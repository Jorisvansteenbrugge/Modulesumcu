process PRS_UTILS_NORM {
    tag "${meta.id}"
    label 'process_single'

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    tuple val(meta), path(prs_scores)

    output:
    tuple val(meta), path ("*_normalised_counts.tsv"), emit: tsv
    tuple val("${task.process}"), val('prs_utils_norm'), eval('echo 1.0.0'), emit: versions_prs_utils_norm, topic: versions

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    normalise_counts.py \\
        --PRS ${prs_scores} \\
        --mu ${meta.mu} \\
        --SD ${meta.sd} \\
        -o ${prefix}_normalised_counts.tsv
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
	touch ${prefix}_normalised_counts.tsv
	"""
}
