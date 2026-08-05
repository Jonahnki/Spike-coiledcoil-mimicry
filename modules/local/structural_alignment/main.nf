process STRUCTURAL_ALIGNMENT {
    tag "foldseek_alignment"
    label 'process_medium'
    publishDir "${params.outdir}/04_alignment_results", mode: 'copy'

    conda "bioconda::foldseek=7.04e0ec8"
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/foldseek:7.04e0ec8--pl5321h27ae2fa_0' :
        'quay.io/biocontainers/foldseek:7.04e0ec8--pl5321h27ae2fa_0' }"

    input:
    path structure_sources
    path filled_structures
    val fragment_window
    val fragment_stride
    val min_aln_length
    val patch_tm_threshold

    output:
    path "alignment_results.json", emit: alignment_results
    path "chains/*.pdb",           emit: extracted_chains
    path "versions.yml",           emit: versions

    script:
    """
    structural_alignment.py \\
        --structure-sources ${structure_sources} \\
        --filled-structures ${filled_structures} \\
        --output alignment_results.json \\
        --chains-dir chains/ \\
        --fragment-window ${fragment_window} \\
        --fragment-stride ${fragment_stride} \\
        --min-aln-length ${min_aln_length} \\
        --patch-tm-threshold ${patch_tm_threshold} \\
        --foldseek-bin \$(which foldseek)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        foldseek: \$(foldseek version)
        gemmi: \$(python3 -c "import gemmi; print(gemmi.__version__)")
    END_VERSIONS
    """

    stub:
    """
    mkdir chains
    touch alignment_results.json versions.yml
    """
}
