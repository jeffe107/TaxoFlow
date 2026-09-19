# TaxoFlow

<p align="center">
    <img class="brand" src="assets/taxoflow_logo.png" alt="TaxoFlow logo" width="20%">
</p>

A **Nextflow** pipeline for metagenomics taxonomic classification and abundance estimation using **Kraken2** and **Bracken**, wrapped as a reproducible and scalable workflow.

TaxoFlow follows the reference-based compositional analysis protocol proposed by [Lu et al. (2022)](https://www.nature.com/articles/s41596-022-00738-y). It removes host-derived reads by mapping against the *Arabidopsis thaliana* genome (or any reference of choice), classifies the remaining reads with Kraken2, estimates taxonomic abundance with Bracken, and produces interactive visualizations plus a Phyloseq-based diversity report.

## Table of Contents

- [Pipeline overview](#pipeline-overview)
- [Workflow diagram](#workflow-diagram)
- [Pipeline steps](#pipeline-steps)
- [Installation](#installation)
- [Usage](#usage)
- [Parameters](#parameters)
- [Output](#output)
- [License](#license)
- [References](#references)

## Pipeline overview

At a glance, each sample goes through:

1. **Quality check** of the raw paired-end reads with FastQC.
2. **Adapter trimming** and per-base quality filtering with Trim Galore! (re-running FastQC on the trimmed reads).
3. **Host read removal** by aligning the trimmed reads to the *Arabidopsis thaliana* (TAIR10) genome with Bowtie2; only the unaligned reads are kept.
4. **Taxonomic classification** of the remaining reads against a Kraken2 database.
5. **Abundance estimation** at the species level with Bracken.
6. **Visualization** of Bracken reports as interactive Krona plots.
7. **Cross-sample analysis**: KrakenBiom merges all Bracken outputs into a single BIOM table, and an R Markdown report (Phyloseq) is rendered with absolute/relative abundance, α- and β-diversity, and network plots.
8. **Aggregate QC report** with MultiQC across all samples.

## Workflow diagram

<p align="center">
    <img src="assets/workflow_taxoflow.png" alt="Workflow" width="90%">
</p>

## Pipeline steps

| Step | Module | Tool | Description |
|------|--------|------|-------------|
| 1 | `fastqc.nf` | FastQC | Quality control of raw paired-end reads |
| 2 | `trimgalore.nf` | Trim Galore! | Adapter trimming and quality filtering (with FastQC) |
| 3 | `bowtie2.nf` | Bowtie2 | Host (*A. thaliana*) read removal; keeps unaligned reads |
| 4 | `kraken2.nf` | Kraken2 | Taxonomic classification against a reference database |
| 5 | `bracken.nf` | Bracken | Species-level abundance estimation (default read length 250 bp) |
| 6 | `kReport2Krona.nf` + `ktImportText.nf` | KronaTools / Krona | Interactive Krona visualizations per sample |
| 7 | `kraken_biom.nf` | KrakenBiom | Merge all Bracken outputs into a BIOM table |
| 8 | `knit_phyloseq.nf` | Phyloseq (R) | Diversity/abundance report rendered from the BIOM table |
| 9 | `multiqc.nf` | MultiQC | Aggregate QC report for all samples |

## Installation

### Prerequisites

- [Nextflow](https://www.nextflow.io/) (>= 21.10)
- A container engine ([Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)) **or** [Conda](https://docs.conda.io/) with Mamba
- A [Kraken2 database](https://benlangmead.github.io/aws-indexes/k2) built with Bracken (see Bracken's `bracken-build`)
- A Bowtie2 index of the host reference genome (default: TAIR10)

Clone the repository:

```bash
git clone https://github.com/jeffe107/TaxoFlow
cd TaxoFlow
```

## Usage

### Input reads

Provide paired-end reads either through a glob pattern or a sample sheet.

**Option A — glob pattern** (automatically pairs `_1`/`_2` files):

```bash
nextflow run main.nf \
  -profile docker \
  --reads 'data/samples/*_R{1,2}_*.fastq.gz'
```

**Option B — samplesheet** (also enables the cross-sample Phyloseq report, see `knit_phyloseq`):

```csv
sample_id,fastq_1,fastq_2
ERR2143768,data/samples/ERR2143768/ERR2143768_1.fastq.gz,data/samples/ERR2143768/ERR2143768_2.fastq.gz
ERR2143770,data/samples/ERR2143770/ERR2143770_1.fastq.gz,data/samples/ERR2143770/ERR2143770_2.fastq.gz
ERR2143774,data/samples/ERR2143774/ERR2143774_1.fastq.gz,data/samples/ERR2143774/ERR2143774_2.fastq.gz
```

```bash
nextflow run main.nf \
  -profile docker \
  --sheet_csv data/samplesheet.csv
```

### Example with a custom database (Kraken2 + Bracken) and read length

```bash
nextflow run main.nf \
  -profile conda \
  --reads 'reads/*_R{1,2}.fastq.gz' \
  --bowtie2_index /path/to/TAIR10_bowtie2 \
  --kraken2_db /path/to/krakendb \
  --read_length 150
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `reads` | string | `null` | Glob pattern of paired-end reads (e.g. `'data/*_R{1,2}_{1,2}*.fastq.gz'`). Mutually exclusive with `sheet_csv`. |
| `sheet_csv` | string | `null` | CSV sample sheet with `sample_id,fastq_1,fastq_2` columns. Also triggers the cross-sample Phyloseq BIOM analysis. |
| `outdir` | string | `"${projectDir}/output"` | Directory where results are published. |
| `bowtie2_index` | string | `"${projectDir}/data/genome/TAIR10"` | Path to the Bowtie2 index of the host reference genome. |
| `kraken2_db` | string | `"${projectDir}/data/krakendb"` | Path to the Kraken2 database (must include Bracken database files). |
| `report` | string | `"${projectDir}/bin/report.Rmd"` | Path to the R Markdown template used by the Phyloseq report. |
| `read_length` | int | `250` | Read length used by Bracken for abundance estimation. |
| `report_id` | string | `"all_samples"` | Name of the final MultiQC report. |

### Profiles

| Profile | Description |
|---------|-------------|
| `conda` | Resolve tool dependencies with Conda (channels: `conda-forge`, `bioconda`, `defaults`). |
| `docker` | Resolve tool dependencies with Docker containers. |

## Output

Results are published to `outdir` (default `output/`), organized by step:

```
output/
├── bowtie2/                 # Bowtie2 alignment summary logs and unaligned reads
├── fastqc/                  # FastQC reports for raw reads (*.zip, *.html)
├── trimming/                # Trim Galore! reports, trimmed reads and FastQC
├── kraken2/                 # Kraken2 classifications (*.kraken2, *.k2report)
├── bracken/                 # Bracken abundance estimates (*.bracken, *.breport)
├── krona/                   # Interactive Krona HTML plots per sample
├── biom/                    # Merged BIOM table (merged.biom)
├── taxoReport.html          # Phyloseq diversity and abundance report (samplesheet mode)
└── multiqc/                 # MultiQC report (HTML + data directory)
```

## License

TaxoFlow is released under the [Creative Commons Attribution 4.0 International](LICENSE) (CC BY 4.0) license.

## References

1. Lu, J., Rincon, N., Wood, D.E. et al. Metagenome analysis using the Kraken software suite. *Nature Protocols* **17**, 2815–2839 (2022). https://doi.org/10.1038/s41596-022-00738-y
2. Wood, D.E., Lu, J. & Langmead, B. Improved metagenomic analysis with Kraken 2. *Genome Biology* **20**, 257 (2019).
3. Lu, J., Breitwieser, F.P., Thielen, P. et al. Bracken: estimating species abundance in metagenomics data. *PeerJ Computer Science* **3**, e104 (2017).
4. Langmead, B. & Salzberg, S.L. Fast gapped-read alignment with Bowtie 2. *Nature Methods* **9**, 357–359 (2012).
5. Ondov, B.D., Bergman, N.H. & Phillippy, A.M. Interactive metagenomic visualization in a Web browser. *BMC Bioinformatics* **12**, 385 (2011).