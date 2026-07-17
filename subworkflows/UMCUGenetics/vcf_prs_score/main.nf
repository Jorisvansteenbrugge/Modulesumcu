include { PGSCATALOG_MATCH } from '../../../modules/UMCUGenetics/pgscatalog/match/main'
include { PRS_UTILS_NORM   } from '../../../modules/UMCUGenetics/prs_utils/norm/main'
include { PLINK2_SCORE     } from '../../../modules/UMCUGenetics/plink2/score_expanded/main'
include { PLINK2_VCF       } from '../../../modules/UMCUGenetics/plink2/vcf_expanded/main'

workflow VCF_PRS_SCORE {
    take:
    ch_vcf
    ch_normalised_model

    main:

    PLINK2_VCF(
        ch_vcf
    )

    // Pair each (sample, model) pvar with the matching model's normalised scorefile by model_id.
    ch_match_input = PLINK2_VCF.out.pvar_zst
        .map { meta, pvar -> [meta.model_id, meta, pvar] }
        .combine(
            ch_normalised_model.map { meta, model -> [meta.id, model] },
            by: 0
        )
        .multiMap { _mid, sm_meta, pvar, model ->
            target:    [sm_meta, pvar]
            scorefile: [sm_meta, model]
        }

    PGSCATALOG_MATCH(
        ch_match_input.target,
        ch_match_input.scorefile,
    )


    PLINK2_SCORE(
        PLINK2_VCF.out.pgen
            .join(PLINK2_VCF.out.psam)
            .join(PLINK2_VCF.out.pvar)
            .join(PLINK2_VCF.out.afreq)
            .join(PGSCATALOG_MATCH.out.scorefile)
    )

    PRS_UTILS_NORM(
        PLINK2_SCORE.out.score
    )


    // Collate software versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(PLINK2_VCF.out.versions)
    ch_versions = ch_versions.mix(PGSCATALOG_MATCH.out.versions)
    ch_versions = ch_versions.mix(PLINK2_SCORE.out.versions)

    emit:
    ch_versions       = ch_versions
    ch_score_norm     = PRS_UTILS_NORM.out.tsv
    ch_score_variants = PGSCATALOG_MATCH.out.log
    ch_score          = PGSCATALOG_MATCH.out.scorefile
    ch_score_summary  = PGSCATALOG_MATCH.out.summary
    ch_pgen           = PLINK2_VCF.out.pgen
    ch_psam           = PLINK2_VCF.out.psam
    ch_pvar           = PLINK2_VCF.out.pvar_zst
    ch_vmiss_gz       = PLINK2_VCF.out.vmiss_gz
    ch_afreq_gz       = PLINK2_VCF.out.afreq_gz

}
