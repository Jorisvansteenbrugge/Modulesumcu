process ANCESTRY_KNN {
    tag "${meta.id}"
    label "process_medium"

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    tuple val(meta), path(eigenvec)
    tuple val(meta2), path(ref_metadata)

    output:
    tuple val(meta), path("*_knn.tsv"), emit: knn_tsv
    tuple val(meta), path("*_knn_pca.png"), emit: knn_pca_plot, optional: true

    script:
    def prefix = task.ext.prefix ?: meta.id
    def args = task.ext.args ?: ""
    """
    knn.py \
        --eig ${eigenvec} \\
        --labels ${ref_metadata} \\
        ${args} \\
        --plot-output ${prefix}_knn_pca.png \\
        --output ${prefix}_knn.tsv
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}_knn.tsv
    touch ${prefix}_knn_pca.png
    """
}
