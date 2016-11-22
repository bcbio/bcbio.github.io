---
layout: post
title: Validation of Genome in a Bottle hg38 truth set and FreeBayes 1.1.0
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

# Overview

We previously [validated callers against human genome build 38](http://bcb.io/2015/09/17/hg38-validation/)
using a combination of lifted over truth sets from [Genome in a Bottle](http://genomeinabottle.org/) and
native truth sets from [Illumina's Platinum Genome project](http://www.illumina.com/platinumgenomes/).
The goal was to establish
the new human genome build as a suitable target for sequencing new projects.
Since then, hg38 has seen increased adoption and the Genome in a Bottle
consortium released [a new truth set with support for hg38
(v3.3.1)](https://groups.google.com/a/genomicsandhealth.org/d/msg/ga4gh-dwg-benchmarking/Ng0uzT0H4S0/pUtSJdcRAwAJ).

We validated two callers against this truth set:

- [GATK HaplotypeCaller](https://software.broadinstitute.org/gatk/) -- a post
   3.6 nightly release with fixes for some issues in 3.6.
- [FreeBayes](https://github.com/ekg/freebayes) -- v1.0.2-29 and new v1.1.0 with
  improved speed and memory usage.

The results generally agree with our previous analysis and both callers perform well:

![hg38](http://i.imgur.com/32TCGi3.png)

We dig more into false negative and false positive problems with indels on both
callers and also discuss the advantages of FreeBayes 1.1.0.

## False negative indels: heterozygote/homozygote differences

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
