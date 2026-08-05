# structural-mimicry-nf

A generalized Nextflow DSL2 pipeline for structural mimicry screening between an
arbitrary query protein (across multiple experimentally-resolved conformational
states) and an arbitrary candidate antigen set.

**This pipeline is not hardcoded to any specific biological system.** The
demonstration dataset — SARS-CoV-2 spike glycoprotein screened against four
cardiac autoantigens (MYH6, TPM1, TPM3, ACTC1) as a reassessment of the
molecular mimicry hypothesis in mRNA vaccine-associated myocarditis — is
supplied as a default samplesheet configuration, not fixed pipeline logic.
Swap the samplesheets to screen any other query protein against any other
candidate antigen panel.

## What this pipeline answers

Given a protein that adopts multiple physiologically real conformational
states, and a panel of candidate autoantigens: is there structurally
meaningful similarity between any query conformation and any candidate
antigen, is that similarity statistically distinguishable from chance, and
does it land on an antibody-accessible surface?

## Pipeline stages

| Step | Stage | What it does |
|---|---|---|
| 1 | `LOCK_ANTIGEN_PANEL` | Verifies every accession live against UniProt before anything downstream runs |
| 2 | `SOURCE_STRUCTURES` | Sources experimental structures for query conformations and candidate antigens from the PDB |
| 3 | `FILL_COVERAGE_GAPS` | Fills structural coverage gaps in candidate antigens (AlphaFold DB, then ESMFold) — never predicts query conformational states |
| 4 | `STRUCTURAL_ALIGNMENT` | Whole-domain (Foldseek) and fragment-level (30-residue window) structural comparison |
| 5 | `STATISTICAL_VALIDATION` | Randomized proteome null distribution + known cross-reactive pair calibration |
| 6 | `ANTIGENICITY_SCORING` | Solvent-accessible surface area (FreeSASA) — is the structurally similar region antibody-accessible? |
| 7 | `CONFORMATIONAL_COMPARISON` | Synthesises all layers into the central finding: does the signal depend on conformational state? |

## Demonstration run results

`demo_results/` contains the findings this repository's demonstration run
produced — spike glycoprotein screened against four cardiac autoantigens
(MYH6, TPM1, TPM3, ACTC1) as a reassessment of the molecular mimicry
hypothesis in mRNA vaccine-associated myocarditis. Each file corresponds to
one pipeline stage's output (panel verification through the final
conformational comparison synthesis).

The full methodology narrative — every locked design decision and every
course correction made during implementation — is documented in
[`docs/design_decisions.md`](docs/design_decisions.md). Read that file
alongside `demo_results/07_conformational_comparison.json` for the complete
picture of how the pipeline arrived at its central finding.

Interactive Colab notebooks used for the original exploratory runs are in
[`notebooks/`](notebooks/); the `modules/local/` Nextflow processes are the
production-ready, generalized equivalents of the same logic.

## Quick start (demonstration dataset)

```bash
nextflow run main.nf -profile docker,test
```

## Running on your own query protein and antigen panel

```bash
nextflow run main.nf \
    -profile docker \
    --panel_samplesheet /path/to/your_antigen_panel.csv \
    --query_conformations /path/to/your_query_conformations.csv \
    --outdir /path/to/results
```

Samplesheet formats are documented in `assets/samplesheets/`, with the
demonstration files serving as worked examples.

## Design decisions and course corrections

Every locked methodological decision and every bug found and fixed during
implementation is documented in [`docs/design_decisions.md`](docs/design_decisions.md),
including the specific corrections made to structure sourcing, chain extraction,
fragment-level analysis, and compute environment handling.

## Compute requirements

Most stages are CPU-only. `FILL_COVERAGE_GAPS` (Step 3) requires GPU access only
when the ESMFold fallback is triggered — see `docs/design_decisions.md` for the
reasoning behind the local-vs-cloud compute split used during development.

## Citation

If you use this pipeline, please cite the associated manuscript (in preparation)
and this repository.

## License

MIT
