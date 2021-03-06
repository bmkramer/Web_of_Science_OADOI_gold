# Web_of_Science_OADOI_gold - R script

[![DOI](https://zenodo.org/badge/115628623.svg)](https://zenodo.org/badge/latestdoi/115628623)

Using the [OADOI API (v2)](https://oadoi.org/api) to get information on online availability (gold, hybrid, bronze and green Open Access)  of sets of academic articles retrieved from Web of Science. 

## Rationale
In December 2017, [Web of Science](http://info.clarivate.com/openaccess) started including information on Open Access (OA) availability of publications using article-level information from [OADOI](https://oadoi.org/). Previously, information on OA availability on publications in Web of Science was based on journal level, only including gold Open Access journals indexed in DOAJ. 

Web of Science currently labels all articles as gold OA that are detected as freely available from the publisher. No distinction is made between articles in gold open access journals, hybrid journal or subscription journals that make (some) articles freely available, but without a license for re-use (read-only). Both for effective filtering and for monitoring OA developments at various levels (i.e. institutional, field, country) such distinctions would be very useful. 

This script uses detailed information available from the OADOI API to provide a breakdown of sets of articles labeled as 'gold OA' in Web of Science. The following categories are distinguished (description taken from [Piwowar at al., 2017]( https://doi.org/10.7287/peerj.preprints.3119v1))

 - **Gold**: Published in an open-access journal (as defined by the DOAJ)
 - **Hybrid**: Free under an open license in a toll-access journal
 - **Bronze**: Free to read on the publisher page, but without a license

## Input / output
This script uses as input a set of export files with full records from Web of Science, in Tab-delimited (Win, UTF-8) format.The files should be placed in a folder named 'WoS_export' in the working directory (or elsewhere if adapted in the script). In the script, variables can be declared to define the dataset (entity of analysis (e.g. name of institution), year, type of OA), these will be used to name the output files. 

NB1. Only 500 records can be exported from Web of Science at a time, but since this script handles a series of export files, larger datasets can be analysed.

NB2 Many thanks to Alberto Martín-Martín ([@alberto-martin](https://github.com/alberto-martin)) and Emilio Delgado López-Cózar from [EC3](http://ec3.ugr.es) for their R-script for [reading Web of Science into R](https://github.com/alberto-martin/read.wos.R/blob/master/report.Rmd), that I re-used here. 

The script has three separate outputs:
- a csv-file with a list of DOIs from the Web of Science export files
- a csv-file with [information from the OADOI API (v2)](https://oadoi.org/api/v2) for each of these DOIs:
  - DOI
  - data_standard - method for hybrid detection (1 or 2; 2 is more sensitive)
  - is_oa - whether an OA-version of the article was found
  - host_type - publisher (for gold OA) or repository (for green OA)
  - license - (NA if no license available)
  - journal_is_oa - whether the journal is included in DOAJ
  - URL - URL where the OA-version of the article can be found
 - printed summary listing numbers and percentages of articles identified as green, gold, hybrid and bronze.
 
 ![example WoS OADOI gold output](/WoS_OADOI_gold_output_example.jpg)

## A word about green OA
Web of Science only includes information about green OA availability when either the accepted version (manuscript after peer review, but without publisher formatting) or the published version (with publisher formatting) can be retrieved from a repository. Submitted versions (author manuscript before peer review) are not included, even though this information is available from the OADOI API.

In addition, when multiple OA-versions of an article are available, OADOI prioritizes publisher-hosted content(i.e. gold, hybrid or bronze), then versions closer to the version of record (i.e. for green OA, published version over accepted version over submitted version). Web of Science only includes the 'best' OA location as determined by this algorithm. 

Since this script is primarily intended to break down the 'gold OA' category in Web of Science (into gold, hybrid and bronze OA), no further breakdown is provided for green OA. 


## Example 

An example (including data) of the use of this script to analyze levels of OA for Dutch universities' output in 2016 (articles & reviews only) can be found on Zenodo: https://doi.org/10.5281/zenodo.1133759

 ![NL universities OA levels 2016 output](/NL%20Universities%202016%20green-gold-hybrid-bronze%20OA%20-%20levels.png)
 
## The script 
[WOS_gold_DOI_queries_OADOI_API_v2.R](/WOS_gold_DOI_queries_OADOI_API_v2.R)

update 20180122: added generic version of script that takes a DOI-list as input

[generic_DOI_queries_OADOI_API_v2.R](/generic_DOI_queries_OADOI_API_v2.R)




