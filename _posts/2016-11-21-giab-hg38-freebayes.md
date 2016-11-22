---
layout: post
title: Validation of Genome in a Bottle human Genome Build 38 truth set and FreeBayes 1.1.0
categories:
- validation
tags:
- germline
- small-variants
- validation
published: false
author: brad_chapman
excerpt:
---


# Human build 38 (hg38) validation

We previously [validated callers against human genome build 38](http://bcb.io/2015/09/17/hg38-validation/)
using a combination of lifted over truth sets from [Genome in a Bottle](http://genomeinabottle.org/) and
native truth sets from [Illumina's Platinum Genome project](http://www.illumina.com/platinumgenomes/).
The goal was to establish
the new human genome build as a suitable target for sequencing new projects.
Since then, hg38 has seen increased adoption and the Genome in a Bottle
consortium released [a new truth set with support for hg38
(v3.3.1)](https://groups.google.com/a/genomicsandhealth.org/d/msg/ga4gh-dwg-benchmarking/Ng0uzT0H4S0/pUtSJdcRAwAJ).

We wanted to confirm the previous results and help contribute to refiniing the
truth set, and validated two callers against it:

- [GATK HaplotypeCaller](https://software.broadinstitute.org/gatk/) -- a post
   3.6 nightly release with fixes for some issues in 3.6.
- [FreeBayes](https://github.com/ekg/freebayes) -- v1.0.2-29 and new v1.1.0 with
  improved speed and memory usage.

The results generally agree with our previous analysis and both callers perform
well relative to hg19:

![hg38](http://i.imgur.com/l03f9ax.png)

We dig more into additional indel false negatives and positives and also discuss
the advantages of moving to FreeBayes 1.1.0.

## False negative indels: heterozygote/homozygote differences

One hg38 validation result where callers performed worse than hg19 is indel
sensitivity. SNP sensitivity and specificity for hg19 and hg38 is similar, but
both callers have higher false positive and negative rates for indel detection
on hg38. However, hg38 also allows detection of ~30k more indels so does offer
benefits as well.

To investigate the reasons for this difference we looked at variants in the
GiaB hg38 truth set missed by both FreeBayes and GATK HaplotypeCaller, which
account for 25k of the 33k false negatives. Of these missing variants
HaplotypeCaller and FreeBayes call passing variant at 7.8k and 5.5k positions,
respectively.

The discrepancies appear to be due to resolution of heterozygotes versus
homozygotes. The same variants get called but Genome in a Bottle labels them as
homozygotes and FreeBayes and HaplotypeCaller as heterozygotes:

    GiaB:      chr1 1370553  CA  C  GT:DP:AD   1|1:242:1,97

    FreeBayes: chr1 1370553  CA  C  GT:DP:AD   0|1:23:3,9
    GATK:      chr1 1370553  CA  C  GT:AD:DP   0/1:4,9:13

Here are the shared variants and positions where we see these issues:

https://s3.amazonaws.com/biodata/giab/hg38/hg38-giab_3_3_1-freebayes-gatk.tar.gz

## FreeBayes 1.1.0

The latest version of FreeBayes (v1.1.0) replaces the underlying BAM
manipulation library with [SeqLib](https://github.com/walaj/SeqLib). SeqLib
wraps [htslib](https://github.com/samtools/htslib), and several other
bioinformatics libraries like the [bwa](https://github.com/lh3/bwa) aligner and
[fermi](https://github.com/lh3/fermi-lite) assembler, under a consistent C++
API. Since the SeqLib/htslib interface has faster and lighter BAM readinga and
writing compared to the previous BamTools implementation, this reduces memory
usage and increases runtimes by 3x. The validations show that the FreeBayes
SeqLib results in 1.1.0 are equivalent to those from the previous validated
version (1.0.2-29).

We can freely move analyses to FreeBayes v1.1.0 to take advantage of the speed
gains without any changes in sensitivity and specificity.

TODO: validate FreeBayes 1.1.0 on DREAM synthetic 4 or 6 data
