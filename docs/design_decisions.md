# Design Decisions and Course Corrections

This document records every locked methodological decision and every correction made
during implementation, so the reasoning is auditable rather than assumed.

## Locked methodology decisions

- **Antigen panel**: literature-anchored (MYH6, TPM1, TPM3, ACTC1), not a broader
  systematic sweep — chosen to keep this study directly comparable to the two
  contradictory predecessor investigations it reassesses (Kanduc-lineage linear
  peptide-sharing analyses; eBioMedicine structural/sequence null result).
- **Structure sourcing**: experimental-first (PDB), AlphaFold DB then ESMFold as
  sequential fallbacks — the query protein's conformational states are *never*
  filled by prediction; only experimentally-resolved states are used.
- **Structural comparison**: whole-domain Foldseek/TM-align first, fragment-level
  zoom-in second — the whole-domain-first approach's patch-level blind spot is
  disclosed explicitly rather than hidden.
- **Statistical validation**: combined randomized-proteome null distribution +
  known-pair biological calibration, not either alone.
- **Query protein scope**: single reference sequence (Wuhan strain for the spike
  demonstration), multiple experimentally-resolved conformational states.
- **Mechanism scope**: B-cell/antibody structural mimicry only.
- **Antigenicity tool**: solvent-accessible surface area (FreeSASA), computed
  locally rather than via a web API dependency.
- **Output format**: findings paper + open-source reusable pipeline, generalized
  from day one — arbitrary query protein × arbitrary candidate antigen set as
  inputs, with the spike/cardiac panel as the first demonstration dataset.

## Course corrections made during implementation

### Tool substitutions
- **Epitopia → ElliPro → FreeSASA**: Epitopia's documentation and validation dated
  to 2009 with no evidence of continued maintenance. ElliPro was the corrected
  choice, but its multi-step session-based web API is fragile to script from a
  Colab notebook. FreeSASA was adopted as the final choice: it computes the same
  underlying physical property (solvent accessibility) that ElliPro's protrusion
  index estimates, runs entirely locally with no API dependency, and produces
  numeric SASA values directly reportable in a manuscript.
- **ESMFold (original) retained over ESMFold2**: reviewed and explicitly rejected
  after finding no demonstrated accuracy improvement on disordered/flexible
  regions, the specific property relevant to this study, versus a much less
  proven, recently-released model.

### Structure sourcing bugs found and fixed
- **Candidate pool too narrow**: an initial run capped the RCSB search pool at 25
  candidates ranked by sequence-identity score. Because near-identical hits above
  the identity cutoff score in ties, "top 25 by score" was effectively an
  arbitrary slice — the canonical closed-state reference structure (6VXX) never
  appeared. Fixed by widening the pool to 60 candidates and adding a secondary
  sort preferring simple, single-construct structures over antibody-Fab
  cocktail complexes.
- **State misclassification**: a title-keyword classifier initially mislabeled a
  mixed-state structure (one RBD open, two RBD closed) as a clean "closed" state,
  because a partial keyword match ("closed state") won silently even though the
  title also described a contradicting RBD position. Fixed by (a) requiring
  stricter, more specific phrase matches, (b) introducing an explicit
  `mixed_or_composite` category for titles matching more than one state, and
  (c) adding a small set of well-established canonical reference structures with
  their conformational state assigned deterministically, overriding the fuzzy
  classifier rather than depending on it for structures whose identity is
  already known from primary literature.
- **Postfusion chain extraction failure**: the postfusion structure contains only
  the S2 subunit (S1 dissociates during the postfusion transition), so matching
  against the N-terminal 50 residues of the full reference sequence failed
  silently. Fixed with a sliding-window sequence match that searches the full
  target sequence for the best-matching chain region, rather than assuming the
  match starts at residue 1.
- **`gemmi.one_letter_code()` API change**: an intermediate `gemmi` version
  changed this function's expected input from a `ResidueSpan` object to a plain
  list of residue name strings. Fixed at the call site.

### Fragment analysis artifact
- The first fragment-level Foldseek run returned TM-scores as high as 2.0, which
  is mathematically impossible (TM-score is bounded [0, 1]). Root cause: Foldseek's
  scoring overflows on trivially short (2-residue) alignments within small
  30-residue fragments. Fixed by filtering to `alnlen >= 15` (at least half the
  fragment window genuinely aligned) in addition to `TM <= 1.0`, which reduced a
  fragment hit set from 8,248 raw hits (1,440 arithmetic artifacts) to 1,811
  valid hits — revealing a real, previously-hidden signal underneath the noise.

### Compute environment
- **Colab Drive I/O errors**: large JSON reads directly from a mounted Google
  Drive intermittently raised `OSError: [Errno 5] Input/output error` mid-read.
  Fixed by copying input files to local ephemeral storage (`/tmp`) before
  reading, avoiding sustained Drive I/O for anything beyond simple file copies.
- **Local vs. Colab split**: Foldseek/TM-align steps (CPU-bound, batch-heavy —
  the randomized null distribution alone runs ~900 comparisons) run poorly on
  Colab's free tier, which penalizes long-running non-interactive sessions.
  ESMFold fallback folding (GPU-bound) is the one step that genuinely benefits
  from Colab. This is documented explicitly so a future user of this pipeline
  knows which steps need a persistent machine versus a free interactive
  notebook.

## Known limitations, disclosed rather than resolved

- Predicted structures (AlphaFold DB, ESMFold) do not constitute a true dynamic
  conformational ensemble; they are used only to patch experimental coverage
  gaps in candidate antigens, never as a substitute for the query protein's
  experimentally-resolved conformational diversity.
- Whole-domain alignment may under-detect small, localized patch-level mimicry
  outside any globally aligned region — this is exactly why the fragment-level
  analysis exists as a second, independent layer.
- A structural or antigenicity signal identified by this pipeline is a
  computational hypothesis, not evidence of an actual antibody response in vivo.
  No wet-laboratory validation is included in this pipeline's scope.
- No well-established canonical two-RBD-up reference structure was identified
  for the spike demonstration case during methodology verification; this is
  recorded as a deliberate, disclosed gap rather than forced with a weaker
  antibody-bound or ACE2-bound substitute.
