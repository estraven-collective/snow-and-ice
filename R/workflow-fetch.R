library(tidyverse)
library(here)

source(here('R/api-query.R'))

path <- fetch_viirs()

unzip(zpath, exdir = 'data/test-2012')
