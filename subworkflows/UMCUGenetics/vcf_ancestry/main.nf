include { ANCESTRY_CALC         } from '../../../modules/UMCUGenetics/ancestry/calc/main'
include { ANCESTRY_MERGE   } from '../../../modules/UMCUGenetics/ancestry/merge/main'
include { BCFTOOLS_MERGE       } from '../../../modules/nf-core/bcftools/merge/main'
include { BCFTOOLS_VIEW        } from '../../../modules/nf-core/bcftools/view/main'
include { PLINK2_EXTRACT       } from '../../../modules/UMCUGenetics/plink2/extract/main'
include { PLINK2_INDEPPAIRWISE } from '../../../modules/nf-core/plink2/indeppairwise/main'
include { PLINK2_PCA           } from '../../../modules/nf-core/plink2/pca/main'
include { PLINK2_VCFEXPANDED           } from '../../../modules/UMCUGenetics/plink2/vcfexpanded/main'

workflow VCF_ANCESTRY {
    take:
    ch_vcf
    ch_ref_vcf
    ch_ref_meta
    ch_genome
    ch_genome_index

    main:

    BCFTOOLS_VIEW(
        ch_vcf,
        [],
        [],
        []
    )

    def regions_vcf = BCFTOOLS_VIEW.out.vcf
        .map{ _meta, vcf -> vcf }
        .collect()

    ch_merge_input = ch_vcf
        .combine(ch_ref_vcf)
        .map{ sample_meta, sample_vcf, sample_tbi, _ref_meta, ref_vcf, ref_tbi ->
            [sample_meta, [sample_vcf, ref_vcf], [sample_tbi, ref_tbi] ]
        }
        .combine( regions_vcf )

    BCFTOOLS_MERGE(
        ch_merge_input,
        ch_genome.join(ch_genome_index).first()
    )

    PLINK2_VCFEXPANDED(
        BCFTOOLS_MERGE.out.vcf
    )


    PLINK2_INDEPPAIRWISE(
        PLINK2_VCFEXPANDED.out.pgen
            .join(PLINK2_VCFEXPANDED.out.pvar)
            .join(PLINK2_VCFEXPANDED.out.psam),
        params.indeppairwise_win,
        params.indeppairwise_step,
        params.indeppairwise_r2
    )

    PLINK2_EXTRACT(
        PLINK2_VCFEXPANDED.out.pgen
            .join(PLINK2_VCFEXPANDED.out.psam)
            .join(PLINK2_VCFEXPANDED.out.pvar)
            .join(PLINK2_INDEPPAIRWISE.out.prune_in)
    )

    PLINK2_PCA(
        PLINK2_EXTRACT.out.extract_pgen
            .join(PLINK2_EXTRACT.out.extract_psam)
            .join(PLINK2_EXTRACT.out.extract_pvar)
            .map{ meta, pgen, psam, pvar -> [meta, params.pca_npcs, false, pgen, psam, pvar]}
    )

    ANCESTRY_CALC(
        PLINK2_PCA.out.evecfile,
        ch_ref_meta
    )

    ANCESTRY_MERGE(
        ANCESTRY_CALC.out.knn_tsv
            .map { _meta, tsv -> tsv }
            .collect()
    )

    emit:
    knn_tsv        = ANCESTRY_CALC.out.knn_tsv
    knn_pca_plot   = ANCESTRY_CALC.out.knn_pca_plot
    knn_mqc_tsv    = ANCESTRY_MERGE.out.knn_mqc_tsv
}
