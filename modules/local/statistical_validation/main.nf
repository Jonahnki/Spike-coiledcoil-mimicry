process STATISTICAL_VALIDATION {
    tag "null_distribution_and_calibration"
    label 'process_high'
    publishDir "${params.outdir}/05_validation_results", mode: 'copy'

    conda "bioconda::foldseek=7.04e0ec8"

    input:
    path alignment_results
    val n_null_proteins
    val significance_alpha

    output:
    path "validation_results.json", emit: validation_results
    path "versions.yml",            emit: versions

    script:
    """
    statistical_validation.py \\
        --alignment-results ${alignment_results} \\
        --output validation_results.json \\
        --n-null-proteins ${n_null_proteins} \\
        --alpha ${significance_alpha} \\
        --foldseek-bin \$(which foldseek)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        foldseek: \$(foldseek version)
        numpy: \$(python3 -c "import numpy; print(numpy.__version__)")
    END_VERSIONS
    """

    stub:
    """
    touch validation_results.json versions.yml
    """
}
