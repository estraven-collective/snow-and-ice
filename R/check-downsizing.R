library(tidyverse)
library(here)
library(glue)
library(stars)
library(lubridate)

# Boh?
Sys.setenv(GTIFF_SRS_SOURCE="GEOKEYS")

load('data/satellite-snow-cover.Rdata')

path_to_tif <- here(
  "data",
  "tif-out",
  "289350081",
  "VNP10A1F_A2024011_h18v04_001_2024014163211_NPP_Grid_IMG_2D_CGF_NDSI_Snow_Cover_31b135d6.tif"
)


last_day <- 
  path_to_tif %>% 
  read_stars()

# everything out of the 0-100 range is a diagnostic value
last_day[[1]][last_day[[1]] > 100] <- NA

downsized_last_day <- 
  st_warp(
    last_day, 
    crs = st_crs(last_day), 
    cellsize = c(5e3, 5e3)
  )

ggplot() +
  geom_stars(data = last_day) +
  labs(fill = "Snow",
       title = "Original")

ggplot() +
  geom_stars(data = downsized_last_day) +
  labs(fill = "Snow",
       title = "Downsized")

  
