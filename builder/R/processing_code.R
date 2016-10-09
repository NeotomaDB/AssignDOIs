# Note, FAUNMAP records are not really showing up here.  I think it's because the site name isn't where
# I think it is.  Check with Eric.

end_point <- 'C:\\vdirs\\doi\\datasets'

for (i in sample(19924, size = 1000, replace = FALSE)) {

  ds_id <- i
  cat(i)

  if (!ds_id %in% list.files(end_point)) {
    # This is a new entry without prior versioning.
    tester <- try(rmarkdown::render('static_page.Rmd', 
                      output_file = paste0('index.html'),
                      envir = globalenv()))

    if (!class(tester) == "try-error") {
      dir.create(paste0(end_point, ds_id))
      file.copy(from = paste0('Packrat.png'),
                to   = paste0(end_point, ds_id, '\\Packrat.png'))
      file.copy(from = paste0('nsf.png'),
                to   = paste0(end_point, ds_id, '\\nsf.png')) 
      file.copy(from = paste0('index.html'),
                to   = paste0(end_point, ds_id, '\\index.html'),
                overwrite = TRUE) 
      file.copy(from = paste0('logo_earthcube_cube-only_SMALL.png'),
                to   = paste0(end_point, ds_id, '\\logo_earthcube_cube-only_SMALL.png'))
      file.copy(from = paste0('index_files'),
                to   = paste0(end_point, ds_id),
                recursive = TRUE, overwrite = TRUE) 
    }
  } else {
    # Add check for date & SQL code to check relevant modification dates.
#    file.copy(from = paste0('C:\\Users\\Simon Goring\\Documents\\GitHub\\neotomadb.github.io\\dataset\\', ds_id, '\\index.html'),
#              to   = paste0('C:\\Users\\Simon Goring\\Documents\\GitHub\\neotomadb.github.io\\dataset\\', ds_id, '\\index_', format(Sys.time(), '%Y-%m-%d'), '.html'))
#    try(rmarkdown::render('static_page.Rmd', 
#                      output_file = paste0('C:\\Users\\Simon Goring\\Documents\\GitHub\\neotomadb.github.io\\dataset\\', ds_id, '\\index.html'),
#                      envir = globalenv()))
  }
}
