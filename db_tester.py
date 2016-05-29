#!/usr/bin/env python

# Pushing DOI information to DataCite using Neotoma & the DataCite API:

__author__ = "Simon Goring"
__copyright__ = "Copyright 2016"
__credits__ = ["Simon Goring"]
__license__ = "MIT"
__version__ = "Expat License"
__maintainer__ = "Simon Goring"
__email__ = "simon.j.goring@gmail.com"
__status__ = "Development"

# Load the database.
# For each dataset in the database, create a unique DOI.
# Using the information we've established (maybe create a class for the input?)

import pymysql
import xml.etree.ElementTree as etree
import sys

def dict_to_xml(tag, d):
    '''
    Turn a simple dict of key/value pairs into XML
    '''
    elem = etree.Element(tag)
    for key, val in d.items():
        child = etree.Element(key)
        child.text = str(val)
        elem.append(child)
    return elem

# We expect the argument for `sys.argv` to be a number, the dataset ID:

# We connect to the database:
con = pymysql.connect(user='root', db = 'neotoma', password = 'c@mpf1re', host = 'localhost')

# Then this needs to execute for each dataset ID:

cur = con.cursor(pymysql.cursors.DictCursor)

top = etree.Element('top')

# Add the 'AlternateIdentifier':
#child = etree.SubElement(top, 'AlternateIdentifier')
#child.text(sys.argv[1])

print(sys.argv[1])

# Let's assign the creator stuff.
# This query returns a `dict`.
# creator = {'creatorName':,
#            'nameIdentifier':
#            ' nameIdentifierScheme':
#            'schemeURI':
#            'affiliation':}

# A couple quick things:
#  1. For the "Creator" we're missing information about people.  We don't have
#     any information about their ORCiD (something we could add) or a specific
#     affiliation.

cur.execute("SELECT ContactName AS creatorName, \
	                Notes AS nameIdentifier, \
	                'ORCID' AS nameIdentifierScheme, \
	                'http://orcid.org' AS schemeURI, \
	                Address AS affiliation \
	FROM contacts \
	WHERE ContactID = \
	(SELECT ContactID \
	FROM datasetpis \
	WHERE DatasetID =" + sys.argv[1] +");")

top.append(dict_to_xml("Creator", cur.fetchone()))

cur.close()
#  So, that's the creator field.

# Let's assign the Title fields:
cur = con.cursor(pymysql.cursors.DictCursor)

cur.execute("SELECT CONCAT (SiteName, ' ', DataSetType, ' dataset') AS Title, \
	                'Title' AS titleType \
	FROM datasets AS ds \
	INNER JOIN collectionunits as cu \
	ON ds.CollectionUnitID = cu.CollectionUnitID \
	INNER JOIN sites AS sts \
	ON cu.SiteID = sts.SiteID \
	INNER JOIN datasettypes AS dst \
	ON ds.DatasetTypeID = dst.DatasetTypeID \
	WHERE DatasetID = " + sys.argv[1] +";")

top.append(dict_to_xml("Title", cur.fetchone()))

print(etree.tostring(top))

cur.close()

con.close()