import requests
from requests.auth import HTTPBasicAuth
import json
import re

# To:
# 0. Pull in the Publications Table
# 1. Read in the publications CSV
# 2. Check for publications with a valid DOI
# 3. Go to CrossRef and get the publication information/

# Load the SQL database:
import pymysql

# con = pymysql.connect(user='root', db = 'neotoma', password = 'c@mpf1re', host = 'localhost')

# # Then load the whole publications table:

# cur = con.cursor(pymysql.cursors.DictCursor)

# cur.execute("SELECT * FROM Publications")

# pub_dict = cur.fetchall()

#  Now read in the google spreadsheet:
#  Instructions come from:
#    http://gspread.readthedocs.org/en/latest/oauth2.html
import gspread
from oauth2client.service_account import ServiceAccountCredentials

# Authorize:
scope = ['https://spreadsheets.google.com/feeds']
credentials = ServiceAccountCredentials.from_json_keyfile_name('Neotoma-DOI-7a06a3f69d1d.json', scope)

gc = gspread.authorize(credentials)

# You need tomake sure that the document is shared with the client, in this case:
#  "neotoma@neotoma-doi.iam.gserviceaccount.com"
sht1 = gc.open_by_key('10_u41Q3Vd9cvyrBS9RiL9g5tCaI3Cimpry7k1iwd-ug').get_worksheet(0)

# We want all the values in the worksheet.  The critical columns are:
#  Column 2 - the "yes/no" for a match to CrossRef
#  Column 4 - the publicationID
#  Column 8 - The DOI

doi_test = sht1.get_all_values()

#  Given a good DOI, get the metadata:
urlbase = 'http://api.crossref.org/works/doi/'