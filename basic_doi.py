import requests
from requests.auth import HTTPBasicAuth
import re
import pymysql
# import sys

def escape (s):
  # Helps reformat the dictionary into a text string:
  return re.sub("[%:\r\n]", lambda c: "%%%02X" % ord(c.group(0)), s)

urlbase = 'https://ezid.cdlib.org/'

# Check that the service is working:
r = requests.get(urlbase + 'status')
print(r.text)

# I want to pull the information from the DB:
con = pymysql.connect(user='root', db = 'neotoma', password = 'c@mpf1re', host = 'localhost')

# Then this needs to execute for each dataset ID:

cur = con.cursor(pymysql.cursors.DictCursor)

required_query = "SELECT CONCAT(SiteName, ' ', DatasetType, ' dataset') AS SiteName, \
    'Title' AS titleType, \
    ContactName AS creatorName, \
    'ORCID' AS nameIdentifierScheme, \
    'http://orcid.org' AS schemeURI, \
    Address AS affiliation, \
  YEAR(ds.RecDateCreated) as publicationyear           \
FROM (SELECT * FROM datasets WHERE DatasetID = 1001) AS ds \
INNER JOIN datasetpis ON ds.DatasetID = datasetpis.DatasetID \
INNER JOIN collectionunits AS cu ON ds.CollectionUnitID = cu.CollectionUnitID \
INNER JOIN sites AS sts ON cu.SiteID = sts.SiteID \
INNER JOIN datasettypes AS dst ON ds.DatasetTypeID = dst.DatasetTypeID \
INNER JOIN contacts ON datasetpis.ContactID = contacts.ContactID;"

contact_query = "SELECT ContactName AS contributorName, contributorType \
FROM (SELECT ContactID, 'Researcher' AS contributorType \
    FROM \
    ((SELECT d.CollectionUnitID FROM datasets AS d WHERE d.DatasetID = 1001) AS sds \
    INNER JOIN chronologies AS chron ON sds.CollectionUnitID = chron.CollectionUnitID) \
UNION ALL \
    SELECT ContactID, 'Collector' AS contributorType FROM \
    ((SELECT d.CollectionUnitID FROM datasets AS d \
    WHERE d.DatasetID = 1001) AS sds \
    INNER JOIN collectors AS coll ON sds.CollectionUnitID = coll.CollectionUnitID) \
UNION ALL \
    SELECT ContactID, 'ProjectLeader' AS contributorType \
    FROM  \
    datasetpis WHERE datasetpis.DatasetID = 1001 \
UNION ALL \
    SELECT ContactID, 'DataCurator' AS contributorType \
    FROM  \
    datasetsubmissions WHERE datasetsubmissions.DatasetID = 1001 \
UNION ALL \
  SELECT ContactID, 'Author' AS contributorType \
  FROM  \
  ((SELECT d.PublicationID FROM datasetpublications AS d WHERE d.datasetID = 1001) AS sds \
  INNER JOIN publicationauthors AS paut ON sds.PublicationID = paut.PublicationID) \
UNION ALL \
  SELECT DISTINCT ContactID, 'Analyst' AS contributorType \
  FROM \
  ((SELECT samp.SampleID FROM samples AS samp WHERE samp.datasetID = 1001) AS sas \
  INNER JOIN sampleanalysts AS sana ON sas.SampleID = sana.SampleID)) AS cids \
  INNER JOIN contacts ON cids.ContactID = contacts.ContactID;"

date_query = "SELECT ds.SubmissionDate as 'Date', 'Submitted' as 'dateType' FROM datasetsubmissions AS ds \
WHERE ds.DatasetID = 1001 \
UNION ALL \
SELECT ds.RecDateCreated, 'Created' FROM datasetsubmissions AS ds \
WHERE ds.DatasetID = 1001 \
UNION ALL \
SELECT ds.RecDateModified, 'Updated' FROM datasetsubmissions AS ds \
WHERE ds.DatasetID = 1001;"

cur.execute(required_query)
meta_one = cur.fetchone()

cur.execute(contact_query)
meta_contact = cur.fetchall()

cur.execute(date_query)
meta_date = cur.fetchall()
for date in meta_date:
  date.get('SubmissionDate') = date.get('SubmissionDate').strftime('%Y-%m-%d')
  

# Create a basic DOI:
#  All of these must be strings.
metadata = {'datacite.creator':  meta_one.get("creatorName"),
            'datacite.title': {'datacite.title':     meta_one.get("SiteName"),
                               'datacite.titleType': meta_one.get("titleType")},
           'datacite.publisher': 'Neotoma Paleoecological Database',
           'datacite.publicationyear': str(meta_one.get("publicationyear")),
           'datacite.resourcetype': 'Dataset',
           'datacite.Contributor': meta_contact
           }

# We add the encoding here, but I think it's not neccessary.
anvl = "\n".join("%s: %s" % (escape(name), escape(value)) for name,
           value in metadata.items()).encode("utf-8")

print(anvl.decode("utf-8"))

# Post a request for a very basic DOI:

r = requests.post(urlbase + 'shoulder/doi:10.5072/FK2', 
	              auth = HTTPBasicAuth('apitest', 'apitest'),
               headers = {'Content-Type':'text/plain; charset=UTF-8'},
	              data = anvl.decode("utf-8"))

print(r.text)
print(type(r.text))

# This then gets the assigned DOI:
tester_doi = r.text[13:(r.text.index('|') - 1)]

print(tester_doi)
