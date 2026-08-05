/*
========================================================================================
    STRUCTURAL_MIMICRY_SCREEN
========================================================================================
    Orchestrates the full generalized structural mimicry screening workflow.
    Query protein and candidate antigen set are both supplied via samplesheet —
    nothing here is specific to spike or cardiac antigens.
*/

include { LOCK_ANTIGEN_PANEL }        from '../modules/local/lock_antigen_panel/main'
include { SOURCE_STRUCTURES }         from '../modules/local/source_structures/main'
include { FILL_COVERAGE_GAPS }        from '../modules/local/fill_coverage_gaps/main'
include { STRUCTURAL_ALIGNMENT }      from '../modules/local/structural_alignment/main'
include { FRAGMENT_ANALYSIS }         from '../modules/local/fragment_analysis/main'
include { STATISTICAL_VALIDATION }    from '../modules/local/statistical_validation/main'
include { ANTIGENICITY_SCORING }      from '../modules/local/antigenicity_scoring/main'
include { CONFORMATIONAL_COMPARISON } from '../modules/local/conformational_comparison/main'

workflow STRUCTURAL_MIMICRY_SCREEN {

    take:
    panel_samplesheet    // path: candidate antigen panel (accession, symbol, role, justification)
    query_conformations  // path: query protein conformational states (state, pdb_id or structure source)

    main:

    // Step 1 — verify every accession live against UniProt before anything else runs
    LOCK_ANTIGEN_PANEL(panel_samplesheet)

    // Step 2 — source experimental structures for query conformations + candidate antigens
    SOURCE_STRUCTURES(
        LOCK_ANTIGEN_PANEL.out.locked_panel,
        query_conformations
    )

    // Step 3 — fill structural coverage gaps (AlphaFold DB first, ESMFold fallback)
    // The query protein's conformational states are NEVER filled by prediction —
    // only experimentally-resolved states are used, by design (see docs/design_decisions.md)
    FILL_COVERAGE_GAPS(SOURCE_STRUCTURES.out.structure_sources)

    // Step 4 — whole-domain + fragment-level structural alignment
    STRUCTURAL_ALIGNMENT(
        SOURCE_STRUCTURES.out.structure_sources,
        FILL_COVERAGE_GAPS.out.filled_structures,
        params.fragment_window,
        params.fragment_stride,
        params.min_aln_length,
        params.patch_tm_threshold
    )

    // Step 5 — statistical validation: randomized proteome null + known-pair calibration
    STATISTICAL_VALIDATION(
        STRUCTURAL_ALIGNMENT.out.alignment_results,
        params.n_null_proteins,
        params.significance_alpha
    )

    // Step 6 — solvent accessibility / antigenicity scoring of retained hits
    ANTIGENICITY_SCORING(
        STRUCTURAL_ALIGNMENT.out.alignment_results,
        STATISTICAL_VALIDATION.out.validation_results,
        params.exposed_threshold
    )

    // Step 7 — synthesis across query conformational states
    CONFORMATIONAL_COMPARISON(
        STRUCTURAL_ALIGNMENT.out.alignment_results,
        STATISTICAL_VALIDATION.out.validation_results,
        ANTIGENICITY_SCORING.out.antigenicity_results
    )

    emit:
    locked_panel            = LOCK_ANTIGEN_PANEL.out.locked_panel
    structure_sources       = SOURCE_STRUCTURES.out.structure_sources
    filled_structures       = FILL_COVERAGE_GAPS.out.filled_structures
    alignment_results       = STRUCTURAL_ALIGNMENT.out.alignment_results
    validation_results      = STATISTICAL_VALIDATION.out.validation_results
    antigenicity_results    = ANTIGENICITY_SCORING.out.antigenicity_results
    conformational_summary  = CONFORMATIONAL_COMPARISON.out.summary
}
