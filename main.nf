#!/usr/bin/env nextflow
include {TaxoFlow} from './taxoflow.nf'

workflow {

    main:

    log.info """\
	___________________________________________________________________________________________________
	___________________________________________________________________________________________________
    >===>>=====>                                 >=======>  >=>                         
     	>=>                                      >=>        >=>                         
     	>=>        >=> >=>  >=>   >=>    >=>     >=>        >=>    >=>     >=>      >=> 
     	>=>      >=>   >=>    >> >=>   >=>  >=>  >=====>    >=>  >=>  >=>   >=>  >  >=> 
     	>=>     >=>    >=>     >>     >=>    >=> >=>        >=> >=>    >=>  >=> >>  >=> 
     	>=>      >=>   >=>   >>  >=>   >=>  >=>  >=>        >=>  >=>  >=>   >=>>  >=>=> 
     	>=>       >==>>>==> >=>   >=>    >=>     >=>       >==>    >=>     >==>    >==>   
	___________________________________________________________________________________________________
	___________________________________________________________________________________________________
    """
    .stripIndent()

    if(params.reads){
            reads_ch = Channel.fromFilePairs(params.reads, checkIfExists:true)
        } else {
            reads_ch = Channel.fromPath(params.sheet_csv)
                            .splitCsv(header:true)
                            .map {row-> tuple(row.sample_id, [file(row.fastq_1), file(row.fastq_2)])}
        }
    TaxoFlow(params.bowtie2_index, params.kraken2_db, reads_ch)

	// publish files
    publish:

    bowtie_log              =    TaxoFlow.out.bowtie_log
    bowtie_unali            =    TaxoFlow.out.bowtie_unali
    kraken_class            =    TaxoFlow.out.kraken_class
    bracken_class           =    TaxoFlow.out.bracken_class
    krona                   =    TaxoFlow.out.krona
    biom                    =    TaxoFlow.out.biom
    fastqc_zip              =    TaxoFlow.out.fastqc_zip
    fastqc_html             =    TaxoFlow.out.fastqc_html 
    trimmed_reads           =    TaxoFlow.out.trimmed_reads
    trimming_reports        =    TaxoFlow.out.trimming_reports
    trimming_fastqc_1       =    TaxoFlow.out.trimming_fastqc_1
    trimming_fastqc_2       =    TaxoFlow.out.trimming_fastqc_1
    multiqc_report          =    TaxoFlow.out.multiqc_report
    multiqc_data            =    TaxoFlow.out.multiqc_data

}

output {

    bowtie_log {
        path 'bowtie2'
    }
    bowtie_unali {
        path 'bowtie2'
    }
    kraken_class {
        path 'kraken2'
    }
    bracken_class {
        path 'bracken'
    }
    krona {
        path 'krona'
    }
    biom {
        path 'biom'
    }
    fastqc_zip {
        path 'fastqc'
    }
    fastqc_html {
        path 'fastqc'
    }
    trimmed_reads {
        path 'trimming'
    }
    trimming_reports {
        path 'trimming'
    }
    trimming_fastqc_1 {
        path 'trimming'
    }
    trimming_fastqc_2 {
        path 'trimming'
    }
    multiqc_report {
        path 'multiqc'
    }
    multiqc_data {
        path 'multiqc'
    }
}
