process LOCK_ANTIGEN_PANEL {
    tag "panel_verification"
    label 'process_single'
    publishDir "${params.outdir}/01_locked_panel", mode: 'copy'

    conda "bioconda::requests"
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/requests:2.31.0' :
        'quay.io/biocontainers/requests:2.31.0' }"

    input:
    path panel_samplesheet

    output:
    path "panel.json", emit: locked_panel
    path "versions.yml", emit: versions

    script:
    """
    lock_antigen_panel.py \\
        --samplesheet ${panel_samplesheet} \\
        --output panel.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
        requests: \$(python3 -c "import requests; print(requests.__version__)")
    END_VERSIONS
    """

    stub:
    """
    touch panel.json
    touch versions.yml
    """
}
