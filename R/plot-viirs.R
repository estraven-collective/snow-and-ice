source(here::here('R/read-viirs.R'))
library(tidyverse)
library(stars)
library(rnaturalearth)
library(rnaturalearthdata)

h5_files <- 
  list.files('data/test-2012/',
             recursive = T,
             full.names = T) %>% 
  .[str_detect(., pattern = '.he5$')] %>% 
  tibble(path = .) %>% 
  separate(path, into = c('pre', 'date'), sep = '_', remove = FALSE) %>% 
  select(-pre) %>% 
  mutate(year = date %>% str_sub(2, 5),
         day = date %>% str_sub(6,8))


count_snow <- function(h5_path) {
  st <- read_viirs(h5_path)
  st[[3]][st[[3]] > 100] <- 0
  return(st[[3]] %>% sum(na.rm = T))
}

h5_files_loaded <-  
  h5_files %>% 
  mutate(snow_amount = map_dbl(path, count_snow))

h5_files_loaded %>% 
  ggplot() +
  aes(x = day %>% as.numeric(),
      y = snow_amount) +
  geom_line() +
  theme_bw()

# st <- read_viirs('data/VNP10A1F.A2023071.h18v04.001.2023072094756.h5')
# st <- read_viirs('data/query-full-timespan/166975177/VNP10A1F_A2012024_h18v04_001_2019317170939_HEGOUT.he5')
st <- read_viirs('data/query-full-timespan/166974973/VNP10A1F_A2012024_h19v04_001_2019317171405_HEGOUT.he5')


world <- 
  ne_countries(scale = "medium", returnclass = "sf") %>% 
  st_transform(crs = sf::st_crs(st))

# set all pixels not flagged as snow to 0
st[[3]][st[[3]] > 100] <- 0

st[[3]][st[[3]] > 0] %>% hist()

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

