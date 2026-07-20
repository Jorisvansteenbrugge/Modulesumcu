/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { VCF_ANCESTRY             } from '../../../subworkflows/UMCUGenetics/vcf_ancestry/main'
include { VCF_PRS_SCORE            } from '../../../subworkflows/UMCUGenetics/vcf_prs_score/main'
include { PRS_INTERVALS            } from '../../../subworkflows/UMCUGenetics/prs_intervals/main'
include { BAM_HAPLOTYPECALLER_NORM } from '../../../subworkflows/UMCUGenetics/bam_haplotypecaller_norm/main'

include { SAMPLE_QC                } from '../../../modules/UMCUGenetics/prs_utils/sampleqc/main'
include { MERGE_PRS_MQC            } from '../../../modules/local/merge_prs_mqc/main'
include { MULTIQC                  } from '../../../modules/nf-core/multiqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BAM_PRS {

    take:
    ch_samplesheet // channel: samplesheet read in from --

    main:

    ch_genome_fasta = Channel.fromPath("${params.genome_fasta}")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

    ch_genome_index = Channel.fromPath("${params.genome_fasta}.fai")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

    ch_genome_dict = Channel.fromPath("${params.genome_dict}")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

    ch_dbsnp = Channel.fromPath("${params.dbsnp}")
		.map { file -> [['id': file.getSimpleName()], file] }
		.collect()

    ch_dbsnp_index = Channel.fromPath("${params.dbsnp}.tbi")
		.map { file -> [['id': file.getSimpleName()], file] }
		.collect()


    ch_PRS_model = Channel.fromPath(params.prs_models)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.modelID, mu: row.mu, sd: row.sd, alpha: row.alpha]
            [meta, file("${projectDir}/assets/models/${row.path}")]
        }



    PRS_INTERVALS(ch_PRS_model)

    BAM_HAPLOTYPECALLER_NORM(
        ch_samplesheet,
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        ch_dbsnp,
        ch_dbsnp_index,
        PRS_INTERVALS.out.list,
        PRS_INTERVALS.out.vcf.join(PRS_INTERVALS.out.tbi)
    )

    VCF_PRS_SCORE(
        BAM_HAPLOTYPECALLER_NORM.out.vcf,
        PRS_INTERVALS.out.normalised_model
    )



    ch_ref_vcf = Channel.of([
        file("${params.ancestry_db}", checkIfExists: true),
        file("${params.ancestry_db}.tbi", checkIfExists: true)
    ])
        .map { vcf, tbi -> [ [id: vcf.getSimpleName()], vcf, tbi ] }
        .first()
    ch_ref_meta = Channel.fromPath("${params.ancestry_db_meta}")
        .map {meta -> [[id: meta.getSimpleName()], meta]}
        .first()

    ch_ancestry_vcf = BAM_HAPLOTYPECALLER_NORM.out.vcf
        .map { meta, vcf -> [meta.sample_id, vcf] }
        .groupTuple()
        .map { sid, vcfs -> [[id: sid], vcfs[0]] }

    ch_ancestry_tbi = BAM_HAPLOTYPECALLER_NORM.out.tbi
        .map { meta, tbi -> [meta.sample_id, tbi] }
        .groupTuple()
        .map { sid, tbis -> [[id: sid], tbis[0]] }

    VCF_ANCESTRY(
        ch_ancestry_vcf.join(ch_ancestry_tbi),
        ch_ref_vcf,
        ch_ref_meta,
        ch_genome_fasta,
        ch_genome_index
    )


    // QC step — combined meta carries (sample_id, model_id); ancestry is per-sample only.
    SAMPLE_QC(
        VCF_PRS_SCORE.out.ch_score_norm
            .join(VCF_PRS_SCORE.out.ch_score_summary)
            .map { meta, scores, summary -> [meta.sample_id, meta, scores, summary] }
            .combine(
                VCF_ANCESTRY.out.knn_tsv.map { ancestry_meta, knn -> [ancestry_meta.id, knn] },
                by: 0
            )
            .map { _sid, meta, scores, summary, knn -> [meta, scores, knn, summary] }
    )


    MERGE_PRS_MQC(
        SAMPLE_QC.out.score_qc.map{ _meta, tsv -> tsv }.collect()
    )


    //
    // Collate and save software versions
    //
    //
    ch_versions = Channel.empty()

    ch_versions = ch_versions.mix(PRS_INTERVALS.out.ch_versions)
    ch_versions = ch_versions.mix(VARIANT_CALLING.out.ch_versions)
    ch_versions = ch_versions.mix(CALC_SCORES.out.ch_versions)



    emit:
    // multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    PRS_mqc  = MERGE_PRS_MQC.out.mqc_tsv
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
