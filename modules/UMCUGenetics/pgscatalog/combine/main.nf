process PGSCATALOG_COMBINE {
    tag "${meta.id}"

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/pgscatalog-utils:1.4.4--pyhdfd78af_0'
        : 'biocontainers/pgscatalog-utils:1.4.4--pyhdfd78af_0'}"

    input:
    tuple val(meta), path(scoring_file)
    val assembly_version

    output:
    tuple val(meta), path("*_normalised.txt.gz"), emit: normalised_model
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    pgscatalog-combine \\
        -s ${scoring_file} \\
        -t ${assembly_version} \\
        -o ${prefix}_normalised.txt.gz


    echo "pgscatalog-combine: 1.4.4" > versions.yml
    """
}
