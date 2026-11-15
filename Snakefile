configfile: "config.yaml"


# =========================================================
# Download + FASTQ validation
# =========================================================

rule download_and_check:
    input:
        "sample.tsv"

    output:
        clean="results/download/clean_sample.tsv",
        bad="results/download/bad_samples.txt"

    script:
        "scripts/download_and_check.py"


# =========================================================
# DADA2 — Stage 1: Quality check
# =========================================================
#
# Run:
#
#     snakemake --cores 1 quality_check
#
# Then inspect:
#
#     results/qc/Forward_Quality.png
#     results/qc/Reverse_Quality.png
#
# After deciding truncLen, edit config.yaml.
# =========================================================

rule quality_check:
    input:
        clean="results/download/clean_sample.tsv"

    output:
        forward_quality="results/qc/Forward_Quality.png",
        reverse_quality="results/qc/Reverse_Quality.png"

    params:
        raw_dir=config["raw_dir"],
        output_dir="results/qc"

    threads: 1

    script:
        "scripts/dada2_quality_check.R"


# =========================================================
# DADA2 — Stage 2: Filtering + error-rate QC
# =========================================================
#
# After choosing truncLen in config.yaml:
#
#     snakemake --cores 8 filter_and_error_check
#
# Inspect:
#
#     results/qc/Forward_Filtered.png
#     results/qc/Reverse_Filtered.png
#     results/qc/Forward_Errors.png
#     results/qc/Reverse_Errors.png
#
# =========================================================

rule filter_and_error_check:
    input:
        clean="results/download/clean_sample.tsv",
        forward_quality="results/qc/Forward_Quality.png",
        reverse_quality="results/qc/Reverse_Quality.png"

    output:
        filtering="results/qc/Filtering.csv",
        forward_filtered="results/qc/Forward_Filtered.png",
        reverse_filtered="results/qc/Reverse_Filtered.png",
        forward_errors="results/qc/Forward_Errors.png",
        reverse_errors="results/qc/Reverse_Errors.png"

    params:
    	raw_dir=config["raw_dir"],
    	filtered_dir="results/filtered",
    	output_dir="results/qc",

    	truncLen_fwd=config["dada2"]["truncLen"]["forward"],
    	truncLen_rev=config["dada2"]["truncLen"]["reverse"],

    	maxEE_fwd=config["dada2"]["maxEE"]["forward"],
    	maxEE_rev=config["dada2"]["maxEE"]["reverse"],

    	trimLeft=config["dada2"]["trimLeft"],
    	truncQ=config["dada2"]["truncQ"],
    	maxN=config["dada2"]["maxN"]

    threads: 8

    script:
        "scripts/dada2_filter_error_check.R"


# =========================================================
# DADA2 — Stage 3: Full processing
# =========================================================
#
# Once you are happy with the filtering and error plots:
#
#     snakemake --cores 8 dada2_all
#
# =========================================================

rule dada2_all:
    input:
        db=config["idtaxa_db"],
        sample_table="results/download/clean_sample.tsv",

        filtering="results/qc/Filtering.csv",
        forward_errors="results/qc/Forward_Errors.png",
        reverse_errors="results/qc/Reverse_Errors.png"

    output:
        taxid="results/asv/No_chim/TaxID.csv",
        seqtab="results/qc/seqtab_post_removal.csv",
        data="results/asv/No_chim/data_0_Nochim.csv",
        features="results/asv/No_chim/features_0.csv"

    params:
        raw_dir=config["raw_dir"],
        filtered_dir="results/filtered",

        truncLen_fwd=config["dada2"]["truncLen"]["forward"],
        truncLen_rev=config["dada2"]["truncLen"]["reverse"]

    threads: 8

    script:
        "scripts/dada2_pipeline.R"


# =========================================================
# REFS
# =========================================================

rule refs:
    input:
        data="data/data_0.csv",
        features="data/features_0.csv",
        labels="data/labels.csv"

    output:
        expand("run{run}/results.txt", run=range(10))

    threads: 10

    shell:
        """
        python scripts/aBioInf100.py
        """


# =========================================================
# Summary
# =========================================================

rule summary:
    input:
        expand("run{run}/results.txt", run=range(10))

    output:
        sum="best/sum.csv",
        data="best/data_0.csv",
        features="best/features_0.csv",
        labels="best/labels.csv"

    shell:
        """
        python scripts/summaryMulti.py
        """


# =========================================================
# ROC
# =========================================================

rule roc:
    input:
        data="best/data_0.csv",
        features="best/features_0.csv",
        labels="best/labels.csv"

    output:
        "results/ml/roc.done"

    shell:
        """
        mkdir -p results/ml
        cp best/labels.csv best/labels_0.csv
        python scripts/ROCrunMultClassifiersMCC.py
        touch results/ml/roc.done
        """


# =========================================================
# Final figure
# =========================================================

rule figure:
    input:
        "best/sum.csv",
        "best/features_0.csv",
        "results/ml/roc.done"

    output:
        pdf="sumFig.pdf",
        png="sumFig.png"

    shell:
        """
        python scripts/sumFig.py
        """


# =========================================================
# Taxonomy annotation
# =========================================================

rule taxonomy_selected:
    input:
        features="best/features_0.csv",
        taxid="results/asv/No_chim/TaxID.csv"

    output:
        "results/ml/selected_features_taxonomy.csv"

    script:
        "scripts/map_selected_taxonomy.py"