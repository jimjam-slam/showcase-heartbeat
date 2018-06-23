# convert monthly area-averaged mean time series to csv
# (to feed into d3.js)

library(tidyverse)
library(tidync)
library(lubridate)
library(viridis)
library(magrittr)
library(here)
library(grid)
library(gridExtra)
library(gridSVG)

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
      labels = c('JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'),
      ordered = TRUE),
    dt_ym = format(dt, '%Y-%m')) %>%
  filter(year > 1939) %>%
  select(dt, year, summer, month, month_fac, count = tmin) %>%
  # select(dt, year, summer, month, month_fac, dt_ym, count = tmin) %>%
  write_csv('monthly_ts.csv')

hb_theme = theme(
  panel.grid.major.x = element_blank(),
  panel.grid.minor.x = element_blank(),
  panel.grid.minor.y = element_blank(),
  panel.grid.major.y = element_line(colour = "#666666"),
  axis.title.x = element_text(colour = 'white', margin = margin(t = 7)),
  axis.text = element_text(colour = "#666666"),
  plot.subtitle = element_text(colour = '#666666'),
  plot.title = element_text(colour = '#999999'))

mts_ann = 
  mts %>%
  group_by(year) %>%
  summarise(count = sum(count)) %>%
  mutate(anomaly = count - mean(count))

mts_barplot =
  ggplot(mts_ann) +
    geom_col(
      aes(x = year, y = anomaly),
      fill = 'white', colour = NA, show.legend = FALSE) +
    theme_minimal(base_family = 'Oswald', base_size = 14) +
    hb_theme +
    labs(
      x = 'YEAR',
      y = NULL,
      title = 'MONTHLY NIGHTS OVER 20 °C',
      subtitle = 'RELATIVE TO THE 1940–2013 AVERAGE')

# ggplot alters the order of the bars before plotting: negative bars are ordered
# before positive ones. i've manually sorted the data here, but in future i can
# use ggplot_build(mts_barplot)$data to safely get the order ggplot2 used.
mts_ann_sorted =
  mts_ann %>%
  mutate(is_positive = anomaly > 0) %>%
  arrange(is_positive, year)

# finally, garnish the svg elements and export the whole thing out
barplot_grob = mts_barplot %>% ggplotGrob() %>% grid.force()
dev.new(width = 8, height = 4.5, units = 'in')
grid.draw(barplot_grob)
grid.garnish('geom_rect',
  'class' =
    paste0('chart_bar_', if_else(mts_ann_sorted$is_positive, 'pos', 'neg')),
  'data-year' = mts_ann_sorted$year,
  'data-count' = mts_ann_sorted$count,
  'data-anomaly' = mts_ann_sorted$anomaly,
  'data-positive' = mts_ann_sorted$is_positive,
  group = FALSE, grep = TRUE, redraw = TRUE)
grid.export('ts_bar_garnished_sorted.svg', strict = FALSE)

# fyi: i needed to manually paste my svg's css file (containing transition
# states) into the file inside <style></style> tags
