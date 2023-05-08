library(tidyverse)
library(here)
library(glue)
library(stars)
library(lubridate)
library(scico)
library(rnaturalearth)
library(rnaturalearthdata)

snow <- read_csv('data/all_snow_measured_cropped.csv')

# use custom values from GeoTIFF keys and drop the EPSG code
Sys.setenv(GTIFF_SRS_SOURCE="GEOKEYS")

# snow per month ----------------------------------------------------------


snow %>% 
 group_by(year,
          week = week(date)) %>% 
  summarise(
    across(.cols = starts_with('snow'),
           .fns = ~mean(.,na.rm = T))
  ) %>% 
  ggplot() +
  aes(x = year,
      y = week,
      fill = snow_amount_cropped) +
  geom_tile() +
  scale_y_reverse() +
  scale_fill_scico(palette = 'tokyo') +
  theme_minimal()

monthly_snow_res <- 
  snow %>% 
  group_by(year,
           month = month(date, label = T)) %>% 
  summarise(
    across(.cols = starts_with('snow'),
           .fns = ~mean(.,na.rm = T))
  ) 

monthly_snow_res %>% 
  ggplot() +
  aes(x = 1,
      y = snow_amount_cropped) +
  geom_col(fill = '#3366EE') +
  facet_grid(rows = vars(month),
             cols = vars(year),
             switch = 'y') +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  theme_bw() +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_blank(),
        panel.spacing = unit(0, units = 'mm'),
        strip.text.y.left = element_text(angle = 0))


# plot river basins -------------------------------------------------------

basins <- read_sf('data/WaterAccounts_SpatialUnits.gpkg')

ita <- 
  ne_countries(scale = "medium", returnclass = "sf") %>% 
  filter(name %>% str_detect('Ita'))

last_measure <- 
  snow %>% 
  filter(date == max(date)) %>% 
  pull(path) %>% 
  read_stars() 

last_measure[[1]][last_measure[[1]] > 100] <- NA

po <- basins %>%
  filter(entityName %>% str_detect('^Po')) %>% 
  st_transform(crs = st_crs(last_measure))

# River Network
# https://www.eea.europa.eu/en/datahub/datahubitem-view/a9844d0c-6dfb-4c0c-a693-7d991cc82e6e
rivers <-
  read_sf('data/euhydro_po_v013_FGDB/euhydro_po_v013.gdb/') %>% 
  # filter(SUB_BASIN %>% str_detect('^Po ')) %>% 
  st_transform(crs = st_crs(last_measure))


ggplot(po) +
  geom_sf(data = ita, fill = '#DDDDDD') +
  geom_sf(fill = '#92BB66', alpha = .7) 

ggplot(rivers) +
  geom_sf(data = ita, fill = '#DDDDDD') +
  geom_sf()

last_measure_cropped <- st_crop(last_measure, po, crop = T)

ggplot() +
  geom_stars(data = last_measure_cropped) +
  labs(fill = 'Snow %') +
  coord_sf(crs = sf::st_crs(last_measure_cropped)) +
  scale_fill_scico(palette = 'buda',
                   direction = 1,
                   na.value = '#FFFFFF00') 


# downsample --------------------------------------------------------------

last_measure_cropped_down <- 
  last_measure_cropped %>% st_downsample(n = 2)

save(last_measure, file = 'data/last-measure.Rdata')
save(last_measure_cropped, file = 'data/last-measure-cropped.Rdata')
save(last_measure_cropped_down, file = 'data/last-measure-cropped-down.Rdata')

# 
# source(here('R/api-query.R'))
# source(here('R/read-viirs.R'))
# 
# 
# d <- 
#   read_viirs(
#     here(
#       'data',
#       '2023-output',
#       '264712484',
#       'VNP10A1F_A2023099_h18v04_001_2023100121927_HEGOUT.he5'
#     )
# )
# 
# d[[3]][d[[3]] > 100] <- 0
# 
# d <- d[3]
# 
# stars::st_warp(d)
# 

