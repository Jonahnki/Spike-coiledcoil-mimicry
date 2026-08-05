process SOURCE_STRUCTURES {
    tag "structure_sourcing"
    label 'process_medium'
    publishDir "${params.outdir}/02_structure_sources", mode: 'copy'

    input:
    path locked_panel
    path query_conformations

    output:
    path "structure_sources.json", emit: structure_sources
    path "structures/*.cif",       emit: structure_files
    path "versions.yml",           emit: versions

    script:
    """
    source_structures.py \\
        --panel ${locked_panel} \\
        --conformations ${query_conformations} \\
        --output structure_sources.json \\
        --structures-dir structures/ \\
        --top-n-candidates 60

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    mkdir structures
    touch structure_sources.json versions.yml
    """
}
