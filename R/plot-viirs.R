library(here)
library(tidyverse)
library(stars)
library(rnaturalearth)
library(rnaturalearthdata)
library(scico)

source(here::here('R/read-viirs.R'))

# st <- read_viirs('data/VNP10A1F.A2023071.h18v04.001.2023072094756.h5')
st <- 
  read_viirs(
    here(
      'data',
      '2023-output',
      '264326604',
      'VNP10A1F_A2023086_h18v04_001_2023087183605_HEGOUT.he5'
    )
  )

world <- 
  ne_countries(scale = "medium", returnclass = "sf")
  # st_transform(crs = sf::st_crs(st))

# set all pixels not flagged as snow to 0
st[[3]][st[[3]] > 100] <- NA

ggplot() +
  geom_stars(data = st[3],
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
  
