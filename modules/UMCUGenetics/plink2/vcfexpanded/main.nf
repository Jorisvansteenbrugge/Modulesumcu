process PLINK2_VCFEXPANDED {
	tag "${meta.id}"
	label 'process_low'

	conda "${moduleDir}/environment.yml"
	container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a2.3--h712d239_1':
        'biocontainers/plink2:2.00a2.3--h712d239_1' }"

	input:
	tuple val(meta), path(vcf)

	output:
	tuple val(meta), path("*.pgen"), emit: pgen
	tuple val(meta), path("*.psam"), emit: psam
	tuple val(meta), path("*.pvar"), emit: pvar
	tuple val(meta), path("*.pvar.zst"), emit: pvar_zst
	tuple val(meta), path("*.afreq"), emit: afreq
    tuple val(meta), path("*.afreq.gz"), emit: afreq_gz
    tuple val(meta), path('*.vmiss'), emit: vmiss
    tuple val(meta), path('*.vmiss.gz'), emit: vmiss_gz
    tuple val("${task.process}"), val('plink2'), eval("plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//'"), topic: versions, emit: versions_plink2

	when:
	task.ext.when == null || task.ext.when

	script:
	def args = task.ext.args ?: ''
	def prefix = task.ext.prefix ?: "${meta.id}"
	def mem_mb = task.memory.toMega()
	"""
    plink2 \\
        --threads ${task.cpus} \\
        --memory ${mem_mb} \\
        ${args} \\
        --vcf ${vcf} dosage=DS \\
        --out ${prefix}

    plink2 --zst-decompress ${prefix}.pvar.zst > ${prefix}.pvar
    gzip -k ${prefix}.afreq
    gzip -k ${prefix}.vmiss

    """

	stub:
	def prefix = task.ext.prefix ?: "${meta.id}"
	"""
    touch ${prefix}.pgen
    touch ${prefix}.psam
    touch ${prefix}.pvar
    touch ${prefix}.pvar.zst
	touch ${prefix}.afreq
    touch ${prefix}.afreq.gz
    touch ${prefix}.vmiss
    touch ${prefix}.vmiss.gz

    """
}
