---
title: DOI workflow
author: Simon Goring
date: May 22, 2016
---

# DOI Workflow

<!-- MarkdownTOC -->

- Use Cases
    - Serial Assignment
    - Unique Assignment
- Outstanding Issues
    - DOI Metadata:
    - Landing Page
    - DOI Assignment
    - Updating Records

<!-- /MarkdownTOC -->

# Use Cases

Currently the Neotoma Paleoecological Database ([http://neotomadb.org]()) has no established system for minting DOIs for records within the database.  Given the database structure, discussed in detail [here](http://neotoma-manual.readthedocs.io/en/latest/)), there is no natural single table, but there is a data construct that mirrors (to some degree) the concept of a complete dataset, the existing Neotoma API `download` structure (*e.g.*, [http://api.neotomadb.org/v1/downloads/14196]()).  This object will be the atomic unit for DOI assignment and we will refer to it as a "dataset" in this document, although a second API service exists that refers to "datasets". The API "dataset" service excludes count or sample data for a site, and as such doesn't serve our needs for the assignment of DOIs.

Neotoma, in establishing a DOI service, has two main use cases.  Pre-existing records and records that will be provided to Neotoma as a set of datasets (either the inclusion of a new Constituent Database, or as the result of a data synthesis project) will require the bulk assignment records, we refer to this as "Serial Assignment". The second use case occurs when new records are uploaded individually through Tilia ([http://tiliait.com]()) or a data upload web service (in development), we will refer to these as "Unique Assignment".  For each of these two use cases the process is generally the same for the actual call to DataCite/EZID, but the wrapping within the workflow will differ.

## Serial Assignment

Serial assignment of DOIs occurs when we first assign DOIs to all Neotoma records, and when a new constituent database, or large sets of datasets are uploaded to Neotoma.  This process is (likely) triggered manually, or it could be applied to a set of unique dataset IDs.  This process could also work by simply polling Neotoma each day for `Datasets` without DOI assignments, but we want to be able to provide the DOI quickly when people submit their records.

The process is:

* Data are added to Neotoma (with empty dataset DOI field)
* The script run through each dataset with an unassigned DOI
* A landing page is created programmatically.
* The script calls out to DataCite/EZID & generates a DOI and assigns metadata
* The DOI returned from DataCite is attached to the `Datasets` table
* \[an email is sent to the Dataset PI with the dataset DOI & metadata, and to the relevant steward\]

## Unique Assignment

Unique assignment of a DOI occurs at data upload whether from Tilia, or directly into Neotoma through another portal.

The process is:

* Data are added to Neotoma (with empty dataset DOI field)
* A landing page is created programmatically.
* The script calls out to DataCite/EZID & generates a DOI and assigns metadata
* The DOI returned from DataCite is attached to the `Datasets` table
* Either:
  * The DOI is attached to the "Success" object and returned as part of the process
  * Or, the application polls Neotoma again with the new dataset ID and recieves the DOI.
* An email is sent to the Dataset PI and to the steward.

# Outstanding Issues

## DOI Metadata:

### SQL:

To fill in the metadata fields we need to generate a few seperate calls:

#### Manditory fields:

* **Identifier**:       `DOI`
* **Creator**:          `Contacts:ContactName` **NOTE**: This "The main researchers involved in producing the data, or the authors of the publication, in priority order".  I'm pulling the `ContactName` from the `DatasetPI`.  The problem is that `ContactID` is a foreign (or primary) key in 15 different tables.  I'm not 100% sure how exactly the DataCite/EZID API works for re-assigning DOI metadata and how it's handling the Python input.  I could build things as XML, but would prefer to use JSON as our native formatting.
* **Title**:            `CONCAT(Sites:SiteName, ' ', DatasetTypes:DatasetType, ' dataset')`

```SQL
/* SQL example */
SELECT CONCAT (SiteName, ' ', DataSetType, ' dataset') AS SiteName,
         'Title' AS titleType
FROM datasets AS ds
INNER JOIN collectionunits as cu
ON ds.CollectionUnitID = cu.CollectionUnitID
INNER JOIN sites AS sts
ON cu.SiteID = sts.SiteID
INNER JOIN datasettypes AS dst
ON ds.DatasetTypeID = dst.DatasetTypeID
WHERE DatasetID = 12;
```

* **Publisher**:        `"Neotoma Paleoecological Database"` (could be the Constituent Database)
* **Publication Year**: `Datasets:RecDateCreated`

The manditory fields can be generated in a single SQL call (as long as DatasetPI is pushed as the only `creator`).

```sql
SELECT CONCAT(SiteName, ' ', DatasetType, ' dataset') AS SiteName,
    'Title' AS titleType,
    ContactName AS creatorName,
    'ORCID' AS nameIdentifierScheme,
    'http://orcid.org' AS schemeURI,
    Address AS affiliation,
  YEAR(ds.RecDateCreated) as publicationyear
FROM (SELECT * FROM datasets WHERE DatasetID = " + sys.argv[1] + ") AS ds
INNER JOIN datasetpis ON ds.DatasetID = datasetpis.DatasetID
INNER JOIN collectionunits AS cu ON ds.CollectionUnitID = cu.CollectionUnitID
INNER JOIN sites AS sts ON cu.SiteID = sts.SiteID
INNER JOIN datasettypes AS dst ON ds.DatasetTypeID = dst.DatasetTypeID
INNER JOIN contacts ON datasetpis.ContactID = contacts.ContactID;
```

#### Optional Fields

##### Subject
This needs to get worked out a bit more explicitly.  There are a set of Library of Congress subjects we can use.

##### Contributor
I've generally worked this out.  There is a SQL command that I run through:

```mysql
/* A big UNION based on the dataset/Collection Unit ID first: */
SELECT
    ContactName AS creatorName,
    contributorType
FROM
    (
        SELECT
            ContactID,
            "Chronology" AS contributorType
        FROM
            /* pull from chronologies */
            (
                (
                    SELECT
                        d.CollectionUnitID
                    FROM
                        datasets AS d
                    WHERE
                        d.DatasetID = 1001
                ) AS sds
                INNER JOIN chronologies AS chron ON sds.CollectionUnitID = chron.CollectionUnitID
            )
        UNION ALL
            SELECT
                ContactID,
                "Collector" AS contributorType
            FROM
                /* pull from chronologies */
                (
                    (
                        SELECT
                            d.CollectionUnitID
                        FROM
                            datasets AS d
                        WHERE
                            d.DatasetID = 1001
                    ) AS sds
                    INNER JOIN collectors AS coll ON sds.CollectionUnitID = coll.CollectionUnitID
                )
            UNION ALL
                SELECT
                    ContactID,
                    "ContactPerson" AS contributorType
                FROM
                    /* pull from dataset PIs */
                    datasetpis
                WHERE
                    datasetpis.DatasetID = 1001
                UNION ALL
                    SELECT
                        ContactID,
                        "DataCurator" AS contributorType
                    FROM
                        /* pull from dataset submissions */
                        datasetsubmissions
                    WHERE
                        datasetsubmissions.DatasetID = 1001
                    UNION ALL
                        SELECT
                            ContactID,
                            "Author" AS contributorType
                        FROM
                            /* pull from publicaitons */
                            (
                                (
                                    SELECT
                                        d.PublicationID
                                    FROM
                                        datasetpublications AS d
                                    WHERE
                                        d.datasetID = 1001
                                ) AS sds
                                INNER JOIN publicationauthors AS paut ON sds.PublicationID = paut.PublicationID
                            )
                        UNION ALL
                            SELECT DISTINCT
                                ContactID,
                                "Analyst" AS contributorType
                            FROM
                                /* pull from sample analysts */
                                (
                                    (
                                        SELECT
                                            samp.SampleID
                                        FROM
                                            samples AS samp
                                        WHERE
                                            samp.datasetID = 1001
                                    ) AS sas
                                    INNER JOIN sampleanalysts AS sana ON sas.SampleID = sana.SampleID
                                )
    ) AS cids
INNER JOIN contacts ON cids.ContactID = contacts.ContactID
```

For dataset 1001 this give us:

| contributorName    | contributorType |
| ----------- | ----------- |
| Duvall, Mathieu L. | Researcher |
| Cwynar, Les C. | Collector |
| Cwynar, Les C. | ProjectLeader |
| Grimm, Eric Christopher | DataCurator |
| Spear, Ray W.  | Author |
| Cwynar, Les C. | Author |
| Cwynar, Les C. | Analyst |

This results in 

* **Date**: We can provide a set of dates:
    * Submission Date (`datasetsubmissions:SubmissionDate`) 
    * Record Created  (`datasetsubmissions:RecDateCreated`) 
    * Record Modified  (`datasetsubmissions:RecDateModified`)
    * Publication (there may be multiple here, each obtained by `publications:Year` through `dataset:Publications`)

This corresponds to the SQL call:

```SQL
SELECT ds.SubmissionDate, "Submitted" FROM datasetsubmissions AS ds \
WHERE ds.DatasetID = 1001 \
UNION ALL \
SELECT ds.RecDateCreated, "Created" FROM datasetsubmissions AS ds \
WHERE ds.DatasetID = 1001 \
UNION ALL \
SELECT ds.RecDateModified, "Updated" FROM datasetsubmissions AS ds \
WHERE ds.DatasetID = 1001;
```

**Returns**
| SubmissionDate      | dateType |
| ------------------- | -------- |
| 1998-07-05 00:00:00 | Submitted |
| 2007-06-30 00:00:00 | Submitted |
| 2013-09-30 14:02:43 | Created |
| 2014-10-25 00:31:04 | Updated |

Curiously, here we get multiple entries for each record.  Presumably this is a result of multiple submission between the NAPD and Neotoma.

* **Language**: `"English"`
* **ResourceType**
* **ResourceTypeGeneral**: "Dataset"
* **Size**: Here we need to obtain the size (in bytes) of the returned object.
* **Format**: a list: "JSON", "XML", "TLX"
* **Version**: 
* **Rights**:
* **Description (with type sub‐property)**:
* **GeoLocation (with point and box sub‐properties)**:
* **GeoLocationPlace**: 


## Landing Page

Since we are not going directly to the data itself we'd like to understand what exactly is required of a landing page for a dataset (or what is preferred).

## DOI Assignment

## Updating Records

In cases where a data set is updated Neotoma still directly modifies the record.  This will (or may) change 