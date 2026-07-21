process PRSUTILS_GETVCF {
    tag "GATK VCF ${meta.id}"

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    tuple val(meta), path(scoring_file)
    val genome_build

    output:
    tuple val(meta), path("*_genotypes.vcf"), emit: vcf
    tuple val("${task.process}"), val('gatk_vcf'), eval('echo 1.0.0'), emit: versions_gatk_vcf, topic: versions

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    pgs_to_vcf.py \\
        ${scoring_file} \\
        ${prefix}_genotypes.vcf \\
        --genome-build ${genome_build}
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}_genotypes.vcf
    """
}
