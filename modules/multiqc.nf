process MULTIQC {
    tag "All samples"
    container "community.wave.seqera.io/library/pip_multiqc:a3c26f6199d64b7c"
    conda "bioconda::multiqc"

    input:
    path '*'
    val output_name

    output:
    path "${output_name}.html", emit: report
    path "${output_name}_data", emit: data

    script:
    """
    multiqc . -n ${output_name}.html
    """
}