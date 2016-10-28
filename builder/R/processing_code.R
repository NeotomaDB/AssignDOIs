# Here's how things work:
# Look in the directory for all folders created with a dataset ID
# Look in the `output` file where datasets are output.
# 

library(tidyr, quietly = TRUE, verbose = FALSE)
library(dplyr, quietly = TRUE, verbose = FALSE)
library(RODBC, quietly = TRUE, verbose = FALSE)
library(lubridate, quietly = TRUE, verbose = FALSE)

end_point  <- 'C:\\vdirs\\doi\\datasets'
good_files <- read.csv('outputs.csv', header = TRUE)

build_ages <- "SELECT ds.DatasetID, ds.RecDateModified as dataset, 
               dspi.RecDateModified as dsPI, 
               contacts.RecDateModified as contact, 
               cu.RecDateModified as collUnit, 
               sts.RecDateModified as sites,
               dst.RecDateModified as datatype, 
               dss.RecDateModified as ds_sub, 
               dsp.RecDateModified as datapub, 
               chr.RecDateModified as chron FROM NDB.Datasets as ds  LEFT JOIN 
               NDB.DatasetPIs as dspi ON ds.DatasetID = dspi.DatasetID
               LEFT JOIN NDB.Contacts ON dspi.ContactID = contacts.ContactID
               INNER JOIN NDB.CollectionUnits AS cu ON ds.CollectionUnitID = cu.CollectionUnitID
               INNER JOIN NDB.Sites AS sts ON cu.SiteID = sts.SiteID
               INNER JOIN NDB.DatasetTypes AS dst ON ds.DatasetTypeID = dst.DatasetTypeID 
               INNER JOIN NDB.DatasetSubmissions as dss on dss.DatasetID = ds.DatasetID
               LEFT JOIN NDB.DatasetPublications as dsp on dsp.DatasetID = ds.DatasetID
               LEFT JOIN NDB.Chronologies as chr on chr.CollectionUnitID = cu.CollectionUnitID"

doi_sens <- scan('..\\doi_sens.txt', what = "character")
con <- odbcDriverConnect(doi_sens[1])

ds_dates <- sqlQuery(con, query = build_ages,
                     stringsAsFactors = FALSE)

ds_dates <- ds_dates %>% gather(ID, date, -DatasetID) %>% 
  group_by(DatasetID) %>% summarise(max(date, na.rm = TRUE))

datasets <- unlist(ds_dates[,1])

good_files <- good_files[grep("doi", good_files$doi),]

if (any(datasets %in% good_files$id)) {
  db_dates <- as_date(unlist(ds_dates[match(good_files$id, datasets),2]))
  ids <- good_files$id[db_dates > as_date(good_files$date)]
  datasets <- datasets[!datasets %in% ids]
}

for (i in datasets) {

  ds_id <- i
  cat(i, '\n')

  if (!ds_id %in% list.files(end_point)) {
    # This is a new entry without prior versioning.
    dir.create(paste0(end_point, '/', ds_id))
    tester <- try(rmarkdown::render('static_page.Rmd', 
                      output_file = paste0(end_point, '/', ds_id, '/index.html'),
                      envir = globalenv(), quiet = TRUE))

    if (!class(tester) == "try-error") {
      unlink(paste0(end_point, '/', ds_id, '/index_files'), force = TRUE, recursive = TRUE)
     
      # Note, this needs to be run as an admin.
      shell(paste0("mklink /d ", end_point, '\\', ds_id, "\\index_files ",
                   end_point, "\\index_files"), intern = TRUE)
        
    } else {
      good_files <- read.csv('outputs.csv', header = TRUE)
      if (i %in% good_files$id) {
        good_files$doi[match(i, good_files$id)] <- "Err"
      }
    }
  }
}
