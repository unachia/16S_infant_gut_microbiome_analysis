# 16S Infant Gut Microbiome Analysis

A reproducible Snakemake workflow for analysing publicly available infant gut microbiome data from NCBI, integrating 16S rRNA sequencing data with metadata on infant feeding practices.

## Project Overview

This project analyses infant gut microbiome datasets to investigate microbial differences associated with feeding practices. The dataset contains 16S rRNA sequencing data together with information on infant feeding type and feeding periods.

The workflow combines sequencing data processing, microbiome analysis and downstream machine-learning classification to identify microbial features that discriminate between breast-fed and formula-fed infants.

## Research Question

Can gut microbial profiles distinguish between breast-fed and formula-fed infants, and which microbial features contribute most to the classification?

## Workflow

```text
Public NCBI dataset
        │
        ▼
16S rRNA sequencing data + infant metadata
        │
        ▼
Quality control & preprocessing
        │
        ▼
Microbiome analysis
        │
        ▼
Feature preparation
        │
        ▼
Machine-learning classification
        │
        ▼
Discriminative microbial features
