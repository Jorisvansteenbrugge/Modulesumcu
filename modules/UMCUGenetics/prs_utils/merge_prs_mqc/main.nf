process MERGE_PRS_MQC {
    label 'process_single'

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    path(tsvs)

    output:
    path("prs_scores_mqc.tsv"), emit: mqc_tsv
    tuple val("${task.process}"), val('prs_utils_merge_prs_mqc'), eval('echo 1.0.0'), emit: versions_prs_utils_merge_prs_mqc, topic: versions

    script:
    """
    merge_prs_mqc.py ${tsvs.join(' ')}
    """

    stub:
    """
    touch prs_scores_mqc.tsv
    """
}
