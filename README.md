[![lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)](https://www.tidyverse.org/lifecycle/#stable)



# AssignDOIs

This repository serves two purposes:  It is the code that will run to assign DOIs to Neotoma datasets through DataCite (mostly in the `R/builder` folder) and it is also the paper that describes this process.

## Contributors
* [Simon Goring](http://github.com/SimonGoring)

This is currently a project under development.  All participants are expected to follow the [code of conduct](https://github.com/SimonGoring/AssignDOIs/blob/master/code_of_conduct.md) for this project.

## What is Included

The project includes all code an markdown neccessary to replicate the process undertaken to assign DOIs to Neotoma datasets, as well as a descriptive Methods article (in development) that explains the motivation and process for assigning DOIs.

The key components of this repository are:

### DOI Paper

* *`DOI_Assignment.Rmd`* and associated `html` and `md` files.
* *`DOI_publications.bib`* BibTeX formatted bibliography, for use in the `Rmd` file.
* *`site_page_output.png`* An image for the paper.

As with other projects, this project assumes an open authorship model, provided contributors follow the code of conduct.

### Builder

* *./builder*
  * *static_page.Rmd* The framework for the landing page generated for individual datasets.
  * *outputs.csv* this is the storage file for all generated DOIs to link them directly to the Neotoma, along with a date of generation, which would allow us to test against the database & modification date.
  * *html* and *png* files, associated with the building of the `Rmd` file.
  * *./builder/R* A set of R script files to manage database connection, processing & SQL queries required to generate the landing page.
  * *./builder/index_files* Files for the JavaScript libraries used to generate the landing pages.
  * *./data* DataCite schema, or other data files used in generating the static files.
  
These files are used to generate the static landing page for the individual datasets.  The key script is in `./builder/R/processing_code.R`. This code takes as input a dataset number and runs `rmarkdown::render()` on the `static_page.Rmd` file, passing in the dataset number as an argument through the `globalenv()`.

## Future Directions

Continued improvement of the landing page. I (Simon Goring) continue to develop embedding JSON-LD RDFa code using a [schema.org]() framework at the bottom of the `static_page.Rmd` file.  Any suggestions or improvements are welcome here.