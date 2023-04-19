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


all_hf5_paths <- 
  downloaded_years %>% 
  out_folder_from_year() %>% 
  map(
    ~list.files(.,
               recursive = T,
               full.names = T)
  ) %>% 
  unlist() %>% 
  # .[str_detect(., pattern = '.he5$')] %>%
  .[str_detect(., pattern = '.tif$')] %>%
  tibble(path = .) %>% 
  separate(path, into = c('pre', 'date_string'), sep = '_', remove = FALSE) %>% 
  select(-pre) %>% 
  mutate(year = date_string %>% str_sub(2, 5) %>% as.numeric(),
         yday = date_string %>% str_sub(6,8) %>% as.numeric(),
         date = as.Date(glue('{year}-01-01')) + yday - 1)



# extract snow cover estimate ---------------------------------------------

count_snow <- function(h5_path) {
  st <- read_viirs(h5_path)
  st[[3]][st[[3]] > 100] <- 0
  return(st[[3]] %>% sum(na.rm = T))
}

h5_files_loaded <-  
  all_hf5_paths %>% 
  mutate(snow_amount = map_dbl(path, count_snow))

# plot snow estimate ------------------------------------------------------

h5_files_loaded %>% 
  write_csv('data/h5_files_loaded.csv')

h5_files_loaded %>% 
  mutate(day = day %>% as.numeric()) %>% 
  group_by(day) %>% 
  mutate(med_snow = median(snow_amount, na.rm = T)) %>% 
  ungroup() %>% 
  filter(!(year == 2012 & day < 25)) %>% 
  ggplot() +
  aes(x = day) +
  geom_line(
    aes(y = med_snow),
    colour = 'grey70',
    size = 2
  ) +
  geom_line(
    aes(y = snow_amount),
    size = 1.2
  ) +
  facet_wrap(facets = 'year') +
  theme_bw()
