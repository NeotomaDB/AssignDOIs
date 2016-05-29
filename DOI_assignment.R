## ---- echo=FALSE, message = FALSE, warnings=FALSE------------------------
library(RMySQL, quietly = TRUE, verbose = FALSE)
library(httr, quietly = TRUE, verbose = FALSE)
library(XML, quietly = TRUE, verbose = FALSE)

source('sql_calls.R')

con <- dbConnect(MySQL(),
                 user = 'root', 
                 dbname = 'neotoma', 
                 password = 'c@mpf1re', 
                 host = 'localhost')

datacite <- 'https://ezid.cdlib.org/'

schema <- xmlSchemaParse('data/metadata.xsd')


## ---- results='hide'-----------------------------------------------------
# Building the XML document:

dataset <- 1001

doc <- newXMLDoc()

root <- newXMLNode('resource', 
                    namespaceDefinitions = c("http://datacite.org/schema/kernel-3",
                             "xsi" = "http://www.w3.org/2001/XMLSchema-instance"),
                    attrs = c("xsi:schemaLocation" = "http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"), doc = doc)


## ---- results = 'hide', message = FALSE, warning = FALSE-----------------
default <- dbGetQuery(con, statement = default_call(dataset))

# Clean the affiliation:
default$affiliation <- gsub('\r\n', ', ', default$affiliation)

# This is the empty shoulder for assigning DOIs:
newXMLNode("indentifier", '10.5072/FK2', 
           attrs = c('identifierType' = 'DOI'), parent = root)

# This creator stuff is just done one at a time. . . 

newXMLNode("creators", parent = root)

lapply(1:nrow(default),
       function(x) {
         addChildren(root[["creators"]], newXMLNode("creator",
                    .children = list(newXMLNode("creatorName",
                                                default$creatorName[x]),
                                     newXMLNode("affiliation",
                                                default$affiliation[x]))))
        })

# Now on to '3':
newXMLNode("titles", parent = root)
newXMLNode("title", 
           default$SiteName[1],
           attrs = c("titleType" = "Title", "xml:lang" = "en-us"),
           parent = root[["titles"]])

# Number 4:
newXMLNode("publisher", "Neotoma Paleoecological Database", parent = root)

# Number 5:
newXMLNode("publicationYear", format(Sys.Date(), "%Y"), parent = root)

## ----results='as-is', echo=FALSE-----------------------------------------
contacts <- dbGetQuery(con, statement = contributor_call(dataset))

contacts$affiliation <- gsub('\r\n', ', ', contacts$affiliation)
knitr::kable(contacts)

## ---- results='hide'-----------------------------------------------------

# The contributors come from the DB call.  This duplicates 
newXMLNode("contributors", parent = root)
lapply(1:nrow(contacts), 
       function(x) { 
         newXMLNode("contributor", 
                    attrs = c("contributorType" = contacts$contributorType[x]),
                    .children = list(newXMLNode("contributorName", 
                                                contacts$creatorName[x])), parent = root[["contributors"]])
         })

## ----results='as-is', echo = FALSE---------------------------------------
dates   <- dbGetQuery(con, statement = date_call(dataset))
knitr::kable(dates)

## ---- results='hide'-----------------------------------------------------
# Adding the dates in one at a time, we use the lapply to insert them
# into the `dates` node.
newXMLNode("dates", parent = root)
lapply(1:nrow(dates), 
       function(x) { 
         newXMLNode("date", 
                    format(as.Date(dates[1,1]), "%Y-%m-%d"), 
                           attrs = c("dateType" = dates[x,2]), 
                    parent = root[["dates"]]) 
         } )


## ---- echo = TRUE, results='hide'----------------------------------------
# Number 9:
newXMLNode("language", "English", parent = root)

# Number 10:
newXMLNode("resourceType", "Dataset/Paleoecological Sample Data", 
           attrs = c("resourceTypeGeneral" = "Dataset"), parent = root)


## ---- results='hide'-----------------------------------------------------
# Number 14:
newXMLNode("formats", parent = root)
newXMLNode("format", "XML", parent = root[["formats"]])
newXMLNode("format", "TLX", parent = root[["formats"]])
newXMLNode("format", "JSON", parent = root[["formats"]])

## ---- results='hide'-----------------------------------------------------
# Number 16

addChildren(newXMLNode("rightsList", parent = root),
           children = newXMLNode("rights", "CC-BY4", 
           attrs = c("rightsURI" = "http://creativecommons.org/licenses/by/4.0/deed.en_US")))

saveXML(doc = doc, 
        file = paste0('data/datasets/', dataset, '_output.xml'),
        prefix = '<?xml version="1.0" encoding="UTF-8"?>')

## ------------------------------------------------------------------------
xmlSchemaValidate('data/metadata.xsd', doc)

## ------------------------------------------------------------------------

urlbase = 'https://ezid.cdlib.org/'

parse_doc <- gsub('\\n', '', paste0('datacite: ',
                         saveXML(xmlParse(paste0('data/datasets/', 
                                                 dataset, '_output.xml')))))
parse_doc <- gsub('\\"', "'", parse_doc)


## ------------------------------------------------------------------------

r = POST(url = paste0(urlbase, 'shoulder/doi:10.5072/FK2'), 
	       authenticate(user = 'apitest', password = 'apitest'),
         add_headers(c('Content-Type' = 'text/plain; charset=UTF-8',
                       'Accept' = 'text/plain')),
	       body = parse_doc,
	                   format = 'xml')

content(r)

out_doi <- substr(content(r), 
                  regexpr("doi:", content(r)), 
                  regexpr("\\s\\|", content(r)) - 1)

content(r)

## ----eval=FALSE----------------------------------------------------------
## r = POST(url = paste0(urlbase, paste0('identifier/', out_doi),
## 	       authenticate(user = 'apitest', password = 'apitest'),
##          add_headers(c('Content-Type' = 'text/plain; charset=UTF-8',
##                        'Accept' = 'text/plain')),
## 	       body = paste0('datacite: ',paste(readLines(paste0('data/datasets/',
##                 dataset,  '_output.xml')), collapse = " ")),
## 	                   format = 'xml')

