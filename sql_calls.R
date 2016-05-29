# SQL queries:
default_call <- function(x) {
  paste0("SELECT CONCAT(SiteName, ' ', DatasetType, ' dataset') AS SiteName,
  'Title' AS titleType, ContactName AS creatorName, 'ORCID' AS nameIdentifierScheme, 
  'http://orcid.org' AS schemeURI, Address AS affiliation, YEAR(ds.RecDateCreated) as publicationyear 
  FROM (SELECT * FROM datasets WHERE DatasetID = ", x, ") AS ds INNER JOIN datasetpis ON ds.DatasetID = datasetpis.DatasetID
  INNER JOIN collectionunits AS cu ON ds.CollectionUnitID = cu.CollectionUnitID INNER JOIN sites AS sts ON cu.SiteID = sts.SiteID
  INNER JOIN datasettypes AS dst ON ds.DatasetTypeID = dst.DatasetTypeID INNER JOIN contacts ON datasetpis.ContactID = contacts.ContactID;")
}

contributor_call <- function(x) {
  paste0("SELECT ContactName AS creatorName, Address as affiliation, contributorType
FROM (SELECT ContactID, 'Researcher' AS contributorType
FROM ((SELECT d.CollectionUnitID FROM datasets AS d WHERE d.DatasetID = ", x, ") AS sds
INNER JOIN chronologies AS chron ON sds.CollectionUnitID = chron.CollectionUnitID)
UNION ALL SELECT ContactID, 'DataCollector' AS contributorType 
FROM ((SELECT d.CollectionUnitID FROM datasets AS d
WHERE d.DatasetID = ", x, ") AS sds INNER JOIN collectors AS coll ON sds.CollectionUnitID = coll.CollectionUnitID)
UNION ALL SELECT ContactID, 'ProjectLeader' AS contributorType
FROM datasetpis WHERE datasetpis.DatasetID = ", x, "
UNION ALL SELECT ContactID, 'DataCurator' AS contributorType
FROM datasetsubmissions WHERE datasetsubmissions.DatasetID = ", x, "
UNION ALL SELECT ContactID, 'Researcher' AS contributorType
FROM ((SELECT d.PublicationID FROM datasetpublications AS d
WHERE d.datasetID = ", x, ") AS sds
INNER JOIN publicationauthors AS paut ON sds.PublicationID = paut.PublicationID)
UNION ALL SELECT DISTINCT ContactID, 'DataCollector' AS contributorType
FROM ((SELECT samp.SampleID FROM samples AS samp
WHERE samp.datasetID = ", x, ") AS sas INNER JOIN sampleanalysts AS sana ON sas.SampleID = sana.SampleID)) AS cids
INNER JOIN contacts ON cids.ContactID = contacts.ContactID")
}

date_call <- function(x) {
  paste0("SELECT ds.SubmissionDate, 'Submitted' FROM datasetsubmissions AS ds 
              WHERE ds.DatasetID = ", x, " UNION ALL 
              SELECT ds.RecDateCreated, 'Created' FROM datasetsubmissions AS ds
              WHERE ds.DatasetID = ", x, " UNION
              SELECT ds.RecDateModified, 'Updated' FROM datasetsubmissions AS ds
              WHERE ds.DatasetID = ", x, ";")
}