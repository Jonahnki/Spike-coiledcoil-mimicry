process FILL_COVERAGE_GAPS {
    tag "coverage_gap_filling"
    label 'process_high'
    label 'process_gpu'
    publishDir "${params.outdir}/03_filled_structures", mode: 'copy'

    input:
    path structure_sources

    output:
    path "filled_structures.json", emit: filled_structures
    path "alphafold_db/*",         emit: alphafold_structures, optional: true
    path "esmfold/*",              emit: esmfold_structures,   optional: true
    path "versions.yml",           emit: versions

    script:
    """
    fill_coverage_gaps.py \\
        --structure-sources ${structure_sources} \\
        --output filled_structures.json \\
        --alphafold-dir alphafold_db/ \\
        --esmfold-dir esmfold/ \\
        --esmfold-max-residues-per-call 400

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
        torch: \$(python3 -c "import torch; print(torch.__version__)")
        transformers: \$(python3 -c "import transformers; print(transformers.__version__)")
    END_VERSIONS
    """

    stub:
    """
    mkdir alphafold_db esmfold
    touch filled_structures.json versions.yml
    """
}
