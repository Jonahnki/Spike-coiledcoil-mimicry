#!/usr/bin/env python3
"""
Lock and verify a candidate antigen panel against live UniProt.

Generalized from the original spike/cardiac-specific Step 1 script: reads an
arbitrary panel from a samplesheet (accession, symbol, role, justification,
expected_gene, expected_organism_substring, expected_reviewed) rather than a
hardcoded dict, so this script works for any antigen panel, not just the
myocarditis demonstration case.

Every accession is independently re-verified against the live UniProt REST
API at run time. If any accession fails to resolve, resolves to the wrong
gene/organism, or resolves to an unreviewed entry where reviewed was
expected, the script aborts and writes nothing rather than silently
propagating a wrong accession downstream (see docs/design_decisions.md,
"Regolyx accession crisis" precedent).
"""

import argparse
import csv
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

UNIPROT_BASE = "https://rest.uniprot.org/uniprotkb"
REQUEST_HEADERS = {
    "User-Agent": "structural-mimicry-nf/1.0 (research pipeline; see GitHub repo)"
}
REQUEST_TIMEOUT = 20
REQUEST_DELAY_SECONDS = 1.0


class AccessionVerificationError(RuntimeError):
    pass


def fetch_uniprot_entry(accession: str) -> dict:
    url = f"{UNIPROT_BASE}/{accession}.json"
    resp = requests.get(url, headers=REQUEST_HEADERS, timeout=REQUEST_TIMEOUT)
    if resp.status_code != 200:
        raise AccessionVerificationError(
            f"UniProt lookup failed for {accession}: HTTP {resp.status_code}. "
            f"Body: {resp.text[:300]}"
        )
    return resp.json()


def verify_entry(row: dict) -> dict:
    accession = row["accession"]
    print(f"  Verifying {row['symbol']} ({accession}) ...", end=" ", flush=True)

    data = fetch_uniprot_entry(accession)

    entry_type = data.get("entryType", "")
    is_reviewed = "Swiss-Prot" in entry_type

    organism = data.get("organism", {}).get("scientificName", "")
    genes = data.get("genes", [])
    gene_name = genes[0].get("geneName", {}).get("value") if genes else None

    protein_desc = data.get("proteinDescription", {})
    full_name = (
        protein_desc.get("recommendedName", {}).get("fullName", {}).get("value")
        or protein_desc.get("submissionNames", [{}])[0].get("fullName", {}).get("value", "N/A")
    )
    length = data.get("sequence", {}).get("length")
    sequence = data.get("sequence", {}).get("value")

    problems = []
    expected_reviewed = row.get("expected_reviewed", "true").lower() == "true"
    if expected_reviewed and not is_reviewed:
        problems.append(f"expected reviewed entry, got entryType={entry_type!r}")

    expected_org = row.get("expected_organism_substring", "").strip()
    if expected_org and expected_org not in organism:
        problems.append(f"expected organism containing {expected_org!r}, got {organism!r}")

    expected_gene = row.get("expected_gene", "").strip()
    if expected_gene and gene_name != expected_gene:
        problems.append(f"expected gene {expected_gene!r}, got {gene_name!r}")

    if not sequence:
        problems.append("no sequence returned")

    if problems:
        print("MISMATCH")
        raise AccessionVerificationError(
            f"Verification failed for {row['symbol']} ({accession}): " + "; ".join(problems)
        )

    print(f"OK — {full_name} | gene={gene_name} | organism={organism} | {length} aa | {entry_type}")

    return {
        "accession": accession,
        "verified_full_name": full_name,
        "verified_gene": gene_name,
        "verified_organism": organism,
        "verified_length_aa": length,
        "verified_entry_type": entry_type,
        "sequence": sequence,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samplesheet", required=True, type=Path,
                         help="CSV with columns: key,accession,symbol,role,justification,"
                              "expected_gene,expected_organism_substring,expected_reviewed")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    with open(args.samplesheet, newline="") as f:
        rows = list(csv.DictReader(f))

    print(f"Locking antigen panel: {len(rows)} entries from {args.samplesheet}")
    print("=" * 60)

    locked_panel = {
        "pipeline_step": 1,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "verification_source": "https://rest.uniprot.org",
        "source_samplesheet": str(args.samplesheet),
        "note": (
            "Every accession below was independently re-verified against the live "
            "UniProt API at generation time. See 'verified_*' fields per entry."
        ),
        "entries": {},
    }

    try:
        for i, row in enumerate(rows):
            verified = verify_entry(row)
            locked_panel["entries"][row["key"]] = {
                "symbol": row["symbol"],
                "role": row["role"],
                "justification": row.get("justification", ""),
                **verified,
            }
            if i < len(rows) - 1:
                time.sleep(REQUEST_DELAY_SECONDS)
    except AccessionVerificationError as e:
        print(f"\nABORTED — {args.output} was NOT written.\nReason: {e}", file=sys.stderr)
        sys.exit(1)
    except requests.RequestException as e:
        print(f"\nABORTED — network error, {args.output} was NOT written.\nReason: {e}",
              file=sys.stderr)
        sys.exit(1)

    args.output.write_text(json.dumps(locked_panel, indent=2))
    print(f"\nAll {len(rows)} accessions verified. Panel written to: {args.output}")


if __name__ == "__main__":
    main()
