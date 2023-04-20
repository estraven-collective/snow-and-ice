library(here)
library(tidyverse)
library(stars)
library(rnaturalearth)
library(rnaturalearthdata)
library(scico)

source(here::here('R/read-viirs.R'))

# use custom values from GeoTIFF keys and drop the EPSG code
Sys.setenv(GTIFF_SRS_SOURCE="GEOKEYS")

st <- read_stars('data/2023-output-geotiff/260463021/VNP10A1F_A2023034_h18v04_001_2023035141341_NPP_Grid_IMG_2D_CGF_NDSI_Snow_Cover_879b1352.tif')

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
  
