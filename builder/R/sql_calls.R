# SQL queries:
default_call <- function(x) {
  paste0("SELECT CONCAT(SiteName, ' ', DatasetType, ' dataset') AS SiteName,
         'Title' AS titleType, 
         ContactName AS creatorName, 
         'ORCID' AS nameIdentifierScheme, 
         'http://orcid.org' AS schemeURI, 
         Address AS affiliation, 
         YEAR(ds.RecDateCreated) as publicationyear 
         FROM (SELECT * FROM NDB.Datasets WHERE DatasetID = ", x, ") AS ds 
         LEFT JOIN NDB.DatasetPIs ON ds.DatasetID = datasetpis.DatasetID
         LEFT JOIN NDB.Contacts ON datasetpis.ContactID = contacts.ContactID
         INNER JOIN NDB.CollectionUnits AS cu ON ds.CollectionUnitID = cu.CollectionUnitID
         INNER JOIN NDB.Sites AS sts ON cu.SiteID = sts.SiteID
         INNER JOIN NDB.DatasetTypes AS dst ON ds.DatasetTypeID = dst.DatasetTypeID 
         ")
}

contributor_call <- function(x) {
  paste0("SELECT ContactName AS creatorName, Address as affiliation, contributorType
FROM (SELECT ContactID, 'Researcher' AS contributorType
FROM ((SELECT d.CollectionUnitID FROM NDB.Datasets AS d WHERE d.DatasetID = ", x, ") AS sds
INNER JOIN NDB.Chronologies AS chron ON sds.CollectionUnitID = chron.CollectionUnitID)
UNION ALL SELECT ContactID, 'DataCollector' AS contributorType 
FROM ((SELECT d.CollectionUnitID FROM NDB.datasets AS d
WHERE d.DatasetID = ", x, ") AS sds INNER JOIN NDB.Collectors AS coll ON sds.CollectionUnitID = coll.CollectionUnitID)
UNION ALL SELECT ContactID, 'ProjectLeader' AS contributorType
FROM NDB.DatasetPIs WHERE datasetpis.DatasetID = ", x, "
UNION ALL SELECT ContactID, 'DataCurator' AS contributorType
FROM NDB.DatasetSubmissions WHERE datasetsubmissions.DatasetID = ", x, "
UNION ALL SELECT ContactID, 'Researcher' AS contributorType
FROM ((SELECT d.PublicationID FROM NDB.DatasetPublications AS d
WHERE d.datasetID = ", x, ") AS sds
INNER JOIN NDB.PublicationAuthors AS paut ON sds.PublicationID = paut.PublicationID)
UNION ALL SELECT DISTINCT ContactID, 'DataCollector' AS contributorType
FROM ((SELECT samp.SampleID FROM NDB.samples AS samp
WHERE samp.datasetID = ", x, ") AS sas INNER JOIN NDB.SampleAnalysts AS sana ON sas.SampleID = sana.SampleID)) AS cids
INNER JOIN NDB.Contacts ON cids.ContactID = contacts.ContactID")
}

date_call <- function(x) {
  paste0("SELECT ds.SubmissionDate, 'Submitted' FROM NDB.DatasetSubmissions AS ds 
              WHERE ds.DatasetID = ", x, " UNION ALL 
              SELECT ds.RecDateCreated, 'Created' FROM NDB.DatasetSubmissions AS ds
              WHERE ds.DatasetID = ", x, " UNION
              SELECT ds.RecDateModified, 'Updated' FROM NDB.DatasetSubmissions AS ds
              WHERE ds.DatasetID = ", x, ";")
}

geoloc_call <- function(x) {
  paste0("Select CONCAT(LatitudeSouth, ' ', 
                        LongitudeWest, ' ',
                        LatitudeNorth, ' ', LongitudeEast)
  FROM NDB.Sites
  INNER JOIN
  (SELECT SiteID 
  FROM NDB.CollectionUnits
  INNER JOIN
  (SELECT datasets.CollectionUnitID FROM NDB.Datasets WHERE DatasetID = ", x, ") as ds
  ON collectionunits.CollectionUnitID = ds.CollectionUnitID) as scd 
  ON sites.SiteID = scd.SiteID")
}

doi_call <- function(x) {
  paste0("SELECT DOI
  FROM NDB.Publications
  INNER JOIN (SELECT publicationID FROM NDB.DatasetPublications WHERE datasetID = ", x, ") as dpub 
  ON publications.publicationID = dpub.publicationID")
}

pub_call <- function(x) {
  paste0("SELECT *
         FROM NDB.Publications
         INNER JOIN (SELECT publicationID FROM NDB.DatasetPublications WHERE datasetID = ", x, ") as dpub 
         ON publications.publicationID = dpub.publicationID")
}

constdb_call <- function(x) {
  paste0("Select DatabaseName 
FROM NDB.ConstituentDatabases
         INNER JOIN (SELECT DatabaseID FROM NDB.DatasetDatabases WHERE DatasetID = ", x, ") as dsdb 
         ON dsdb.DatabaseID = constituentdatabases.DatabaseID")
}

sharedSite_call <- function(x) {
  paste0("SELECT CONCAT(SiteName, ' ', DatasetType, ' dataset') as Dataset, DatasetType, DatasetID FROM NDB.DatasetTypes
INNER JOIN (SELECT SiteName, DatasetID, DatasetTypeID from NDB.Sites
         INNER JOIN
         (SELECT DatasetID, jssi.CollectionUnitID, SiteID, DatasetTypeID FROM NDB.Datasets
         INNER JOIN (SELECT * FROM NDB.CollectionUnits 
         WHERE collectionunits.SiteID = 
         (SELECT SiteID FROM NDB.CollectionUnits
         INNER JOIN (SELECT collectionunits.CollectionUnitID 
         FROM NDB.CollectionUnits
         INNER JOIN (SELECT * FROM NDB.Datasets where DatasetID = ", x, ") as ds
         ON ds.CollectionUnitID = collectionunits.CollectionUnitID) as clu
         ON clu.CollectionUnitID = collectionunits.CollectionUnitID)) as jssi
         ON jssi.CollectionUnitID = datasets.CollectionUnitID) AS bigjoin
         ON sites.SiteID = bigjoin.SiteID) AS SiteDSType
         ON datasettypes.DatasetTypeID = SiteDSType.DatasetTypeID")
}

sitedesc_call <- function(x) {
  paste0("SELECT SiteDescription FROM NDB.Sites
INNER JOIN (SELECT *
         FROM NDB.CollectionUnits
         INNER JOIN (SELECT CollectionUnitID as cuid FROM NDB.Datasets where DatasetID = ", x, ") as ds
         ON ds.cuid = collectionunits.CollectionUnitID) as cu
         ON cu.SiteID = sites.SiteID")
}

agerange_call <- function(x){
  paste0("select smallage.AgeBoundYounger, smallage.AgeBoundOlder, agetypes.AgeType FROM NDB.AgeTypes
INNER JOIN
         (SELECT AgeBoundYounger, AgeBoundOlder, AgeTypeID FROM NDB.Chronologies
         INNER JOIN (SELECT CollectionUnitID as cuid FROM NDB.Datasets where DatasetID = ", x, ") as ds
         ON ds.cuid = chronologies.CollectionUnitID WHERE chronologies.IsDefault = 1) as smallage
         ON smallage.AgeTypeID = agetypes.AgeTypeID")
}