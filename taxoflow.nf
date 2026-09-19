/*
 * required tasks
 */
include { FASTQC                      }  from './modules/fastqc.nf'
include { TRIM_GALORE                 }  from './modules/trimgalore.nf'
include { BOWTIE2                     }  from './modules/bowtie2.nf'
include { KRAKEN2                     }  from './modules/kraken2.nf'
include { BRACKEN                     }  from './modules/bracken.nf'
include { K_REPORT_TO_KRONA           }  from './modules/kReport2Krona.nf'
include { KT_IMPORT_TEXT              }  from './modules/ktImportText.nf'
include { KRAKEN_BIOM                 }  from './modules/kraken_biom.nf'
include { KNIT_PHYLOSEQ               }  from './modules/knit_phyloseq/knit_phyloseq.nf'
include { MULTIQC                     }  from './modules/multiqc.nf'

/*
 * workflow
 */

workflow TaxoFlow {
    // required inputs
    take:
        bowtie2_index
        kraken2_db
        reads_ch
    // workflow implementation
    main:
         // Initial quality control
        FASTQC(reads_ch)
        TRIM_GALORE(reads_ch)
        BOWTIE2(TRIM_GALORE.out.trimmed_reads, bowtie2_index)
        KRAKEN2(BOWTIE2.out.reads, kraken2_db)
        BRACKEN(KRAKEN2.out.files, kraken2_db, params.read_length)
        K_REPORT_TO_KRONA(BRACKEN.out)
        KT_IMPORT_TEXT(K_REPORT_TO_KRONA.out)
        if(params.sheet_csv){
            KRAKEN_BIOM(BRACKEN.out.collect())
            KNIT_PHYLOSEQ(KRAKEN_BIOM.out)
        }
        multiqc_files_ch = channel.empty().mix(
        FASTQC.out.zip,
        FASTQC.out.html,
        TRIM_GALORE.out.trimming_reports,
        TRIM_GALORE.out.fastqc_reports_1,
        TRIM_GALORE.out.fastqc_reports_2,
        KRAKEN2.out.report,
        BOWTIE2.out.log
        )
    multiqc_files_list = multiqc_files_ch.collect()
    MULTIQC(multiqc_files_list, params.report_id)

    emit:
        bowtie_log               =    BOWTIE2.out.log
        bowtie_unali             =    BOWTIE2.out.reads
        kraken_class             =    KRAKEN2.out.files
        bracken_class            =    BRACKEN.out
        krona                    =    KT_IMPORT_TEXT.out
        biom                     =    KRAKEN_BIOM.out
        fastqc_zip               =    FASTQC.out.zip
        fastqc_html              =    FASTQC.out.html
        trimmed_reads            =    TRIM_GALORE.out.trimmed_reads
        trimming_reports         =    TRIM_GALORE.out.trimming_reports
        trimming_fastqc_1        =    TRIM_GALORE.out.fastqc_reports_1
        trimming_fastqc_2        =    TRIM_GALORE.out.fastqc_reports_2
        multiqc_report           =    MULTIQC.out.report
        multiqc_data             =    MULTIQC.out.data
}