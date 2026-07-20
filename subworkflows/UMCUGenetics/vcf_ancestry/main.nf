include { ANCESTRY_KNN         } from '../../../modules/UMCUGenetics/ancestry_knn/calc/main'
include { ANCESTRY_KNN_MERGE   } from '../../../modules/UMCUGenetics/ancestry_knn/merge/main'
include { BCFTOOLS_MERGE       } from '../../../modules/nf-core/bcftools/merge/main'
include { BCFTOOLS_VIEW        } from '../../../modules/nf-core/bcftools/view/main'
include { PLINK2_EXTRACT       } from '../../../modules/UMCUGenetics/plink2/extract_fix/main'
include { PLINK2_INDEPPAIRWISE } from '../../../modules/nf-core/plink2/indeppairwise/main'
include { PLINK2_PCA           } from '../../../modules/nf-core/plink2/pca/main'
include { PLINK2_VCF           } from '../../../modules/UMCUGenetics/plink2/vcf_expanded/main'

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
        ch_genome.join(ch_genome_index)
    )

    PLINK2_VCF(
        BCFTOOLS_MERGE.out.vcf
    )


    PLINK2_INDEPPAIRWISE(
        PLINK2_VCF.out.pgen
            .join(PLINK2_VCF.out.pvar)
            .join(PLINK2_VCF.out.psam),
        params.indeppairwise_win,
        params.indeppairwise_step,
        params.indeppairwise_r2
    )

    PLINK2_EXTRACT(
        PLINK2_VCF.out.pgen
            .join(PLINK2_VCF.out.psam)
            .join(PLINK2_VCF.out.pvar)
            .join(PLINK2_INDEPPAIRWISE.out.prune_in)
    )

    PLINK2_PCA(
        PLINK2_EXTRACT.out.extract_pgen
            .join(PLINK2_EXTRACT.out.extract_psam)
            .join(PLINK2_EXTRACT.out.extract_pvar)
            .map{ meta, pgen, psam, pvar -> [meta, params.pca_npcs, false, pgen, psam, pvar]}
    )

    ANCESTRY_KNN(
        PLINK2_PCA.out.evecfile,
        ch_ref_meta
    )

    ANCESTRY_KNN_MERGE(
        ANCESTRY_KNN.out.knn_tsv
            .map { _meta, tsv -> tsv }
            .collect()
    )

    // Collate software versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(PLINK2_VCF.out.versions)
    ch_versions = ch_versions.mix(PLINK2_INDEPPAIRWISE.out.versions)
    ch_versions = ch_versions.mix(PLINK2_EXTRACT.out.versions)
    ch_versions = ch_versions.mix(PLINK2_PCA.out.versions)

    emit:
    knn_tsv        = ANCESTRY_KNN.out.knn_tsv
    knn_pca_plot   = ANCESTRY_KNN.out.knn_pca_plot
    knn_mqc_tsv    = ANCESTRY_KNN_MERGE.out.knn_mqc_tsv
    ch_versions    = ch_versions
}
