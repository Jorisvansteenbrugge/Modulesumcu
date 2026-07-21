include { GATK4_HAPLOTYPECALLERALLELES } from '../../../modules/UMCUGenetics/gatk4/haplotypecalleralleles/main'
include { BCFTOOLS_NORM         } from '../../../modules/nf-core/bcftools/norm/main'

workflow BAM_HAPLOTYPECALLER_NORM {
    take:
    ch_samplesheet
    ch_genome_fasta
    ch_genome_index
    ch_genome_dict
    ch_dbsnp
    ch_dbsnp_index
    ch_snp_list
    ch_snp_vcf


    main:

    // [model_meta, snplist, vcf, tbi]
    ch_per_model = ch_snp_list.join(ch_snp_vcf)

    ch_hc = ch_samplesheet.combine(ch_per_model)
        .multiMap { sm, bam, bai, mm, snplist, vcf, tbi ->
            def meta = [
                id: "${sm.id}__${mm.id}",
                sample_id: sm.id,
                model_id: mm.id,
                mu: mm.mu,
                sd: mm.sd,
                alpha: mm.alpha,
            ]
            input:   [meta, bam, bai, snplist, []]
            alleles: [[id: meta.id], vcf, tbi]
        }

    GATK4_HAPLOTYPECALLERALLELES(
        ch_hc.input,
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        ch_dbsnp,
        ch_dbsnp_index,
        ch_hc.alleles
    )

    BCFTOOLS_NORM(
        GATK4_HAPLOTYPECALLERALLELES.out.vcf
            .join(GATK4_HAPLOTYPECALLERALLELES.out.tbi),
        ch_genome_fasta
    )

    // Collate software versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(GATK4_HAPLOTYPECALLERALLELES.out.versions)

    emit:
    vcf         = BCFTOOLS_NORM.out.vcf
    tbi         = BCFTOOLS_NORM.out.index
    ch_versions = ch_versions
}
