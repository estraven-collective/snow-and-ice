library(tidyverse)
library(rnaturalearth)
library(rnaturalearthdata)
library(rhdf5)
library(stars)

crs_guess <- '+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs'

h5 <- here::here('data/VNP10A1F.A2023071.h18v04.001.2023072094756.h5')

meta <- 
  h5read(h5, name = '/HDFEOS INFORMATION/StructMetadata.0') %>% 
  cat()


res_guess <-  units::set_units(370.650173222222, m)
size_guess <- 3000
upper_left_x_guess <- units::set_units(0, m)
upper_left_y_guess <- units::set_units(5559752.598333, m)

y_error <- units::set_units(18000, m)


h5ls(h5)

x <- 
  h5read(h5, name = '/HDFEOS/GRIDS/NPP_Grid_IMG_2D/XDim') %>%
  units::set_units(m)

y <- 
  h5read(h5, name = '/HDFEOS/GRIDS/NPP_Grid_IMG_2D/YDim') %>% 
  units::set_units(m) %>% 
  `-`(y_error) 

world <- 
  ne_countries(scale = "medium", returnclass = "sf") %>% 
  st_transform(crs = crs_guess)



st <- read_stars(
  h5
)

attr(st, 'dimensions')$x$offset <- upper_left_x_guess # min(x)
attr(st, 'dimensions')$y$offset <- upper_left_y_guess - y_error # max(y)
attr(st, 'dimensions')$x$delta <- res_guess
attr(st, 'dimensions')$y$delta <- -res_guess
st_crs(st) <- crs_guess

st %>% names()

ggplot() +
  geom_stars(data = st[3],
             show.legend = F) +
  geom_sf(data = world,
          colour = 'red',
          fill = '#00000000') +
  coord_sf(crs = crs_guess,
           xlim = range(x),
           ylim = range(y)) 
