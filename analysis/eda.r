library(stats)
library(tidyverse)
library(tidync)
library(here)

# for background plotting
library(maps)
library(ggmap)

aus = map_data('world') %>% filter(region == 'Australia')

txx =
  tidync(here('analysis', 'data', 'index-ts', 'txx.nc'))
  
txx_t1 =
  txx %>%
  hyper_filter(time = time == min(time)) %>%
  hyper_tibble()

t1_plot =
  ggplot() +
  geom_polygon(
    data = aus,
    mapping = aes(x = long, y = lat, group = group),
    fill = '#aaaaaa', colour = '#999999') +
  geom_tile(
    data = txx_t1,
    mapping = aes(x = lon, y = lat, fill = tmax))
  
