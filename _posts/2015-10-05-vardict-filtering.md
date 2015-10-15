---
layout: post
title: Low frequency filters for cancer variant calling using VarDict
categories:
- validation
tags:
- cancer
- small-variants
- validation
published: false
author: brad_chapman
excerpt:
---

# Overview

The underlying work that goes into preparing good filters for variant calling is
not always exposed to the biologists who use variants for making research and
clinical decisions. Filter sets like
[the GATK best practice pipeline hard filters](https://www.broadinstitute.org/gatk/guide/article?id=2806)
[perform well](http://bcb.io/2014/05/12/wgs-trio-variant-evaluation/) and are
widely used, but lack detailed background on the underlying truth sets and
methods used to derive them.

As a result, some scientists treat variant calling and filtering as a solved
problem. This creates a disconnect between researchers who work on the underlying
algorithms and understand the filtering trade offs, and users who take
filtered variants as inputs to downstream analysis. Additionally, there is often
room for improvement in filters, even widely used ones. We recently
[tweaked mapping quality filters for GATK](http://imgur.com/a/oHRVB) from the
defaults to provide an improvement in sensitivity without loss of precision.

To provide more clarity into work we do as part of
[bcbio](https://github.com/chapmanb/bcbio-nextgen) development, this post describes
improved filters for
[VarDict tumor/normal cancer variant calling](https://github.com/AstraZeneca-NGS/VarDictJava).
VarDict (v1.4.1) is a freely available small variant (SNP and insertions/deletions) caller from
[Zhongwu Lai](https://twitter.com/ZhongwuL) and
[Jonathan Dry's](https://twitter.com/DrySci) group in
[AstraZeneca Oncology](http://www.astrazeneca.com/Home). The new set of filters
use the
[synthetic 4 dataset from the ICGC-TCGA DREAM challenge](https://www.synapse.org/#!Synapse:syn312572/wiki/62018)
truth set for validation. This dataset is more difficult than the
[synthetic 3 dataset used in previous validations](http://bcb.io/2015/03/05/cancerval/)
since it represents a heterogeneous tumor with 20% normal contamination and two
lower frequency sub-clones.

The filters originally derived from the synthetic 3 dataset analysis result in
VarDict underperforming on SNP sensitivity and precision, relative to
[MuTect (v1.1.5)](https://www.broadinstitute.org/cancer/cga/mutect):

![Original sensitivity and precision](http://i.imgur.com/Mn9DyZP.png)

after adjustment with a new filtering strategy, VarDict is now on par with
MuTect for SNP sensitivity and precision, and better than
[Scalpel (v0.5.1)](http://scalpel.sourceforge.net/) on sensitivity for insertions and
deletions:

![Final sensitivity and precision](http://imgur.com/S6K27fq.png)

The improvement in VarDict come from improved filtering of lower frequency mutations.
Detecting these is critical to understanding tumor heterogeneity, but is also
more challenging, analogous to the way that filters for germline calling often
benefit discrimination of heterozygote calls.

We'll walk through the new filters that led to the improvement, showing plots of
distribution differences that identified the new linear combinations of
filtering parameters. Finally we'll discuss the visual approach
used here versus machine learning methods, and how we hope to avoid
over-training and devise generally useful filters for detecting low frequency
variants.

# Filter development

The key insight for improving VarDict sensitivity was that providing a more
lenient p-value filter (`-P`) to VarDict results in
[detection of many of the initially missing variants](http://i.imgur.com/LZ3eCop.png).
However, setting a lenient p-value filter also results in poor precision.
By using this as a starting point and introducing two new filters for low
frequency variants, we were able to recover good precision without losing the
sensitivity gains.

## Low frequency with low depth

The first filter generalizes
[the requirement for 13X coverage to accurately detect heterozygote calls](http://www.ncbi.nlm.nih.gov/pubmed/23773188).
We apply a linear filter of multiple metrics that looks only at lower frequency (AF)
and lower depth (DP) calls. Within this set of calls, we filter only variants
failing one of 3 other criteria for mapping quality (MQ), number of read
mismatches (NM), low depth (DP) or low quality (QUAL). In pseudo-code, the new filter is:

    ((AF * DP < 6) &&
     ((MQ < 55.0 && NM > 1.0) ||
      (MQ < 60.0 && NM > 2.0) ||
      (DP < 10) ||
      (QUAL < 45)))

Breaking this down into each filtering criteria:

- Remove variants supported by reads with low mapping quality and multiple
  mismatches. The general idea is that poorly mapped reads with multiple errors
  contribute to poor low frequency calls. VarDict reports two useful metrics:
  the mean number of mismatches (NM) and mean mapping quality (MQ) for the reads
  covering a position in the genome. For bwa mapping qualities, we filter calls
  with (MQ < 55.0 and NM > 1.0 or MQ < 60.0 and NM > 2.0). Plotting the
  relationship between mapping quality (MQ) and number of mismatches (NM) shows
  the distributions of these metrics. In true positives they cluster
  near the edges of high mapping quality and a single mismatch:

  ![AFDP: mq nm true](http://i.imgur.com/lzPFRaA.png)

  In false positives there is a more even distribution of the
  values amongst the ranges of mapping quality and mismatches:

  ![AFDP: mq nm false](http://i.imgur.com/Aus76Z7.png)

  This filter is currently tuned to the
  [bwa aligner (v0.7.12)](https://github.com/lh3/bwa), which uses 60 as the
  maximum mapping quality. In bcbio, we only use this filter when using the bwa
  aligner, but we'd also like to generalize by testing with other alignment
  methods and associating poor mapping quality scores with genome mappability
  tracks.

- Low depth (DP < 10) -- Low depth calls contain a disproportionate number of
  false positives.

![AFDP: low depth](http://i.imgur.com/OipIRil.png)

- Low quality (QUAL < 45) -- Similarly, low quality values correlate with false
 positive calls.

![AFDP: low quality](http://i.imgur.com/W63W872.png)

## Low frequency with poor quality

The first set of filters improved precision but still retained 3x more false
positives compared with MuTect. To improve precision further, we looked at the
remaining true and false positive calls and found false positives had a
combination of low frequency (AF), low quality (QUAL) and high p-values (SSF).
The pseudo-code for this filter is:

    AF < 0.2 && QUAL < 55 && SSF > 0.06

Breaking down the distribution differences for each of these filters.

- Allele frequency < 0.2

![low freq](http://i.imgur.com/1AeuVoc.png)

- Quality < 55

![low freq quality](http://i.imgur.com/H2G5OYM.png)

- P-value (SSF) > 0.06

![low freq p-value](http://i.imgur.com/XhlBQCu.png)

# Filter development

The identification of filters involved manual inspection of metrics graphs. We
run automated calling and validation with bcbio, then plot metrics and look for
differences that discriminate true and false positive calls. Practically, we
extract metrics from VCF files into tables using
[bio-vcf](https://github.com/pjotrp/bioruby-vcf), then plot with
[pandas](http://pandas.pydata.org/),
[seaborn](http://stanford.edu/~mwaskom/software/seaborn/index.html) and
[matplotlib](http://matplotlib.org/). Since the base set of calls already
optimize single metric filters, we start with linear combinations of metrics,
subsetting and re-plotting as we identify sets of filters that do a good job of
separating signal and noise.

This approach is analagous to applying machine learning tools to discriminate
true and false positives on the training set, and we'd like to incorporate
additional automated approaches as we continue to improve filters. In the past
we've used
[support vector machines (SVMs)](https://en.wikipedia.org/wiki/Support_vector_machine)
to learn and apply filtering metrics. This approach worked well, but tended to
over-train to specific datasets. Because it was difficult to extract the
underlying relationships in the filter, we didn't have a way to reliably
estimate when a filter was general versus over-trained. We'd ideally like to use
a hybrid approach where we use machine learning to identify potentially useful
linear combinations of metrics, then refine these with manual inspection.

Our goal with using these DREAM synthetic truth sets is to discover generally
useful metrics, rather than performing well on this particular dataset. To avoid
over-training we use our best intuition to select metrics based on depth and
quality which will apply generally across other samples. The best test of
generalizability will be cross-validations on other samples. A
[recent paper from Malachi Griffith, Chris Miller and colloborators at the McDonnell Genome Institute](http://www.cell.com/cell-systems/abstract/S2405-4712%2815%2900113-1)
has an [extensively characterized AML31 case](http://aml31.genome.wustl.edu/)
with validated variants. We plan to cross-validate on this dataset to continue
to improve filtering approaches for heterogeneous, low frequency variants.

The updated filters for VarDict improve sensitivity and precision on low
frequency variants, achieving call rates on par with MuTect for SNPs and with
more sensitive than Scalpel for insertions and deletions. We'd love feedback
from others with experience doing this type of filtering, and would especially
welcome suggestions for practical methods for apply machine learning methods to
the initial metric selection steps.

The filtering approach we took is general and can apply to other callers,
although it's not always easy to derive metrics that will effectively separate
true and false calls. For instance, we also wanted to improve MuTect and Scalpel
calling on this dataset. MuTect doesn't offer quality or other annotation
metrics to provide a way to build additional filters beyond their implemented
heuristics. Scalpel does provide additional metrics and has additional true
positive calls filtered by the default calling approach so could improve in
sensitivity. However,
[we were unable to improve sensitivity without a large decrease in precision](http://imgur.com/a/7Dzd3).
Unfortunately improving callers is still often a laborious process done on a
case-by-case basis. We hope to continue to improve the process by automating
validation work and incorporating
[a large number of diverse validation sets](https://bcbio-nextgen.readthedocs.org/en/latest/contents/configuration.html#validation).

# Running the analysis

Full details for running this comparison are available in
[the bcbio example pipeline documentation](https://bcbio-nextgen.readthedocs.org/en/latest/contents/testing.html#cancer-tumor-normal).
The DREAM synthetic 4 dataset requires
[obtaining access through ICGC-DACO](https://www.synapse.org/#!Synapse:syn312572/wiki/60702)
since the input data comes from real human tumors. It does challenge variant
callers more than the unrestricted synthetic dataset 3 due to the added
heterogeneity and lower frequency variants.

Once you have access to the input data, bcbio automatically runs alignment,
variant calling and validation, producing the validation graphs shown above. The
synthetic 4 example includes alignments for both build 37 and 38 as well as
structural variant calling, so is a full tumor characterization you can use as a
template for calling on your cancer samples. By combining validation and
analysis tools we provide a useful distribution for both improving algorithms
and running real research samples.
