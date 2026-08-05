#!/usr/bin/env nextflow
/*
========================================================================================
    structural-mimicry-nf
========================================================================================
    Generalized structural mimicry screening between an arbitrary query protein
    (multiple conformational states) and an arbitrary candidate antigen set.

    Demonstration dataset: SARS-CoV-2 spike glycoprotein vs. cardiac autoantigens
    (MYH6, TPM1, TPM3, ACTC1), reassessing the molecular mimicry hypothesis in
    mRNA vaccine-associated myocarditis.

    This pipeline is NOT hardcoded to spike/cardiac. The demonstration panel is a
    default samplesheet configuration, not fixed logic — swap the samplesheet to
    screen any query protein against any candidate antigen set.
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

include { STRUCTURAL_MIMICRY_SCREEN } from './workflows/structural_mimicry_screen'

// Default parameters — override via -params-file or --flag
params.panel_samplesheet   = params.panel_samplesheet   ?: "${projectDir}/assets/samplesheets/demo_spike_cardiac_panel.csv"
params.query_conformations = params.query_conformations ?: "${projectDir}/assets/samplesheets/demo_spike_conformations.csv"
params.outdir              = params.outdir              ?: './results'
params.fragment_window     = params.fragment_window     ?: 30
params.fragment_stride     = params.fragment_stride     ?: 15
params.n_null_proteins     = params.n_null_proteins     ?: 300
params.significance_alpha  = params.significance_alpha  ?: 0.05
params.min_aln_length      = params.min_aln_length      ?: 15
params.patch_tm_threshold  = params.patch_tm_threshold  ?: 0.3
params.exposed_threshold   = params.exposed_threshold   ?: 0.25

workflow {
    STRUCTURAL_MIMICRY_SCREEN(
        Channel.fromPath(params.panel_samplesheet, checkIfExists: true),
        Channel.fromPath(params.query_conformations, checkIfExists: true)
    )
}
