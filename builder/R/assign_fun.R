assign_doi <- function(ds_id, post = TRUE) {

  library(RODBC, quietly = TRUE, verbose = FALSE)
  library(httr, quietly = TRUE, verbose = FALSE)
  library(XML, quietly = TRUE, verbose = FALSE)

  doi_sens <- scan('..//doi_sens.txt', what = "character")

  con <- odbcDriverConnect(doi_sens[1])

  source('R//sql_calls.R')

  schema <- XML::xmlSchemaParse('..//data//metadata.xsd')

  # Generating the new XML framework and associated namespaces:
  doc <- XML::newXMLDoc()

  root <- XML::newXMLNode('resource',
                          namespaceDefinitions = c("http://datacite.org/schema/kernel-3",
                                                   "xsi" = "http://www.w3.org/2001/XMLSchema-instance"),
                          attrs = c("xsi:schemaLocation" = "http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"),
                          doc = doc)

  default <- sqlQuery(con, query = default_call(ds_id), as.is = TRUE)

  if (nrow(default) == 0) {
    # There's an error
    message("There is no dataset with this ID.")

    odbcClose(con)

    return(NULL)

  }

  # Clean the affiliation:
  default$affiliation <- gsub('\r\n', ', ', default$affiliation)

  # This is the empty shoulder for assigning DOIs:
  XML::newXMLNode("identifier", '10.21233/N3',
                  attrs = c('identifierType' = 'DOI'),
                  parent = root)

  # This creator stuff is just done one at a time. . .
  XML::newXMLNode("creators", parent = root)

  lapply(1:nrow(default),
         function(x) {
           XML::addChildren(root[["creators"]],
                            XML::newXMLNode("creator",
                      .children = list(XML::newXMLNode("creatorName",
                                                  default$creatorName[x]),
                                       XML::newXMLNode("affiliation",
                                                  default$affiliation[x]))))
          })

  #' Add Titles:
  XML::newXMLNode("titles", parent = root)
  XML::newXMLNode("title",
                  default$SiteName[1],
                  attrs = c("xml:lang" = "en-us"),
                  parent = root[["titles"]])

  #' Add publisher information:
  XML::newXMLNode("publisher", "Neotoma Paleoecological Database", parent = root)

  #' Add publication year:
  XML::newXMLNode("publicationYear", format(Sys.Date(), "%Y"), parent = root)

  #' Add dataset "Subject" index:
  XML::newXMLNode("subjects",
                  XML::newXMLNode("subject",
                                  "Paleoecology",
                                  attrs = c("subjectScheme" = "Library of Congress",
                                            "schemeURI" = "http://id.loc.gov/authorities/subjects")),
                  parent = root)

  #' Get & add contributor information
  contacts <-sqlQuery(con, query = contributor_call(ds_id), as.is=TRUE)
  contacts <- contacts[!duplicated(contacts), ]

  contacts$affiliation <- gsub('\r\n', ', ', contacts$affiliation)

  XML::newXMLNode("contributors", parent = root)

  lapply(1:nrow(contacts),
         function(x) {
           newXMLNode("contributor",
                      attrs = c("contributorType" = contacts$contributorType[x]),
                      .children = list(XML::newXMLNode("contributorName",
                                                  contacts$creatorName[x])),
                      parent = root[["contributors"]])
           })

  # Adding the dates in one at a time, we use the lapply to insert them
  # into the `dates` node.
  dates   <-sqlQuery(con, query = date_call(ds_id), as.is=TRUE)

  XML::newXMLNode("dates", parent = root)
  lapply(1:nrow(dates),
         function(x) {
           XML::newXMLNode("date",
                      format(as.Date(dates[1,1]), "%Y-%m-%d"),
                             attrs = c("dateType" = dates[x,2]),
                      parent = root[["dates"]])
           } )


  #' Language information.  We assume english at this point.
  XML::newXMLNode("language", "English", parent = root)

  #' Add in the resource type:
  XML::newXMLNode("resourceType", "Dataset/Paleoecological Sample Data",
                 attrs = c("resourceTypeGeneral" = "Dataset"),
                 parent = root)

  XML::newXMLNode("relatedIdentifiers", parent = root)

  #' Link to the JSON:
  XML::newXMLNode("relatedIdentifier",
                  paste0("api.neotomadb.org/v1/downloads/", ds_id),
                  attrs = list(relationType = "IsMetadataFor",
                               relatedIdentifierType = "URL",
                               relatedMetadataScheme = "json"),
                  parent = root[["relatedIdentifiers"]])
  XML::newXMLNode("relatedIdentifier",
                  paste0("data.neotomadb.org/datasets/", ds_id, "/index.html"),
                  attrs = list(relationType = "IsMetadataFor",
                               relatedIdentifierType = "URL",
                               relatedMetadataScheme = "json"),
                  parent = root[["relatedIdentifiers"]])
  # Add DOI tags for the publications as related identifiers:
  dois <-sqlQuery(con, query = doi_call(ds_id), as.is=TRUE)

  if (length(dois) == 0) {
    # There's no current DOI
  } else {
    lapply(unlist(dois)[!is.na(unlist(dois))], function(x){
      XML::newXMLNode("relatedIdentifier", paste0("doi:", x),
                      attrs = list(relationType = "IsDocumentedBy",
                                   relatedIdentifierType = "DOI"),
                      parent = root[["relatedIdentifiers"]])
    })
  }

  # Number 13: size
  size <- as.numeric(object.size(httr::GET(paste0("api.neotomadb.org/v1/downloads/", ds_id))))
  XML::newXMLNode("sizes",
                  XML::newXMLNode("size", paste0(ceiling(size/1000), " KB")),
                  parent = root)

  # Number 14 (Adding Formats)
  XML::newXMLNode("formats",
                  parent = root)
  XML::newXMLNode("format",
                  "XML",
                  parent = root[["formats"]])

  XML::newXMLNode("format",
                  "TLX",
                  parent = root[["formats"]])
  XML::newXMLNode("format",
                  "JSON",
                  parent = root[["formats"]])

  # Description
  newXMLNode("descriptions", parent  = root)
  newXMLNode("description",
             paste0("Raw data for the ",
                    default$SiteName,
                    " obtained from the Neotoma Paleoecological Database."),
             parent = root[["descriptions"]],
             attrs = list("descriptionType" = "Abstract",
                          "xml:lang" = "EN"))

  # Number 16
  XML::addChildren(XML::newXMLNode("rightsList", parent = root),
                   children = XML::newXMLNode("rights", "CC-BY4",
                   attrs = c("rightsURI" = "http://creativecommons.org/licenses/by/4.0/deed.en_US")))

  loc <-sqlQuery(con, query = geoloc_call(ds_id), as.is=TRUE)

  XML::newXMLNode("geoLocations", parent = root)
  XML::newXMLNode("geoLocation",
                  XML::newXMLNode("geoLocationBox", loc, parent = root),
                  parent = root[["geoLocations"]])

  schema_test <- XML::xmlSchemaValidate('../data/metadata.xsd', doc)

  if (!schema_test$status == 0) {

    # There's an error
    message("There was a validation error for this dataset.")

    odbcClose(con)

    return(schema_test)

  } else {

    urlbase = 'https://ezid.cdlib.org/'

    XML::saveXML(doc = doc,
                 file = paste0(doi_sens[5], ds_id, "/", ds_id, '_output.xml'),
                 prefix = '<?xml version="1.0" encoding="UTF-8"?>')

  }

  if (post == TRUE) {

    # We need to clean up the XML formatting, removing hard returns and changing quotes:
    parse_doc <- gsub('\\n', '', paste0('datacite: ',
                                        XML::saveXML(xmlParse(paste0(doi_sens[5],
                                                                     ds_id, '/',
                                                                     ds_id, '_output.xml')))))

    parse_doc <- gsub('\\"', "'", parse_doc)

    body <- paste0('_target: http://data.neotomadb.org/datasets/',ds_id, '\n',parse_doc)

    r = httr::POST(url = paste0(urlbase, 'shoulder/doi:10.21233/N3'),
                   httr::authenticate(user = doi_sens[3], password = doi_sens[4]),
                   httr::add_headers(c('Content-Type' = 'text/plain; charset=UTF-8',
                                       'Accept' = 'text/plain')),
                   body = body,
                   format = 'xml')

    out_doi <- substr(content(r),
                      regexpr("doi:", content(r)),
                      regexpr("\\s\\|", content(r)) - 1)

    new_doc <- xmlParse(paste0(doi_sens[5],
                     ds_id, '/',
                     ds_id, '_output.xml'), useInternal = TRUE)

    top <- xmlRoot(new_doc)
    xmlValue(top[[1]]) <-  regexpr("doi:", content(r))

    XML::saveXML(doc = new_doc,
                 file = paste0(doi_sens[5], ds_id, "/", ds_id, '_output.xml'),
                 prefix = '<?xml version="1.0" encoding="UTF-8"?>')

  } else {

    out_doi <- NA

  }

  odbcClose(con)

  list(doc, out_doi)
}
