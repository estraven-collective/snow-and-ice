library(tidyverse)
library(here)
library(glue)
library(stars)
library(lubridate)

source(here('R/api-query.R'))
source(here('R/read-viirs.R'))

# use custom values from GeoTIFF keys and drop the EPSG code
Sys.setenv(GTIFF_SRS_SOURCE="GEOKEYS")

# parameters --------------------------------------------------------------

first_day_available <- as.Date('2012-01-19') # first day recorded by VIIRS
years <- 2012:2023
zipped_output <- here("query_output")
zipped_data_tag <- '-output.zip'
year_data_folder_tag <- 'output-geotiff'


# helper functions --------------------------------------------------------

out_folder_from_year <- function(year) {
  glue('data/{year_from_path(year)}-{year_data_folder_tag}')
}

# check that all years have been downloaded -------------------------------

downloaded_data_path <- 
  zipped_output %>% 
  list.files(full.names = T) %>% 
  .[str_detect(., pattern = glue('{zipped_data_tag}$'))]

year_from_path <- function(path) {
  downloaded_years <- 
    path %>% 
    str_remove(zipped_output) %>% 
    str_remove("/") %>% 
    str_remove(zipped_data_tag) %>% 
    as.numeric()  
  
  return(downloaded_years)
}

downloaded_years <- year_from_path(downloaded_data_path)

# missing years
missing_years <- setdiff(years, downloaded_years)
if(length(missing_years) > 0) cat('year:', missing_years, 'is/are missing\n') 


# Check that all days have been downloaded --------------------------------

all_tif_paths <- 
  downloaded_years %>%
  out_folder_from_year() %>%
  map(
    ~list.files(
      .,
      recursive = T,
      full.names = T)
  ) %>%
  unlist() %>% 
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
         date = as.Date(glue('{year}-01-01')) + yday - 1)

all_snow_paths <- 
  all_tif_paths %>% 
  filter(file_type == 'CGF NDSI')

years_missing_dates <- 
  seq.Date(from = first_day_available, to = Sys.Date(), by = "day") %>% 
  setdiff(all_snow_paths$date) %>% 
  as_date()

years_with_missing_dates <- 
  years_missing_dates %>% 
  year() %>% 
  unique()

# try fetch again years with missing dates  -------------------------------

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



# unzip all years ---------------------------------------------------------



downloaded_data_path %>% 
  walk(
    ~unzip(
      zipfile = .,
      exdir = out_folder_from_year(.)
    )
  )

# extract snow cover estimate ---------------------------------------------

count_snow <- function(tif_path) {
  st <- read_stars(tif_path)
  st[[1]][st[[1]] > 100] <- NA
  return(st[[1]] %>% sum(na.rm = T))
}


all_snow_measured <-  
  all_snow_paths %>% 
  mutate(snow_amount = map_dbl(path, count_snow))
