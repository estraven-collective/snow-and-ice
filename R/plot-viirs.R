source(here::here('R/read-viirs.R'))
library(tidyverse)
library(stars)
library(rnaturalearth)
library(rnaturalearthdata)

st <- read_viirs('data/VNP10A1F.A2023071.h18v04.001.2023072094756.h5')

world <- 
  ne_countries(scale = "medium", returnclass = "sf") %>% 
  st_transform(crs = sf::st_crs(st))

# set all pixels not flagged as snow to 0
st[[3]][st[[3]] > 100] <- 0

ggplot() +
  geom_stars(data = st[3],
             show.legend = F) +
  geom_sf(data = world,
          colour = 'red',
          fill = '#00000000') +
  coord_sf(crs = sf::st_crs(st),
           xlim = sf::st_bbox(st)[c(1,3)],
           ylim = sf::st_bbox(st)[c(2,4)]) +
  scale_fill_viridis_b()

