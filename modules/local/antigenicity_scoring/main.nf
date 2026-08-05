process ANTIGENICITY_SCORING {
    tag "sasa_surface_accessibility"
    label 'process_single'
    publishDir "${params.outdir}/06_antigenicity_results", mode: 'copy'

    conda "bioconda::freesasa"

    input:
    path alignment_results
    path validation_results
    val exposed_threshold

    output:
    path "antigenicity_results.json", emit: antigenicity_results
    path "versions.yml",              emit: versions

    script:
    """
    antigenicity_scoring.py \\
        --alignment-results ${alignment_results} \\
        --validation-results ${validation_results} \\
        --output antigenicity_results.json \\
        --exposed-threshold ${exposed_threshold}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freesasa: \$(python3 -c "import freesasa; print(freesasa.__version__)" 2>/dev/null || echo "unknown")
    END_VERSIONS
    """

    stub:
    """
    touch antigenicity_results.json versions.yml
    """
}
