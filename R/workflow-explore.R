library(here)
library(tidyverse)
library(stars)
library(rnaturalearth)
library(rnaturalearthdata)
library(scico)

source(here::here('R/read-viirs.R'))

# use custom values from GeoTIFF keys and drop the EPSG code
Sys.setenv(GTIFF_SRS_SOURCE="GEOKEYS")

# st <- read_stars('data/2023-output-geotiff/260463021/VNP10A1F_A2023034_h18v04_001_2023035141341_NPP_Grid_IMG_2D_CGF_NDSI_Snow_Cover_879b1352.tif')
st <- read_stars('data/2023-output-geotiff/264891504/VNP10A1F_A2023108_h18v04_001_2023109195420_NPP_Grid_IMG_2D_CGF_NDSI_Snow_Cover_6230d321.tif')

world <- 
  ne_countries(scale = "medium", returnclass = "sf")

#set all pixels not flagged as snow (>100) to Missing
st[[1]][st[[1]] > 100] <- NA

ggplot() +
  geom_stars(data = st,
             show.legend = F,
             alpha = .6) +
  geom_sf(data = world,
          colour = 'red',
          fill = '#00000000') +
  coord_sf(crs = sf::st_crs(st),
           # xlim = c(0, 5e6),
           # ylim = c(0, 5e6)
           xlim = sf::st_bbox(st)[c(1,3)],
           ylim = sf::st_bbox(st)[c(2,4)]
           ) +
  # scale_fill_viridis_b()
  scale_x_continuous(breaks = 5:13) +
  scale_fill_scico(palette = 'tokyo', direction = -1) +
  theme_minimal() +
  theme(panel.grid.major = element_line(linewidth = 2, colour = 'black'),
        panel.grid.minor = element_line(linewidth = 2, colour = 'black'))
  

# check all ---------------------------------------------------------------

tif_folders_tag <- 'output-geotiff'
pattern <- "\\d{4}-output-geotiff/"


all_tif_paths <-
# all_h5_paths <- 
  # downloaded_years %>% 
  # out_folder_from_year() %>% 
  # map(
  #   ~list.files(.,
  #               recursive = T,
  #               full.names = T)
  # ) %>% 
  # unlist() %>% 
  # .[str_detect(., pattern = '.he5$')] %>%
  list.files(path = "data", full.names = T, recursive = T) %>%
  {grep(pattern, ., value = T)} %>% 
  .[str_detect(., pattern = '.tif$')] %>%
  # .[str_detect(., pattern = '.he5$')] %>%
  tibble(path = .) %>% 
  separate(path, into = c('pre', 'date_string', rep(NA, 7), 'file_type_1', 'file_type_2'),
           sep = '_', remove = FALSE) %>% 
  unite(col = 'file_type', file_type_1:file_type_2,  sep = ' ') %>% 
  select(-pre) %>% 
  mutate(year = date_string %>% str_sub(2, 5) %>% as.numeric(),
         yday = date_string %>% str_sub(6,8) %>% as.numeric(),
         date = as.Date(glue('{year}-01-01')) + yday - 1)


# extract tidy df -----------------------------------------------

coords <- 
  st %>% 
  st_coordinates() %>% 
  as_tibble() %>% 
  mutate(snow = st$VNP10A1F_A2023108_h18v04_001_2023109195420_NPP_Grid_IMG_2D_CGF_NDSI_Snow_Cover_6230d321.tif %>% as.vector()) %>% 
  filter(snow > 0) %>% 
  filter(snow < 100)

coords %>% 
  ggplot()+
  aes(x = snow) +
  geom_histogram()

coords %>% 
  ggplot() +
  aes(x = x,
      y = y,
      fill = snow) +
  geom_tile() +
  coord_cartesian()

# extract snow cover estimate ---------------------------------------------
# 
# count_snow <- function(tif_path) {
#   st <- read_viirs(tif_path)
#   st[[3]][st[[3]] > 100] <- 0
#   return(st[[3]] %>% sum(na.rm = T))
# }
# 
# tiff_files_loaded <-  
#   all_tif_paths %>% 
#   mutate(snow_amount = map_dbl(path, count_snow))

# plot snow estimate ------------------------------------------------------

h5_files_loaded %>% 
  write_csv('data/h5_files_loaded.csv')

# h5_files_loaded %>% 
#   mutate(day = day %>% as.numeric()) %>% 
#   group_by(day) %>% 
#   mutate(med_snow = median(snow_amount, na.rm = T)) %>% 
#   ungroup() %>% 
#   filter(!(year == 2012 & day < 25)) %>% 
#   ggplot() +
#   aes(x = day) +
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

