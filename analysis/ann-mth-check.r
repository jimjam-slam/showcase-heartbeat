library(tidyverse)
library(tidync)
library(lubridate)
library(here)

ann =
  tidync(here('analysis', 'data', 'days-above-compliant',
    'tn_gt20_annual_mean.nc')) %>%
  hyper_tibble() %>%
  rename(count = tmin) %>%
  mutate(
    dt = as.Date('1911-12-31') + days(time),
    year = year(dt)) %>%
  select(year, count)

mth =
  tidync(here('analysis', 'data', 'days-above-compliant',
    'tn_gt20_monthly_mean.nc')) %>%
  hyper_tibble() %>%
  rename(count = tmin) %>%
  mutate(
    dt = as.Date('1911-01-31') + days(time),
    year = year(dt)) %>%
  select(year, count)

mth_sum =
  mth %>%
  group_by(year) %>%
  summarise(count = sum(count))

joined =
  ann %>%
  left_join(mth_sum, by = 'year') %>%
  mutate(diff = count.x - count.y)

hist(joined$diff)    # all within +/- 5e-6, so just float precision. horray!