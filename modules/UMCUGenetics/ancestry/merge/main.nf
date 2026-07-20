process ANCESTRY_MERGE {
    tag "ANCESTRY_MERGE"
    label "process_low"

    input:
    path(knn_tsvs)

    output:
    path("ancestry_knn_mqc.tsv"), emit: knn_mqc_tsv
    tuple val("${task.process}"), val('ancestry_knn'), eval('echo 1.0.0'), emit: versions_ancestry_knn, topic: versions

    script:
    """
    echo "Sample ID\tPrediction Group\tConfidence" > ancestry_knn_mqc.tsv

    for f in ${knn_tsvs}; do
        tail -n 1 \$f >> ancestry_knn_mqc.tsv
    done
    """
}
