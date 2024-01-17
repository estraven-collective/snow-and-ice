library(tidyverse)
library(here)
library(glue)
library(stars)
library(lubridate)
library(rnaturalearth)
library(rnaturalearthdata)
library(googledrive)

source(here('R/api-query.R'))

# use custom values from GeoTIFF keys and drop the EPSG code
Sys.setenv(GTIFF_SRS_SOURCE="GEOKEYS")

# authorize google drive
if(interactive()) {
  drive_auth(
    path = here('.secrets/driven-airway-387509-ad76a3b28771.json')
  )
}

# parameters --------------------------------------------------------------

first_day_available <- as.Date('2012-01-19') # first day recorded by VIIRS
days <- seq.Date(first_day_available, today(), by = 'week')  
zipped_output <- here("query_output")
zipped_data_tag <- '-output.zip'
year_data_folder_tag <- 'output-geotiff'
tif_out_folder <- here('data/tif-out')
rdata_name <- 'satellite-snow-cover.Rdata'
rdata_storage <- here('data', rdata_name)
drive_folder <- as_id('13boyabHCvZaUWxO6CtKT3NCglpy7X5d_')

# check if data are available on drive ------------------------------------

drive_folder_content <- 
  drive_ls(drive_folder)

print(drive_folder_content)

drive_data_id <- 
  drive_folder_content %>% 
  filter(name == rdata_name) %>% 
  pull(id)
  
if(length(drive_data_id) == 1) {
  cat('Downloading data from Google Drive:', drive_data_id, '\n')
  drive_download(file = drive_data_id, overwrite = T, path = rdata_storage)
} else {
  cat('No data found on Google Drive\n')
}
  
# Check that all days have been downloaded --------------------------------

if(file.exists(rdata_storage)) {
  load(rdata_storage)
  
  all_snow_measured <- 
    all_snow_measured %>% 
    filter(date %in% days)
  
  missing_dates <- 
    setdiff(
      days,
      all_snow_measured$date
    ) %>% 
    as_date()
} else {
  missing_dates <- days 
}

years_with_missing_dates <- 
  missing_dates %>% 
  year() %>% 
  unique()

# try fetch again years with missing dates  -------------------------------

cat('Downloading missing data for years:', years_with_missing_dates, '\n')

years_with_missing_dates %>% 
  walk(
    ~fetch_viirs(
      start_date = glue('{.}-01-01'),
      end_date = glue('{.}-12-31'),
      format = 'GeoTIFF',
      output_folder = zipped_output,
      request_file = glue('{.}-request.xml'),
      response_file = glue('{.}-response.xml'),
      output_zip = glue('{.}{zipped_data_tag}'),
    ))

# # unzip all years ---------------------------------------------------------

list.files(
  path = zipped_output,
  pattern = zipped_data_tag,
  full.names = T
) %>% 
  walk(
    ~unzip(
      zipfile = .,
      exdir = tif_out_folder,
      overwrite = TRUE
    )
  )

# helper functions --------------------------------------------------------

out_folder_from_year <- function(year) {
  glue('data/{year_from_path(year)}-{year_data_folder_tag}')
}

get_all_tif_paths <- function(tif_out_folder) {
  all_tif_paths <- 
    list.files(tif_out_folder,
               recursive = T,
               full.names = T) %>% 
    .[str_detect(., pattern = '.tif$')] %>%
    tibble(path = .) %>% 
    separate(
      path,
      into = c(
        'pre',
        'date_string',
        rep(NA, 7),
        'file_type_1',
        'file_type_2'
      ),
      sep = '_',
      remove = FALSE) %>% 
    unite(col = 'file_type',
          file_type_1:file_type_2,
          sep = ' ') %>% 
    select(-pre) %>% 
    mutate(year = date_string %>% str_sub(2, 5) %>% as.numeric(),
           yday = date_string %>% str_sub(6,8) %>% as.numeric(),
           date = as_date(glue('{year}-01-01')) + yday - 1)
  
  return(all_tif_paths)
}

measure_snow <- function(path,
                         date_string,
                         file_type,
                         year,
                         yday,
                         date,
                         snow_img,
                         snow_amount)
{
  if(! class(snow_img) == "stars") {
    cat('Processing file:', path, '\n')
    snow_img <- read_stars(path)
    snow_img <- 
      st_warp(
        snow_img, 
        crs = st_crs(snow_img), 
        cellsize = c(5e3, 5e3)
      )
    snow_img[[1]][snow_img[[1]] > 100] <- NA
    snow_amount <- snow_img[[1]] %>% sum(na.rm = T)
  }
  
  out <- 
    tibble(
      path = path,
      date_string = date_string,
      file_type = file_type,
      year = year,
      yday = yday,
      date = date,
      snow_img = list(snow_img),
      snow_amount = snow_amount
    )
  return(out)
}
 
# # extract snow and plot cover estimate -------------------------------------

all_tif_paths <- 
  get_all_tif_paths(tif_out_folder)
 
all_snow_paths <- 
  all_tif_paths %>% 
  filter(file_type == 'CGF NDSI') %>% 
  filter(date %in% days); rm(all_tif_paths)

if(exists(quote(all_snow_measured))) {
  all_snow_measured <- 
    all_snow_measured %>% 
    full_join(all_snow_paths)
} else {
  all_snow_measured <- 
    all_snow_paths %>% 
    mutate(snow_img = list(NA),
           snow_amount = NA)
}

all_snow_measured <-  
  all_snow_measured %>% 
  pmap_dfr(measure_snow)

save(all_snow_measured, file = rdata_storage)


# upload data to google drive ---------------------------------------------

drive_upload(media = rdata_storage,
             path = drive_folder,
             overwrite = T)

