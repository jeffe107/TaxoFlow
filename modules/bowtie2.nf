process BOWTIE2 {
    tag "${sample_id}"
    container "community.wave.seqera.io/library/bowtie2:2.5.4--d51920539234bea7"
    conda "bioconda::bowtie2==2.5.4"

    input:
    tuple val(sample_id), path(read1), path(read2)
    path bowtie2_index

    output:
    tuple val("${sample_id}"), path("${sample_id}.1"), path("${sample_id}.2"), path("${sample_id}.sam"), emit: reads
    path "${sample_id}_aln_sum.log", emit: log

    script:
    """
    export BOWTIE2_INDEXES="${bowtie2_index}"
    export index="${bowtie2_index}/\$(basename ${bowtie2_index})"
    (bowtie2 -x "\${index}" -1 ${read1} -2 ${read2} -p 2 -S ${sample_id}.sam --un-conc-gz ${sample_id}) 2> ${sample_id}_aln_sum.log
    """
}
