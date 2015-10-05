---
layout: post
title: Filtering for tumor/normal variant calling with VarDict
categories:
- validation
tags:
- somatic
- small-variants
- validation
published: false
author: brad_chapman
excerpt:
---

# Overview

The goal of this post is to describe the approaches that went into deriving
filters for VarDict tumor/normal calling, using the
[synthetic 4 dataset from the ICGC-TCGA DREAM challenge](https://www.synapse.org/#!Synapse:syn312572/wiki/62018)
truth set. This dataset is more challenging than the
[synthetic 3 dataset used in the previous validation](http://bcb.io/2015/03/05/cancerval/)
due to the presence of 20% normal contamination and two sub-clones.

The filters derived from the synthetic 3 dataset analysis result in VarDict
underperforming on SNP sensitivity and precision, relative to MuTect:

![Original sensitivity and precision](http://i.imgur.com/Mn9DyZP.png)

after adjustment with a new filtering approach, VarDict is now on par with
MuTect for sensitivity and precision:

![Final sensitivity and precision](http://i.imgur.com/l3usJmS.png)

# Filter development

Provide a more lenient p-value filter (-P) to VarDict demonstrated that VarDict
[detects many of the missing variants](http://i.imgur.com/LZ3eCop.png), but this
also results in poor precision. By introducing two new filters for low
frequency variants, we were able to recover precision without losing the
sensitivity gains.

## Low frequency with low depth

The first filter generalizes
[the need for 13X coverage to accurately detect heterozygote calls](http://www.ncbi.nlm.nih.gov/pubmed/23773188).
We apply a filter with allele frequency and variant depth to identify lower
frequency calls lacking sufficient read support (AF * DP < 6). Given this set of
calls we filter on either of 3 possible metrics:

- Low mapping quality or reads with multiple mismatches. The general idea is
  that poorly mapped reads with multiple errors contribute to poor low
  frequency calls. For bwa mapping qualities, we filter calls with:
  (MQ < 55.0 and NM > 1.0 or MQ < 60.0 and NM > 2.0). Plotting the relationship
  between mapping quality (MQ) and number of mismatches (NM) shows the
  differences between these metrics in true positives, where they cluster near
  the edges of high mapping quality and a single mismatch:

  ![AFDP: mq nm true](http://i.imgur.com/lzPFRaA.png)

  compared to false positives, where there is a more even distribution of these
  values amongst the ranges of mapping quality and mismatches:

  ![AFDP: mq nm false](http://i.imgur.com/Aus76Z7.png)

- Low depth (DP < 10) -- Low depth calls contain a disproportionate number of
  false positives.

![AFDP: low depth](http://i.imgur.com/OipIRil.png)

- Low quality (QUAL < 45) -- Similarly, low quality values correlate with false
 positive calls.

![AFDP: low quality](http://i.imgur.com/W63W872.png)

## Low frequency with poor quality

The first set of filters improved precision but still left us with 3x the false
positives of MuTect. To improve precision further, we looked at the remaining
true and false positive calls and found false positives had a combination of low
frequency, low quality and high p-values:

- Allele frequency < 0.2

![low freq](http://i.imgur.com/1AeuVoc.png)

- Quality < 55

![low freq quality](http://i.imgur.com/H2G5OYM.png)

- P-value (SSF) > 0.06

![low freq p-value](http://i.imgur.com/XhlBQCu.png)
