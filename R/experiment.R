library(tidyverse)
library(here)
library(glue)
library(stars)
library(lubridate)
library(scico)

snow <- read_csv('data/all_snow_measured_cropped.csv')

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
           month = month(date)) %>% 
  summarise(
    across(.cols = starts_with('snow'),
           .fns = ~mean(.,na.rm = T))
  ) 

monthly_snow_res %>% 
  ggplot() +
  aes(x = snow_amount_cropped,
      y = 1) +
  geom_col(orientation = 'y',
           fill = '#3366EE') +
  facet_grid(cols = vars(month),
             rows = vars(year),
             switch = 'y') +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  theme_bw() +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        panel.spacing = unit(0, units = 'mm'),
        strip.text.y.left = element_text(angle = 0))

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

