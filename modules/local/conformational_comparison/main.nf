process CONFORMATIONAL_COMPARISON {
    tag "final_synthesis"
    label 'process_single'
    publishDir "${params.outdir}/07_conformational_comparison", mode: 'copy'

    input:
    path alignment_results
    path validation_results
    path antigenicity_results

    output:
    path "conformational_comparison.json", emit: summary
    path "summary_report.txt",             emit: report
    path "versions.yml",                   emit: versions

    script:
    """
    conformational_comparison.py \\
        --alignment-results ${alignment_results} \\
        --validation-results ${validation_results} \\
        --antigenicity-results ${antigenicity_results} \\
        --output conformational_comparison.json \\
        --report summary_report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch conformational_comparison.json summary_report.txt versions.yml
    """
}
