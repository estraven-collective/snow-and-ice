library(tidyverse)
library(here)
library(glue)
library(stars)

source(here('R/api-query.R'))
source(here('R/read-viirs.R'))


# fetch all years ---------------------------------------------------------

years <- 2012:2023

zipped_output <- here("query_output")
zipped_data_tag <- '-output.zip'
year_data_folder_tag <- 'output-geotiff'

years %>% 
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

# unzip all years ---------------------------------------------------------

out_folder_from_year <- function(year) {
  glue('data/{year_from_path(year)}-{year_data_folder_tag}')
}

downloaded_data_path %>% 
  walk(
    ~unzip(
      zipfile = .,
      exdir = out_folder_from_year(.)
    )
  )

