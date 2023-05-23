library(tidyverse)
library(here)
library(glue)
library(stars)
library(lubridate)
library(rnaturalearth)
library(rnaturalearthdata)
library(scico)
library(googledrive)

theme_set(
  theme_minimal() +
    theme(panel.grid.major = element_line(linewidth = 2, colour = 'black'),
          panel.grid.minor = element_line(linewidth = 2, colour = 'black'))
)

source(here('R/api-query.R'))
source(here('R/read-viirs.R'))

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
days <- seq.Date(first_day_available, today(), by = 'day')  
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
  
# po river basin ----------------------------------------------------------

# https://www.eea.europa.eu/en/datahub/datahubitem-view/e64928db-e6c1-4acc-bab0-7722bb50075f
# Vector Data > Direct Download > GPKG
basins <-
  read_sf('data/WaterAccounts_SpatialUnits.gpkg') 

po <-
  basins %>%
  filter(entityName %>% str_detect('^Po')) 

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

measure_snow_sunday <- function(path,
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
    if(wday(date) == 1) {
    snow_img <- read_stars(path)
    po <- po %>% st_transform(crs = st_crs(snow_img))
    snow_img <- snow_img %>% st_crop(po, crop = T)
    snow_img[[1]][snow_img[[1]] > 100] <- NA
    snow_amount <- snow_img[[1]] %>% sum(na.rm = T)
    } else {
      snow_img <- NA
      snow_amount <- NA
    }
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
  # return(st[[1]] %>% sum(na.rm = T))
}
  
# Check that all days have been downloaded --------------------------------
  
all_dates <- 
  seq.Date(from = first_day_available, to = Sys.Date(), by = "day")

if(file.exists(rdata_storage)) {
  load(rdata_storage)
  
  missing_dates <- 
    setdiff(
      all_dates,
      all_snow_measured$date
    ) %>% 
    as_date()
} else {
  missing_dates <- all_dates 
}

# all_tif_paths <- 
#   get_all_tif_paths(tif_out_folder)
#   
# all_snow_paths <- 
#   all_tif_paths %>% 
#   filter(file_type == 'CGF NDSI')

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
      overwrite = FALSE
    )
  )
 
# # extract snow and plot cover estimate -------------------------------------

all_tif_paths <- 
  get_all_tif_paths(tif_out_folder)
 
all_snow_paths <- 
  all_tif_paths %>% 
  filter(file_type == 'CGF NDSI')

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
  pmap_dfr(measure_snow_sunday)

save(all_snow_measured, file = rdata_storage)


# upload data to google drive ---------------------------------------------

drive_upload(media = rdata_storage,
             path = drive_folder,
             overwrite = T)

# all_snow_measured %>% 
#   group_by(yday) %>% 
#   mutate(med_snow = median(snow_amount, na.rm = T)) %>% 
#   ungroup() %>% 
#   filter(!(year == 2012 &  yday < 25)) %>% # data for first days are a bit noisy? 
#   ggplot() +
#   aes(x = yday) +
#   geom_line(
#     aes(y = med_snow),
#     colour = 'grey70',
#     size = 2
#   ) +
#   geom_line(
#     aes(y = snow_amount),
#     size = 1.2
#   ) +
#   facet_wrap(facets = 'year') +
#   theme_bw()

# 
# # subset po river basin ---------------------------------------------------
# 
# basins <- read_sf('data/WaterAccounts_SpatialUnits.gpkg')
# 
# ita <- 
#   ne_countries(scale = "medium", returnclass = "sf") %>% 
#   filter(name %>% str_detect('Ita'))
# 
# last_measure <- 
#   all_snow_measured %>% 
#   filter(date == max(date)) %>% 
#   pull(path) %>% 
#   read_stars() 
# 
# last_measure[[1]][last_measure[[1]] > 100] <- NA
# 
# po <- basins %>%
#   filter(entityName %>% str_detect('^Po')) %>% 
#   st_transform(crs = st_crs(last_measure))
# 
# ggplot(po) +
#   geom_sf(data = ita, fill = '#DDDDDD') +
#   geom_sf(fill = '#92BB66', alpha = .7) 
# 
# 
# last_measure_cropped <- st_crop(last_measure, po, crop = T)
# 
# ggplot() +
#   geom_stars(data = last_measure_cropped) +
#   labs(fill = 'Snow %') +
#   coord_sf(crs = sf::st_crs(last_measure_cropped)) +
#   scale_fill_scico(palette = 'tokyo',
#                    direction = 1,
#                    na.value = '#FFFFFF00') 
# 
# crop_and_count_snow <- function(tif_path) {
#   print(tif_path)
#   st <- read_stars(tif_path)
#   st[[1]][st[[1]] > 100] <- NA
#   st <- st_crop(st, po, crop = T)
#   return(st[[1]] %>% sum(na.rm = T))
# }
# 
# # On my machine it takes ~3 hours and a half
# # at about three seconds per image
# 
# all_snow_measured_cropped <- 
#   all_snow_measured %>% 
#   mutate(snow_amount_cropped = map_dbl(path, crop_and_count_snow))
# 
# all_snow_measured_cropped %>% 
#   write_csv(
#     here('data', 'all_snow_measured_cropped.csv')
#   )
# 
# all_snow_measured_cropped %>% 
#   group_by(yday) %>% 
#   mutate(med_snow = median(snow_amount_cropped, na.rm = T)) %>% 
#   ungroup() %>% 
#   filter(!(year == 2012 &  yday < 25)) %>% # data for first days are a bit noisy? 
#   ggplot() +
#   aes(x = yday) +
#   geom_line(
#     aes(y = med_snow),
#     colour = 'grey70',
#     size = 2
#   ) +
#   geom_line(
#     aes(y = snow_amount_cropped),
#     size = 1.2
#   ) +
#   labs(title = 'Amount of Snow and Ice in the Po River Basin') +
#   facet_wrap(facets = 'year') +
#   theme_bw()
