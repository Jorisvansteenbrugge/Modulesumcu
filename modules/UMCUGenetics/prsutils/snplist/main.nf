process PRSUTILS_SNPLIST {
    tag "${meta.id}"

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    tuple val(meta), path(scoring_file)

    output:
    tuple val(meta), path("*_snplist.list"), emit: list
    tuple val("${task.process}"), val('prsutils'), eval('echo 1.0.0'), emit: versions_SNPlist, topic: versions

    script:
    def prefix = task.ext.prefix ?: meta.id
    def args = task.ext.args ?: ""
    """
    get_snp_list.py \\
        --scoring_file ${scoring_file} \\
        --prefix ${prefix} \\
        ${args}

    export prefix=${prefix}
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}_snplist.list
    touch ${prefix}_snplist.tsv
    """
}
