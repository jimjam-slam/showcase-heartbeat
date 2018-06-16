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
      theme(
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.y = element_line(colour = "#666666"),
        axis.title.x = element_text(colour = 'white', margin = margin(t = 7)),
        axis.text = element_text(colour = "#666666"),
        plot.title = element_text(colour = 'white')) +
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