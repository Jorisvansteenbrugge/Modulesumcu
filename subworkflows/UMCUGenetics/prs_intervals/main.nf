include { BCFTOOLS_SORT      } from '../../../modules/nf-core/bcftools/sort/main'
include { GET_SNPLIST        } from '../../../modules/UMCUGenetics/prs_utils/snplist/main'
include { GET_VCF            } from '../../../modules/UMCUGenetics/prs_utils/gatk_vcf/main'
include { PGSCATALOG_COMBINE } from '../../../modules/UMCUGenetics/pgscatalog/combine/main'


workflow PRS_INTERVALS {
    take:
    ch_PRS_model
    assembly_version

    main:

    GET_SNPLIST(
        ch_PRS_model
    )

    GET_VCF(
        ch_PRS_model,
        assembly_version
    )

    BCFTOOLS_SORT(GET_VCF.out.vcf)

    PGSCATALOG_COMBINE(
        ch_PRS_model,
        assembly_version
    )

    emit:
    list             = GET_SNPLIST.out.list
    vcf              = BCFTOOLS_SORT.out.vcf
    tbi              = BCFTOOLS_SORT.out.index
    normalised_model = PGSCATALOG_COMBINE.out.normalised_model
}
