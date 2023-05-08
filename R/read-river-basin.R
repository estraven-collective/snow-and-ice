library(sf)
library(stars)
library(tidyverse)
library(rnaturalearth)
library(rnaturalearthdata)


ita <- 
  ne_countries(scale = "medium", returnclass = "sf") %>% 
  filter(name %>% str_detect('Ita'))

# https://www.eea.europa.eu/en/datahub/datahubitem-view/e64928db-e6c1-4acc-bab0-7722bb50075f
# Vector Data > Direct Download > GPKG
basins <- read_sf('data/WaterAccounts_SpatialUnits.gpkg') 


# River Network -- LOOKS BAD
# https://www.eea.europa.eu/en/datahub/datahubitem-view/a9844d0c-6dfb-4c0c-a693-7d991cc82e6e
rivers <-
  read_sf('data/rivers') %>% 
  filter(SUB_BASIN %>% str_detect('^Po '))

po <- basins %>%
  filter(entityName %>% str_detect('^Po')) %>% 
  st_transform(crs = '+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs')

ggplot(po) +
  geom_sf(data = ita, fill = '#888888') +
  geom_sf(fill = '#22BB66', alpha = .7) 

source('R/read-viirs.R')

st <- read_viirs('data/test-2012/167044281/VNP10A1F_A2012041_h18v04_001_2019318154657_HEGOUT.he5')
st[[3]][st[[3]] > 100] <- 0

snow_basin <- st_crop(st, po, crop = T)

ggplot() +
  geom_stars(data = snow_basin[3],
             show.legend = F) +
  coord_sf(crs = st_crs(st)) +
  scale_fill_viridis_b()

snow_basin[[3]] %>% hist()
snow_basin[[3]] %>% sum(na.rm = T)
