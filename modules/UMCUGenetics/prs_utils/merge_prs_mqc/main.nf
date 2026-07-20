process MERGE_PRS_MQC {
    label 'process_single'

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    path(tsvs)

    output:
    path("prs_scores_mqc.tsv"), emit: mqc_tsv

    script:
    """
    merge_prs_mqc.py ${tsvs.join(' ')}
    """

    stub:
    """
    touch prs_scores_mqc.tsv
    """
}
