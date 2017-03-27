---
layout: post
title: Heterogeneity tools: working plan and validation
categories:
- heterogeneity
tags:
- somatic
- small-variants
- copy-number-variants
- validation
published: false
author: brad_chapman
excerpt:
---

# Inputs

- Germline heterozygous SNPs, informative for purity/ploidy/clone estimation
  Need estimation for tumor-only
- Copy number calls -- GC corrected and normalized (to normal or process-matched
  normal)
- Split copy number calls into major/minor alleles, potentially with multiple
  states
- Somatic variant calls with allele frequencies, for tumor subclones
- Estimate subclones from somatic calls + major/minor CNVs

## Challenges

- Heterogeneous input samples ranging from WGS tumor/normal to panel/capture
  tumor-only, would like to have similar workflow to handle most cases
- Lack of good truth sets, so hard to determine if truth sets work well
- Most tools not fully automated and require some decision making during the
  process

## Example figures

  - Overview of problem
    Figure 1: http://genomebiology.biomedcentral.com/articles/10.1186/s13059-015-0602-8

  - sequencing levels required for reconstruction depending on clonal complexity
  Figure 5: http://www.cell.com/action/showImagesData?pii=S2405-4712%2815%2900113-1
  Figure 6: http://genomebiology.biomedcentral.com/articles/10.1186/s13059-015-0602-8

# Tools

## Purity, CNV allelic copy number

PureCN -- purity/ploidy, classify variants as germline/somatic clonal/subclonal,
          panels/exome > 100x, support for no matching normals but needs process-matched normal BAM
http://bioconductor.org/packages/release/bioc/html/PureCN.html

BubbleTree: purity, LOH and subclonality WGS/exome, from heterozygous variants
            and CNVs
http://www.bioconductor.org/packages/release/bioc/html/BubbleTree.html

TitanCNA -- WGS/exome; heterozygous variants => purity, CNVs into major/minor
            subclones, LOH
https://github.com/gavinha/TitanCNA

Battenberg -- WGS tumor/normal; BAMs => purity, CNV caller into major/minor subclones
https://github.com/cancerit/cgpBattenberg

## Subclonal reconstruction

PhyloWGS -- subclone and tumor evolution from Battenberg or TITAN output
            (major/minor allele CN)+ VCFs
https://github.com/morrislab/phylowgs

SciClone -- exome/WGS: somatic CNV calls + variants. Uses only variants in CN=2
            CN=2 regions, requires a relatively stable genome to have enough events.
https://github.com/genome/sciclone
https://github.com/hdng/clonevol

Canopy -- exome/WGS: allele specific CNVs + variants. Recommend using Sequenza
          as input segmented CNV calls.
https://github.com/yuchaojiang/Canopy
https://github.com/yuchaojiang/Canopy/blob/master/instruction/SNA_CNA_input.md

Guan Lab, U of M -- Somatic variants and CNVs, SMC-Het winner but demonstration implementation only
https://www.synapse.org/#!Synapse:syn6087005/wiki/398911

THetA -- integrated, CNVs only, academic only in latest version
https://github.com/raphael-group/THetA

PyClone -- academic only
https://bitbucket.org/aroth85/pyclone/wiki/Home

### CNV callers

 - CNVkit https://github.com/etal/cnvkit
 - Seq2C https://github.com/AstraZeneca-NGS/Seq2C
 - Canvas https://github.com/Illumina/Canvas

# Validation

tHapMix simulation -- WGS tumor/normal https://github.com/Illumina/tHapMix
ICGC-TCGA DREAM Tumor Heterogeneity Challenge (VCF + Battenberg stratified
  output), no truth sets available
https://www.synapse.org/#!Synapse:syn2813581/wiki/303137

## Remove artifacts

- small variants -- Damage assessment
- germline CNVs https://github.com/chapmanb/bcbio-nextgen/issues/963

## CNV benchmarking

HCC2218 truth set from Canvas https://github.com/Illumina/Canvas#demo-tumor-normal-enrichment-data
GiaB NA24385 CNVs http://biorxiv.org/content/early/2016/12/13/093526
