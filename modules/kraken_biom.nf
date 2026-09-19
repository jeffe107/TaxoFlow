process KRAKEN_BIOM {
    tag "merge_samples"
    container "community.wave.seqera.io/library/kraken-biom:1.2.0--f040ab91c9691136"
    conda "bioconda::kraken-biom"

    input:
    val files

    output:
    path "merged.biom"

    script:
    """
    list=(${files.join(' ')})
    extracted=\$(echo "\${list[@]}" | tr ' ' '\n' | awk 'NR % 3 == 2')
    kraken-biom \${extracted} --fmt json -o merged.biom
    """
}
