include { BCFTOOLS_SORT      } from '../../../modules/nf-core/bcftools/sort/main'
include { PRSUTILS_SNPLIST        } from '../../../modules/UMCUGenetics/prsutils/snplist/main'
include { PRSUTILS_GETVCF            } from '../../../modules/UMCUGenetics/prsutils/getvcf/main'
include { PGSCATALOG_COMBINE } from '../../../modules/UMCUGenetics/pgscatalog/combine/main'


workflow PRS_INTERVALS {
    take:
    ch_PRS_model
    assembly_version

    main:

    PRSUTILS_SNPLIST(
        ch_PRS_model
    )

    PRSUTILS_GETVCF(
        ch_PRS_model,
        assembly_version
    )

    BCFTOOLS_SORT(PRSUTILS_GETVCF.out.vcf)

    PGSCATALOG_COMBINE(
        ch_PRS_model,
        assembly_version
    )

    emit:
    list             = PRSUTILS_SNPLIST.out.list
    vcf              = BCFTOOLS_SORT.out.vcf
    tbi              = BCFTOOLS_SORT.out.index
    normalised_model = PGSCATALOG_COMBINE.out.normalised_model
}
