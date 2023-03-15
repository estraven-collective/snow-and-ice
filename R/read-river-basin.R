library(sf)
library(tidyverse)
library(rnaturalearth)
library(rnaturalearthdata)


ita <- 
  ne_countries(scale = "medium", returnclass = "sf") %>% 
  filter(name %>% str_detect('Ita'))

# https://www.eea.europa.eu/en/datahub/datahubitem-view/e64928db-e6c1-4acc-bab0-7722bb50075f
# Vector Data > Direct Download > GPKG
basins <- read_sf('data/WaterAccounts_SpatialUnits.gpkg')

po <- basins %>% filter(entityName %>% str_detect('^Po'))

ggplot(po) +
  geom_sf(data = ita, fill = '#888888') +
  geom_sf(fill = '#22BB66', alpha = .7) 
