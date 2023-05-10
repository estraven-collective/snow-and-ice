library(tidyverse)
library(here)
library(glue)
library(stars)
library(lubridate)
library(rnaturalearth)
library(rnaturalearthdata)
library(scico)

theme_set(
  theme_minimal() +
    theme(panel.grid.major = element_line(linewidth = 2, colour = 'black'),
          panel.grid.minor = element_line(linewidth = 2, colour = 'black'))
)

source(here('R/api-query.R'))
source(here('R/read-viirs.R'))

# use custom values from GeoTIFF keys and drop the EPSG code
Sys.setenv(GTIFF_SRS_SOURCE="GEOKEYS")

# parameters --------------------------------------------------------------

#first_day_available <- as.Date('2012-01-19') # first day recorded by VIIRS
first_day_available <- as.Date('2023-01-01')
days <- seq.Date(first_day_available, today(), by = 'day')  
zipped_output <- here("query_output")
zipped_data_tag <- '-output.zip'
year_data_folder_tag <- 'output-geotiff'
tif_out_folder <- here('data/tif-out')

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

count_snow <- function(tif_path) {
  st <- read_stars(tif_path)
  st[[1]][st[[1]] > 100] <- NA
  return(st[[1]] %>% sum(na.rm = T))
}
  
  # Check that all days have been downloaded --------------------------------
  
all_tif_paths <- 
  get_all_tif_paths(tif_out_folder)
  
all_snow_paths <- 
  all_tif_paths %>% 
  filter(file_type == 'CGF NDSI')

missing_dates <- 
  seq.Date(from = first_day_available, to = Sys.Date(), by = "day") %>% 
  setdiff(all_snow_paths$date) %>% 
  as_date()

years_with_missing_dates <- 
  missing_dates %>% 
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

list.files(
  path = zipped_output,
  pattern = zipped_data_tag,
  full.names = T
) %>% 
  walk(
    ~unzip(
      zipfile = .,
      exdir = tif_out_folder,
      overwrite = FALSE
    )
  )

# extract snow and plot cover estimate -------------------------------------

all_tif_paths <- 
  get_all_tif_paths(tif_out_folder)

all_snow_paths <- 
  all_tif_paths %>% 
  filter(file_type == 'CGF NDSI')

all_snow_measured <-  
  all_snow_paths %>% 
  mutate(snow_amount = map_dbl(path, count_snow))

all_snow_measured %>% 
  group_by(yday) %>% 
  mutate(med_snow = median(snow_amount, na.rm = T)) %>% 
  ungroup() %>% 
  filter(!(year == 2012 &  yday < 25)) %>% # data for first days are a bit noisy? 
  ggplot() +
  aes(x = yday) +
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


# subset po river basin ---------------------------------------------------

basins <- read_sf('data/WaterAccounts_SpatialUnits.gpkg')

ita <- 
  ne_countries(scale = "medium", returnclass = "sf") %>% 
  filter(name %>% str_detect('Ita'))

last_measure <- 
  all_snow_measured %>% 
  filter(date == max(date)) %>% 
  pull(path) %>% 
  read_stars() 

last_measure[[1]][last_measure[[1]] > 100] <- NA

po <- basins %>%
  filter(entityName %>% str_detect('^Po')) %>% 
  st_transform(crs = st_crs(last_measure))

ggplot(po) +
  geom_sf(data = ita, fill = '#DDDDDD') +
  geom_sf(fill = '#92BB66', alpha = .7) 


last_measure_cropped <- st_crop(last_measure, po, crop = T)

ggplot() +
  geom_stars(data = last_measure_cropped) +
  labs(fill = 'Snow %') +
  coord_sf(crs = sf::st_crs(last_measure_cropped)) +
  scale_fill_scico(palette = 'tokyo',
                   direction = 1,
                   na.value = '#FFFFFF00') 

crop_and_count_snow <- function(tif_path) {
  print(tif_path)
  st <- read_stars(tif_path)
  st[[1]][st[[1]] > 100] <- NA
  st <- st_crop(st, po, crop = T)
  return(st[[1]] %>% sum(na.rm = T))
}

# On my machine it takes ~3 hours and a half
# at about three seconds per image

all_snow_measured_cropped <- 
  all_snow_measured %>% 
  mutate(snow_amount_cropped = map_dbl(path, crop_and_count_snow))

all_snow_measured_cropped %>% 
  write_csv(
    here('data', 'all_snow_measured_cropped.csv')
  )

all_snow_measured_cropped %>% 
  group_by(yday) %>% 
  mutate(med_snow = median(snow_amount_cropped, na.rm = T)) %>% 
  ungroup() %>% 
  filter(!(year == 2012 &  yday < 25)) %>% # data for first days are a bit noisy? 
  ggplot() +
  aes(x = yday) +
  geom_line(
    aes(y = med_snow),
    colour = 'grey70',
    size = 2
  ) +
  geom_line(
    aes(y = snow_amount_cropped),
    size = 1.2
  ) +
  labs(title = 'Amount of Snow and Ice in the Po River Basin') +
  facet_wrap(facets = 'year') +
  theme_bw()
