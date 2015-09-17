---
layout: post
title: Validated variant calling with human genome build 38
date: 2015-09-17 08:53:00
categories:
- validation
tags:
- validation
- germline
- small-variants
published: true
author: brad_chapman
excerpt:
---

This post describes a ready to run
[bcbio implementation](https://github.com/chapmanb/bcbio-nextgen) of variant
calling and validation on human genome build 38, demonstrating its utility for
improving variant detection.

[Human genome build 38](http://genomeref.blogspot.com/2013/12/announcing-grch38.html) (hg38, GRCh38) offers a major upgrade over the previous
build, 37 (hg19, GRCh37). The new genome reflects our increased understanding of
the heterogeneity within human sub-populations and contains a large number of
alternative genomic loci that better capture our knowledge of genome structure.
Better genomic representation improves mapping, avoiding a source of hard to
remove false positives during variant calling, and moves towards more accurate
graph-based representations of the genome.

Practically, the community has been slow to move to build 38 in the year and a
half since its official release. There was a
[nice discussion in the bioinformatics subreddit](https://www.reddit.com/r/genome/comments/3b3s3t/switch_from_hg19build37_to_hg20build38/)
about adoption challenges. Our experience has been that researchers want the
improvements in 38 but two areas hold them back:

-   Lack of validated truth sets for build 38. We make extensive use of the
    NA12878 truth sets from
    [the Genome in a Bottle consortium](http://genomeinabottle.org/) and
    [Illumina's platinum genomes](http://www.illumina.com/platinumgenomes/) for
    germline calling, and the
    [ICGC-TCGA DREAM challenge](https://www.synapse.org/#!Synapse:syn312572/wiki/)
    for cancer calling. Not having these ground truths for build 38 makes it
    difficult to validate and improve analysis tools.

-   Lack of resources for build 38. Tools like
    [GEMINI](http://gemini.readthedocs.org/en/latest/) provide a large number of
    [external annotations associated with variations](http://gemini.readthedocs.org/en/latest/content/database_schema.html#the-variants-table),
    many of which are not yet prepared for build 38. Over time, these resources
    will become increasingly available but we need a stop gap solution to
    convert 37-only resources to build 38.
    [liftOver](http://genome.ucsc.edu/cgi-bin/hgLiftOver),
    [CrossMap](http://crossmap.sourceforge.net/) and
    [NCBI remap](http://www.ncbi.nlm.nih.gov/genome/tools/remap) enable
    coordinate conversion, but we lack validations of the positives and
    negatives of each method.

Both of these transition challenges result in fewer tested and validated tools
for 38, which makes migration for new projects challenging. The goal of this
post is to enable use of build 38 by:

-   Providing support for variant calling on build 38 in
    [bcbio](https://github.com/chapmanb/bcbio-nextgen). The
    [bcbio automated installation](https://bcbio-nextgen.readthedocs.org/en/latest/contents/installation.html)
    now includes two build 38 genome targets: hg38 --
    [the full 38 build from 1000 genomes with alternative contigs, including HLA](ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/);
    and hg38-noalt --
    [build 38 with no alternative loci, from NCBI](ftp://ftp.ncbi.nlm.nih.gov/genbank/genomes/Eukaryotes/vertebrates_mammals/Homo_sapiens/GRCh38/seqs_for_alignment_pipelines/).

-   Validating build 38 variant calling against two truth sets:
    [Genome in a Bottle NA12878 build 37 calls](http://genomeinabottle.org/)
    converted to 38 coordinates, and
    [an Illumina Platinum Genome NA12878 truth set](http://www.illumina.com/platinumgenomes/)
    natively prepared with alignment and calling using the build 38 primary
    assembly. The native Platinum Genomes truth set avoids the complications of
    converting Genome in a Bottle coordinates, at the expense of not having
    orthogonal validation of variants from non-Illumina technologies.

-   Comparing coordinate conversion methods. We used
    [NCBi's Remap](http://www.ncbi.nlm.nih.gov/genome/tools/remap) and
    [CrossMap](http://crossmap.sourceforge.net/) with a
    [UCSC chain file](http://hgdownload.cse.ucsc.edu/goldenPath/hg19/liftOver/)
    to convert the Genome in a Bottle reference prior to validating, allowing
    comparison of the effectiveness of both methods.

The results show improved variant detection for build 38 compared
with 37, along with a reduction in false positive calls using the full genome
build with alternative contigs.

Both coordinate conversion methods are a reasonable alternative when full
realignment and reanalysis is impractical. Validation results with NCBI Remap
and CrossMap are comparable to results using fully reanalyzed reference genomes.
The remaining challenges are in the last 1% of difficult to convert variants.

This work is possible thanks to our collaborations with the
[Wolfson Wohl Cancer Research Centre](http://www.gla.ac.uk/researchinstitutes/cancersciences/ics/facilities/wwcrc/)
and [AstraZeneca Oncology](http://www.astrazeneca.com/Home). It is also due to
help from members of the bcbio community, thanks to
[the extensive discussion around build 38 support](https://github.com/chapmanb/bcbio-nextgen/issues/817).
I'd like to especially thank [Deanna Church](https://twitter.com/deannachurch)
for writing the original scripts for remapping Genome in a Bottle to build 38;
[Laura Clarke](https://www.ebi.ac.uk/about/people/laura-clarke) for preparing a
number of hg38 resources from the 1000 genomes project; and
[Alison Meynert](https://www.linkedin.com/pub/alison-meynert/25/b19/556) for
using CrossMap to generate the resource files used by GATK variant calling. Many
of the tools and truth sets developed from the work of the
[Global Alliance for Genomics and Health (GA4GH) Benchmarking Team](http://ga4gh.org/#/benchmarking-team).
I'm so grateful for the community and collaborations that make this work
possible.

# Why support build 38?

Moving to build 38 requires an investment in validation, resource preparation
and tool integration. This effort is worthwhile because of the improvements
which help eliminate errors due to the genome build itself. Deanna Church has a
[great slide deck](http://www.slideshare.net/GenomeRef/transitioning-to-grch38)
that summarizes the advantages of 38:

-   Removal of false positives due to additional genomic regions in
    build 38. If a region is missing from the reference build but a nearly identical
    segment is present, the read from the missing region will map to the incorrect
    segment. This results in hard to remove false positive variants in that segment.

-   Better capture of the diversity of the human genome by inclusion of
    alternative haplotypes. A reference assembly is a useful construct for
    creating a shared coordinate space for collaborating, but sub-populations need
    to have representations of their unique sequences to ensure correct analysis.
    This is especially true for medically important genes where we'll soon be
    making clinical decisions.

-   The inclusion of
    [highly diverse](https://twitter.com/erikgarrison/status/636089957979942912)
    [human leukocyte antigen (HLA) regions](https://en.wikipedia.org/wiki/Human_leukocyte_antigen)
    allows
    [HLA typing](https://github.com/lh3/bwa/blob/master/README-alt.md#hla-typing),
    enabling insight into these important immune system genes.

-   Moving to a
    [graph based representation of the human genome](http://www.genomebiology.com/2015/16/1/13).
    Capturing the heterogeneity of human populations requires
    [cataloging and representing](http://news.ucsc.edu/2015/01/genome-variation.html)
    all potential variants, especially larger structural variations present only
    in sub-populations. Build 38 is a nice step that prepares our tools and
    analysis methods to consider alternative haplotypes across the genome.

In short, the smart people at the
[Genome Reference Consortium](http://www.ncbi.nlm.nih.gov/projects/genome/assembly/grc/index.shtml)
produced a thoroughly improved version of the human genome based on our
increasing knowledge of variability. It's a scientific improvement, and the main
challenges are how to validate and ensure that our existing tools work well with
the changes.

# Validation

Our primary goal was to provide variant calling on build 38 with
[automated validation](http://bcb.io/2014/10/07/joint-calling/). Based on
[Heng Li's validation of 38 using haploid/diploid comparisons with CHM1/NA12878](https://github.com/lh3/bwa/blob/master/README-alt.md#preliminary-evaluation)
we expected to find a larger number of variants detected in build 38 with a reduction in
false positives when using a build with alternative haplotypes.

We aligned 50x NA12878 100bp reads, available from
[Illumina Platinum Genomes](http://www.illumina.com/platinumgenomes/), using
[bwa-mem](https://github.com/lh3/bwa) (v0.7.12) and performed variant calling
with
[GATK HaplotypeCaller](https://www.broadinstitute.org/gatk/guide/tooldocs/org_broadinstitute_gatk_tools_walkers_haplotypecaller_HaplotypeCaller.php)
(v3.3-0) and [FreeBayes](https://github.com/ekg/freebayes) (v0.9.21-7). We did
not
[perform realignment or base quality score recalibration (BQSR) prior to variant calling](http://bcb.io/2013/10/21/updated-comparison-of-variant-detection-methods-ensemble-freebayes-and-minimal-bam-preparation-pipelines/).
We filtered all calls with hard filters, as GATK variant quality score
recalibration (VQSR) intermittently failed to converge on these single sample
whole genome inputs. We aligned and called separately on build 37 (hg19/GRCh37)
and two build 38 (hg38/GRCh38) reference sets, with and without alternative
alleles. We performed validations against the truth sets using
[Real Time Genomics vcfeval](https://github.com/RealTimeGenomics/rtg-tools).

## Illumina Platinum Genomes

Illumina's Platinum Genome initiative has natively prepared truth sets for both
build 37 and 38. This makes interpretation of validation results more
straightforward since we only have two potential sources of error: incorrect
calls in the validation set and errors in the truth set. Illumina created their
build 38 truth set by mapping against
[38 without alternative alleles but with decoy sequence](https://groups.google.com/d/msg/genome-in-a-bottle/tDOcR0VRxcc/KPmifJlRAgAJ).
They called variants using 4 different approaches, performed pedigree checks,
then combined the individual calls. Below are the results of comparing variant
calls from bcbio against this truth set. The comparison measures sensitivity and
precision metrics for SNPs and indels:

- [False negative rate (FNR)](https://en.wikipedia.org/wiki/Sensitivity_and_specificity)
  -- A measure of the sensitivity of variant detection, calculated as 1 -
  sensitivity (so 0.5% FNR = 99.5% sensitivity). By having a natural zero point for
  plotting, this metric provides better resolution for numbers with high values where
  small differences matter. Lower values of FNR are better.

- [False discovery rate (FDR)](https://en.wikipedia.org/wiki/Sensitivity_and_specificity)
  -- Measures the precision of variant detection based on false positives. It's
  calculated as 1 - precision. Lower values have a smaller number
  of false positives compared to true positives.

<a href="http://i.imgur.com/phzZ09Y.png">
  <img src="http://i.imgur.com/phzZ09Y.png" width="700"
       alt="Illumina Platinum Genomes truth set">
</a>

hg38 and hg38-noalt (without alternative haplotypes) have improved detection
compared to hg19, with both FreeBayes and GATK HaplotypeCaller. For SNPs, the
full hg38 comparison has less false positives (FDR) compared to hg38-noalt,
demonstrating the advantage of alternative haplotypes for resolving mapping and
calling issues. For indels, we detect more total indels in build 38 at the cost
of decreased sensitivity and precision. This reflects tuning of current
algorithms for build 37, and offers the opportunity for better overall detection
on 38. Additionally, since the Platinum Genomes mapping does not use alternative
alleles, some of the discordant calls from build 38 may be due to incorrect
calls in the truth set.

## Genome in a Bottle reference with coordinate remapping

We also validated build 38 calls against the Genome in a Bottle NA12878 truth
set. Genome in a Bottle uses inputs from
[multiple sequencing technologies and callers](http://www.nature.com/nbt/journal/v32/n3/full/nbt.2835.html),
but is only currently available for build 37. To prepare it for this comparison
we converted the coordinates to 38 in two ways: using
[NCBI's remap](http://www.ncbi.nlm.nih.gov/genome/tools/remap) and
[CrossMap](http://crossmap.sourceforge.net/) with a
[UCSC chain file](http://hgdownload.cse.ucsc.edu/goldenPath/hg19/liftOver/).
This adds an additional layer into the comparison since we're now considering
three potential sources of errors in the evaluation:

-   Incorrect calls in the evaluation dataset
-   Errors in the truth set
-   Incorrect or missing variants created during coordinate conversion

This approach evaluates coordinate conversion methods at the cost of more
subtleties when assessing the concordant and discordant calls. Even with
potential coordinate conversion issues, the Genome in a Bottle truth set
shows good performance of mapping and calling on build 38.

- We see an improvement in total indels detected in build 38 for both coordinate
  conversion methods. This is due to locations where a single location in 37
  maps to multiple locations in 38. FreeBayes indel resolution is not as good as
  GATK HaplotypeCaller, unlike the results for the Platinum Genomes comparisons.
  This reflects some bias towards GATK heuristics in the Genome in a Bottle
  dataset, which uses HaplotypeCaller for variant resolution. A majority of the
  additional discordant FreeBayes SNPs and Indels have overlapping calls with
  the truth set but differ in the allele representation, indicating areas where
  FreeBayes can improve resolution of heterozygotes versus homozygotes.

- For SNP calling we have fewer concordant variants, due to a loss or
  mismapping of calls in difficult regions. CrossMap has fewer overall SNPs
  (concordant + discordant missing), indicating a loss of some SNPs during
  conversion. In contrast, NCBI remap converts more variants but also has a
  larger number that aren't called and show up as false negatives in the
  comparison. In both cases, these are possible areas to improve coordinate
  remapping resolution.

- There is a reduction in SNP false positives in hg38 compared to hg38-noalt,
  but not as dramatic as seen in the native Platinum Genomes truth set. There is
  value in the alternative alleles in this comparison, moderated by the
  challenges in coordinate remapping of variants in complex regions.

<a href="http://i.imgur.com/4XTIf2p.png">
  <img src="http://i.imgur.com/4XTIf2p.png" width="700"
       alt="Genome in a Bottle truth set">
</a>

## Conclusions

Both the native and coordinate converted validation sets inspire confidence that
we can call variants well on build 38. They also demonstrate improvements due to
better alignment with the alternative alleles, with improved indel detection
and removal of false positives SNPs.

Coordinate conversion of build 37 resources with CrossMap and Remap captures
the majority of the signal in the validations, with some loss in more difficult
regions. Continued work to cooordinate convert missing resources to 38 should
also provide additional information about edge cases where we should use more
caution in interpreting results.

# Scripts, chromosome naming and future work

All of the data and code used here are freely available to build off this work.
A
[GitHub repository contains the scripts used to convert build 37 to 38](https://github.com/hbc/giab_remap_38),
along with links to the prepared Genome in a Bottle truth sets and validation
outputs. Configuration files and input data for re-running the validations are
in
[the bcbio example pipeline documentation](https://bcbio-nextgen.readthedocs.org/en/latest/contents/testing.html#human-genome-build-38).
We welcome re-analyses and re-interpretation of these results.

For build 38, all of the resources in bcbio use the 'chr' prefixed naming scheme
(chr1, chr2, chr3...). In pre-release discussions about build 38 UCSC, Ensembl,
NCBI and other major providers agreed on this as the preferred nomenclature.
NCBI's build 38 analysis sets use it and
[documents the chromosome naming conventions](ftp://ftp.ncbi.nlm.nih.gov/genbank/genomes/Eukaryotes/vertebrates_mammals/Homo_sapiens/GRCh38/seqs_for_alignment_pipelines/README_ANALYSIS_SETS).
Unfortunately, some groups
[decided to stay with non-prefixed names](https://www.biostars.org/p/94826/#116487)
(1, 2, 3...). There is too much interesting biology I'd prefer to work on,
rather than spending time supporting two sets of resources that differ only in
the chromosome name. In bcbio we've decided not to perpetuate this dual naming
scheme for another genome release and will convert non-conforming naming over to
the 'chr' prefixed naming scheme.

Currently bcbio has validated SNP and indel calling for build 38. We plan to support
structural variant validations, using lifted over resources from Genome in a
Bottle and the
[ICGC-TCGA DREAM challenge data](https://www.synapse.org/#!Synapse:syn312572/wiki/).
We also plan to validate RNA-seq tools on build 38.

For small variant calling, we hope to continue to work with the community to
convert additional 37 only resources to 38. Supporting build 38 in
[GEMINI](http://gemini.readthedocs.org/en/latest/) is one of the last large
hurdles. We also plan to integrate tools like
[Erik Garrison's vg](https://github.com/ekg/vg) for mapping and variant calling
against variant graphs. Continuing to move to graph based methods will provide
us with a more reliable assessment of variation in sub-populations, and improved
variant calling in regions with multiple alternative alleles. Build 38 is a
great first step in moving towards a more accurate, graph-based, representation
of human heterogeneity.
