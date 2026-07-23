process PGSCATALOG_MATCH {
    tag "${meta.id}"

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/pgscatalog-utils:1.4.4--pyhdfd78af_0'
        : 'biocontainers/pgscatalog-utils:1.4.4--pyhdfd78af_0'}"

    input:
    tuple val(meta), path(pvar)
    tuple val(meta2), path(scoring_file)


    output:
    tuple val(meta), path("*_summary.csv"), emit: summary
    tuple val(meta), path("*.scorefile.gz"), emit: scorefile
    tuple val(meta), path("*_log.csv.gz"), emit: log
    tuple val("${task.process}"), val('pgscatalog'), eval('echo 1.4.4'), emit: versions_pgscatalog_match, topic: versions

    script:
    def prefix = task.ext.prefix ?: meta.id
    def args = task.ext.args ?: ""
    """
    pgscatalog-match \\
        ${args} \\
        --dataset ${prefix} \\
        --scorefiles ${scoring_file} \\
        --target ${pvar} \\
        --outdir ./
    """

    stub:
    def prefix = task.ext.prefix ?: "Cohort"
    """
	touch ${prefix}_summary.csv
	touch ${prefix}.scorefile.gz
    touch ${prefix}_log.csv.gz
	"""
}
