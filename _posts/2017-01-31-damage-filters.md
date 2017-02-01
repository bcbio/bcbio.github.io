---
layout: post
title: Removal of low frequency false positives due to DNA damage
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

# DNA damage

Detecting low frequency variant calling in somatic cancer samples is difficult
due to the presence of preparation and sequencing induced errors. These cause,
or amplify, weak error signals leading to low frequency false positive calls.
Common damage artifacts in somatic samples include
[oxidative damage (oxoG) during sample preparation](https://academic.oup.com/nar/article-lookup/doi/10.1093/nar/gks1443)
and [deamination during FFPE preparation](http://core-genomics.blogspot.com/2014/08/ffpe-bane-of-next-generation-sequencing.html).

There are existing tools to help measure and remove these biases.
The [D-ToxoG Matlab script](http://archive.broadinstitute.org/cancer/cga/dtoxog)
from the original Broad paper removes oxidative damage artifacts with <1%
frequency. Picard's
[CollectOxoGMetrics and CollectSequencingArtifactMetrics](https://broadinstitute.github.io/picard/command-line-overview.html)
programs identify the global presence of damage.
The [Damage estimator tool](https://github.com/Ettwiller/Damage-estimator) and
[paper](http://biorxiv.org/content/early/2016/08/23/070334) from New England
Biolabs calculate and plot overall DNA damage bias.

We use the [DKFZ Bias Filter](https://github.com/eilslabs/DKFZBiasFilter) tool
from the [Eils labs](http://ibios.dkfz.de/tbi/) to identify, plot and remove
artifacts. It identifies two types of artifacts:

- Strand bias (`bSeq`) imbalance between forward and reverse reads. These are
  typically due to sequencing errors.
- PCR bias (`bPcr`) imbalance between read 1 and read 2, due to DNA damage:
   - Oxidative (oxoG) damage -- `G->T` (read 1), `C->A` (read 2)
   - FFPE deamination -- `C->T` (read 1), `G->A` (read 2)

# FFPE and capture sample

To examine the practical presence of damage, we ran DKFZ filtering scripts on an
FFPE [IDT cancer exome capture](https://www.idtdna.com/pages/products/nextgen/target-capture)
sample. Filtered [VarDict](https://github.com/AstraZeneca-NGS/VarDictJava)
low frequency somatic calls were the baseline for removal with most reads
removed containing 1 or 2 supporting reads for the variant and allele
frequencies of less than 5%.

## Damage errors

The majority of errors were apparent oxidative damage with secondary FFPE
deamination changes:

    G->T 44559
    C->A 44370
    C->T 1824
    G->A 1753
    A->G 932
    T->C 924
    C->G 655
    G->C 671

The filtered calls have 1 or 2 supporting reads:

| reads | count |
| ----- | ----- |
| 1     | 82327 |
| 2     | 12852 |
| 3     | 720   |
| 4     | 73    |

## Sequencer errors

Sequencer bias errors may be carry overs from damage based bias, as they're also
apparent oxidative damage:

    G->T 8035
    C->A 2190
    G->C 443
    C->G 139
    T->A 231
    A->T 98
    A->C 164
    T->G 130

These also have few supporting reads:

| reads | count |
| ----- | ----- |
| 1     | 8377  |
| 2     | 2046  |
| 3     | 225   |
| 4     | 74    |

## Passing calls

As a baseline, these are the low supporting read counts for passing variants, so
there are still a large number of unfiltered:

| reads | count  |
| ----- | ------ |
| 1     | 147694 |
| 2     | 44710  |
| 3     | 6980   |
| 4     | 2448   |

## Plots

The plots produced by DKFZBiasFilter provide a graphical representation of
overabundant calls relative to their genomic context. Colors indicate
over/under-representation of bias, and how the reduction of error types with
bias occurs through filtering.

### Damage errors

![damage plot](http://i.imgur.com/FNFsq22.png)

### Sequencing errors

![sequencing error plot](http://i.imgur.com/UmMj02s.png)
