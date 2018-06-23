# convert monthly area-averaged mean time series to csv
# (to feed into d3.js)

library(tidyverse)
library(tidync)
library(lubridate)
library(viridis)
library(gganimate)
library(magrittr)
library(here)
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

# # video output 
# mts %>%
#   {
#     ggplot(.) +
#       geom_line(
#         aes(x = month_fac, y = count, group = summer, colour = summer,
#           frame = summer, cumulative = TRUE),
#         alpha = 0.75) +
#       scale_colour_viridis(name = 'Summer') +
#       theme_dark() +
#       labs(
#         x = 'Month',
#         y = 'Nights over 20 °C',
#         main = 'Monthly nights over 20 °C, ')
#   } %>%
#   # ggsave('monthly_ts.pdf', plot = .)
#   gganimate('monthly_ts.html',
#     interval = 0.5, ani.width = 1280, ani.height = 800)

hb_theme = theme(
  panel.grid.major.x = element_blank(),
  panel.grid.minor.x = element_blank(),
  panel.grid.minor.y = element_blank(),
  panel.grid.major.y = element_line(colour = "#666666"),
  axis.title.x = element_text(colour = 'white', margin = margin(t = 7)),
  axis.text = element_text(colour = "#666666"),
  plot.subtitle = element_text(colour = 'white'),
  plot.title = element_text(colour = 'white'))

# static version with svg export
lineplot = mts %>%
  {
    ggplot(.) +
      geom_line(
        aes(x = month_fac, y = count, group = summer, colour = summer),
        show.legend = FALSE) +
      scale_colour_viridis(name = 'Summer') +
      # scale_alpha_continuous(range = c(0.1, 1)) +
      theme_minimal(base_family = 'Oswald', base_size = 14) +
      hb_theme +
      labs(
        x = 'MONTH',
        y = NULL,
        # y = 'NIGHTS OVER 20 °C',
        title = 'MONTHLY NIGHTS OVER 20 °C')
  }
dev.new(width = 8, height = 4.5, units = 'in')
lineplot
grid.export('ts_line_grid2.svg', addClasses = TRUE)

# barplot = mts %>%
#   {
#     ggplot(.) +
#       geom_col(
#         aes(x = summer, y= count, group = month_fac, fill = month_fac),
#         position = 'stack', show.legend = FALSE) +
#       theme_dark() +
#       labs(
#         x = 'Summer',
#         y = 'Nights over 20 °C',
#         main = 'Monthly nights over 20 °C, ')
#   }
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
      # y = 'NIGHTS OVER 20 °C',
      title = 'MONTHLY NIGHTS OVER 20 °C',
      subtitle = 'RELATIVE TO THE 1940–2013 AVERAGE')

# naive: just garnish as they appear in the source data frame
# (this doesn't work! the attributes don't atch the plot...)
barplot_grob = mts_barplot %>% ggplotGrob() %>% grid.force()
dev.new(width = 8, height = 4.5, units = 'in')
grid.draw(barplot_grob)
grid.garnish('rect',
  data_year = mts_ann$year,
  data_positive = mts_ann$anomaly > 0,
  group = FALSE, grep = TRUE, redraw = TRUE)
grid.export('ts_bar_garnished_naive.svg', strict = FALSE)

# okay, it looks like it's just negative bars coming before positive ones.
# verified that this works here, but in future i can use
# ggplot_build(mts_barplot)$data to get the geom order as processed by ggplot2.

mts_ann_sorted =
  mts_ann %>%
  mutate(is_positive = anomaly > 0) %>%
  arrange(is_positive, year)

barplot_grob = mts_barplot %>% ggplotGrob() %>% grid.force()
dev.new(width = 8, height = 4.5, units = 'in')
grid.draw(barplot_grob)
grid.garnish('geom_rect',
  "data-year" = mts_ann_sorted$year,
  "data-count" = mts_ann_sorted$count,
  "data-anomaly" = mts_ann_sorted$anomaly,
  "data-positive" = mts_ann_sorted$is_positive,
  group = FALSE, grep = TRUE, redraw = TRUE)
grid.export('ts_bar_garnished_sorted.svg', strict = FALSE)
