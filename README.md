## KrakenFlow

<p align="center">
    <img src="assets/Kraken_logo.png" alt="KrakenFlow" width="50%">
</p>

KrakenFlow is a reproducible Nextflow pipeline for fast, accurate taxonomic profiling of short‑read metagenomic datasets. It combines host/contaminant filtering with Bowtie2, taxonomic assignment with Kraken2, abundance re‑estimation with Bracken, interactive visualization with Krona, and an optional multi‑sample report built with phyloseq/R Markdown.

### What it does
- **Filter reads with Bowtie2**: removes reads mapping to a reference (e.g., yeast) to reduce false positives downstream.
- **Classify with Kraken2**: generates per‑sample classification output and a `.k2report` summary.
- **Re‑estimate abundances with Bracken**: produces species‑level abundance tables (`.bracken`) and human‑readable reports (`.breport`).
- **Visualize with Krona**: creates an interactive `.krona.html` per sample.
- **(Optional) Multi‑sample BIOM + report**: merges Bracken outputs into `merged.biom` and renders `report.html` via an R Markdown template when a samplesheet is used.

### Pipeline at a glance
<p align="center">
    <img src="assets/workflow_kraken.png" alt="Workflow" width="90%">
</p>

### Requirements
- **Nextflow**: `>=22.10.0` recommended. Install: https://www.nextflow.io/
- **Container engine**: Docker enabled by default in `nextflow.config`.
  - Alternative engines (Podman/Singularity/Apptainer) can work with small config tweaks.
- **Databases/Indexes**:
  - A valid **Bowtie2 index** for the host/contaminant you wish to filter (example yeast index is included).
  - A **Kraken2 database** (e.g., Standard, PlusPF, or a custom DB). See: https://github.com/DerrickWood/kraken2/wiki/Manual#kraken-2-databases

### Repository layout
- `main.nf` and `workflow.nf`: pipeline entry and orchestration
- `modules/`: individual process modules (`bowtie2`, `kraken2`, `bracken`, `kReport2Krona`, `ktImportText`, `kraken_biom`, `knit_phyloseq`)
- `data/yeast/`: example Bowtie2 yeast index
- `data/samples/`: example FASTQs layout
- `data/samplesheet.csv`: example multi‑sample sheet (columns: `sample_id,fastq_1,fastq_2`)
- `bin/report.Rmd`: R Markdown template used to build the optional multi‑sample report

### Inputs
You can provide input reads in two ways:

1) FASTQ glob pattern via `--reads`
- Example pattern: `"data/samples/*/*_{1,2}.fastq"`
- The pipeline will pair `*_1.fastq`/`*_2.fastq` automatically per sample.

2) Samplesheet via `--sheet_csv`
- CSV with headers: `sample_id,fastq_1,fastq_2`
- See the included `data/samplesheet.csv` for the expected format.

### Key parameters (override defaults as needed)
- `--reads`: Glob for paired FASTQs (mutually exclusive with `--sheet_csv`).
- `--sheet_csv`: CSV with `sample_id,fastq_1,fastq_2` (enables BIOM + report).
- `--outdir`: Where results are written. Default is set in `nextflow.config`.
- `--bowtie2_index`: Prefix to the Bowtie2 index used for filtering.
- `--kraken2_db`: Path to your Kraken2 database directory.
- `--report`: Path to the Rmd template for the multi‑sample report.

Defaults in `nextflow.config` point to training paths; you will typically override them on the command line.

### Quickstart
Make sure you have Nextflow and Docker installed, then from the `KrakenFlow` directory:

Basic run with the included example yeast index and sample layout (replace the Kraken2 DB path):

```bash
nextflow run main.nf \
  --reads "data/samples/*/*_{1,2}.fastq" \
  --outdir "output" \
  --bowtie2_index "data/yeast/yeast" \
  --kraken2_db "/path/to/kraken2_db"
```

Run using a samplesheet (enables merged BIOM + R Markdown report):

```bash
nextflow run main.nf \
  --sheet_csv "data/samplesheet.csv" \
  --outdir "output" \
  --bowtie2_index "data/yeast/yeast" \
  --kraken2_db "/path/to/kraken2_db" \
  --report "bin/report.Rmd"
```

Notes:
- The included yeast Bowtie2 index prefix is `data/yeast/yeast`.
- You must supply a real Kraken2 database path; this repository does not include one.

### Outputs
For each `sample_id` in `--outdir`:
- `${sample_id}.sam`: filtered alignments (from Bowtie2)
- `${sample_id}.k2report`: Kraken2 report
- `${sample_id}.kraken2`: Kraken2 classifications
- `${sample_id}.bracken`: Bracken abundance estimates (species level by default)
- `${sample_id}.breport`: Bracken human‑readable report
- `${sample_id}.b.krona.txt`: Krona input table
- `${sample_id}.krona.html`: interactive Krona chart

For multi‑sample runs (when `--sheet_csv` is used):
- `merged.biom` in `--outdir`
- `report.html` in `--outdir` (phyloseq‑based overview)

### Reproducibility
All tools run inside pinned containers (see `modules/*.nf`). Docker is enabled in `nextflow.config`; Nextflow will automatically pull the required images on first use.

### Tips and troubleshooting
- If Docker is not available, set an alternative executor in `nextflow.config` (e.g., `podman`, `singularity`) and ensure the images are accessible.
- Ensure your Kraken2 DB was built with k‑mer length and read length appropriate for your data; adjust Bracken parameters if you change read length.
- For large datasets, set a custom `--outdir` on a high‑capacity filesystem.

### Citation
If you use this workflow, please cite the underlying tools:
- Wood DE, Lu J, Langmead B. Kraken 2. Genome Biology (2019).
- Lu J, Breitwieser FP, Thielen P, Salzberg SL. Bracken. PeerJ Computer Science (2017).
- Langmead B, Salzberg SL. Bowtie 2. Nature Methods (2012).
- Ondov BD et al. Krona. BMC Bioinformatics (2011).

And the training material adapted for the R Markdown report as referenced in `bin/report.Rmd`.



