include { PGSCATALOG_MATCH } from '../../../modules/UMCUGenetics/pgscatalog/match/main'
include { PRSUTILS_NORM   } from '../../../modules/UMCUGenetics/prsutils/norm/main'
include { PLINK2_SCOREEXPANDED     } from '../../../modules/UMCUGenetics/plink2/scoreexpanded/main'
include { PLINK2_VCFEXPANDED       } from '../../../modules/UMCUGenetics/plink2/vcfexpanded/main'

workflow VCF_PRS_SCORE {
    take:
    ch_vcf
    ch_normalised_model

    main:

    PLINK2_VCFEXPANDED(
        ch_vcf
    )

    // Pair each (sample, model) pvar with the matching model's normalised scorefile by model_id.
    ch_match_input = PLINK2_VCFEXPANDED.out.pvar_zst
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


    PLINK2_SCOREEXPANDED(
        PLINK2_VCFEXPANDED.out.pgen
            .join(PLINK2_VCFEXPANDED.out.psam)
            .join(PLINK2_VCFEXPANDED.out.pvar)
            .join(PLINK2_VCFEXPANDED.out.afreq)
            .join(PGSCATALOG_MATCH.out.scorefile)
    )

    PRSUTILS_NORM(
        PLINK2_SCOREEXPANDED.out.score
    )


    emit:
    ch_score_norm     = PRSUTILS_NORM.out.tsv
    ch_score_variants = PGSCATALOG_MATCH.out.log
    ch_score          = PGSCATALOG_MATCH.out.scorefile
    ch_score_summary  = PGSCATALOG_MATCH.out.summary
    ch_pgen           = PLINK2_VCFEXPANDED.out.pgen
    ch_psam           = PLINK2_VCFEXPANDED.out.psam
    ch_pvar           = PLINK2_VCFEXPANDED.out.pvar_zst
    ch_vmiss_gz       = PLINK2_VCFEXPANDED.out.vmiss_gz
    ch_afreq_gz       = PLINK2_VCFEXPANDED.out.afreq_gz

}
