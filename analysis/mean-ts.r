# convert monthly area-averaged mean time series to csv
# (to feed into d3.js)

library(tidyverse)
library(tidync)
library(libridate)
library(viridis)
library(gganimate)
library(magrittr)
library(here)

select = dplyr::select

mts =
  tidync(here(
    'analysis', 'data', 'days-above-compliant', 'tn_gt20_monthly_mean.nc')) %>%
  hyper_tibble() %>%
  mutate(
    dt = as.Date('1911-01-31') + days(time),
    month = month(dt),
    year = year(dt),
    summer = cut(dt,
      breaks = seq(
        from = as.Date('1910-07-01'),
        to = as.Date('2014-07-01'),
        by = 'year'), labels = FALSE) + min(year) - 2,
    month_fac = factor(month,
      levels = c(7:12, 1:6),
      labels = c('Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'),
      ordered = TRUE),
    dt_ym = format(dt, '%Y-%m')) %>%
  select(dt, year, summer, month, month_fac, count = tmin) %>%
  select(dt, year, summer, month, month_fac, dt_ym, count = tmin) %>%
  write_csv('monthly_ts.csv') %>%
  {
    ggplot(.) +
      geom_line(
        aes(x = month_fac, y = count, group = summer, colour = summer),
          # frame = summer, cumulative = TRUE),
        alpha = 0.75) +
      scale_colour_viridis(name = 'Summer') +
      theme_dark() +
      labs(
        x = 'Month',
        y = 'Nights over 20 °C',
        main = 'Monthly nights over 20 °C, ')
  } %>%
  # ggsave('monthly_ts.pdf', plot = .)
  gganimate('monthly_ts.mp4',
    interval = 0.5, ani.width = 1280, ani.height = 800)
