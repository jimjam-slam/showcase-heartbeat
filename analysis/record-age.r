library(stats)
library(lubridate)
library(tidyverse)
library(tidync)
library(magrittr)
library(gganimate)
library(broom)
library(here)
library(RPushbullet)

# for background plotting
library(maps)
library(ggmap)

aus = map_data('world') %>% filter(region == 'Australia')

rec_txx =
  # get the netcdf into a data frame
  tidync(
    here('analysis', 'data', 'record-ts', 'monthly-TXx-records.nc')) %>%
  activate('hot_record_time') %>%
  hyper_tibble() %T>%
  # tidy up a little
  print() %>%
  mutate(record = as.logical(hot_record_time)) %>%
  select(-hot_record_time) %>%
  arrange(time) %>%
  # cell-by-cell: find the time since the last record
  group_by(longitude, latitude) %>%
  mutate(last_record = if_else(record, true = time, false = NA_integer_)) %>%
  fill(last_record) %>%
  mutate(
    record_age = time - last_record,
    record_age_clamped = case_when(
      record_age > 120 ~ NA_integer_,
      TRUE ~ record_age
    )) %>%
  select(-last_record) %>%
  ungroup() %>%
  # convert time column to actual dates. assume since jan 1950 (check!)
  mutate(date = as.Date('1950-01-15') + months(time - 1)) %T>%
  print()

rec_txx_plot =
  rec_txx %>%
  ggplot() +
  geom_polygon(
    data = aus,
    mapping = aes(x = long, y = lat, group = group),
    fill = '#cccccc', colour = '#999999') +
  geom_tile(
    aes(x = longitude, y = latitude, frame = date, alpha = record_age_clamped),
    fill = 'red') +
  # scale_fill_gradient(low = '#ff0000ff', high = '#33333300', na.value = '#ffffff00') +
  scale_alpha_continuous(range = 1:0, na.value = 0) +
  coord_fixed(ratio = 1) +
  labs(
    x = 'Longitude',
    y = 'Latitude',
    fill = 'Months since\nrecord',
    title = 'Months since TXx record broken in grid cell as of ') +
  theme_minimal() +
  theme(
    legend.position = 'bottom',
    legend.direction = 'horizontal')

gganimate(rec_txx_plot,
  filename = '~/Desktop/rec_txx_ani.mp4', title_frame = TRUE,
  interval = 1 / 12, ani.width = 1080, ani.height = 1080)
pbPost('note', 'R is done!')

# txmean

rec_txa =
  # get the netcdf into a data frame
  tidync(
    here('analysis', 'data', 'record-ts', 'monthly-TXmean-records.nc')) %>%
  activate('hot_record_time') %>%
  hyper_tibble() %T>%
  # tidy up a little
  print() %>%
  mutate(record = as.logical(hot_record_time)) %>%
  select(-hot_record_time) %>%
  arrange(time) %>%
  # cell-by-cell: find the time since the last record
  group_by(longitude, latitude) %>%
  mutate(last_record = if_else(record, true = time, false = NA_integer_)) %>%
  fill(last_record) %>%
  mutate(
    record_age = time - last_record,
    record_age_clamped = case_when(
      record_age > 120 ~ NA_integer_,
      TRUE ~ record_age
    )) %>%
  select(-last_record) %>%
  ungroup() %>%
  # convert time column to actual dates. assume since jan 1950 (check!)
  mutate(date = as.Date('1950-01-15') + months(time - 1)) %T>%
  print()

rec_txa_plot =
  rec_txa %>%
  ggplot() +
  geom_polygon(
    data = aus,
    mapping = aes(x = long, y = lat, group = group),
    fill = '#cccccc', colour = '#999999') +
  geom_tile(
    aes(x = longitude, y = latitude, frame = date, alpha = record_age_clamped),
    fill = 'red') +
  # scale_fill_gradient(low = '#ff0000ff', high = '#33333300', na.value = '#ffffff00') +
  scale_alpha_continuous(range = 1:0, na.value = 0) +
  coord_fixed(ratio = 1) +
  labs(
    x = 'Longitude',
    y = 'Latitude',
    fill = 'Months since\nrecord',
    title = 'Months since TXmean record broken in grid cell as of ') +
  theme_minimal() +
  theme(
    legend.position = 'bottom',
    legend.direction = 'horizontal')

gganimate(rec_txa_plot,
  filename = '~/Desktop/rec_txmean_ani.mp4', title_frame = TRUE,
  interval = 1 / 12, ani.width = 1080, ani.height = 1080)
pbPost('note', 'R is done!')