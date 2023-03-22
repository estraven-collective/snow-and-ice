source(here::here('R/read-viirs.R'))
library(tidyverse)

# set all pixels not flagged as snow to 0
st[[3]][st[[3]] > 100] <- 0

ggplot() +
  geom_stars(data = st[3],
             show.legend = F) +
  geom_sf(data = world,
          colour = 'red',
          fill = '#00000000') +
  coord_sf(crs = crs_guess,
           xlim = range(x),
           ylim = range(y)) +
  scale_fill_viridis_b()

