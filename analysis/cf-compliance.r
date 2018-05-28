library(ncdf4)
library(here)
library(tidyverse)
library(stringr)

txx = nc_open(here('analysis', 'data', 'index-ts','txx.nc'))
gt37 = nc_open(
  here('analysis', 'data', 'days-above-T', 'Number_of_days_above_37degC.nc'),
  write = TRUE)

# get time values from txx file, amnd change all the days to the 15th
# (dts are stored as numerics representing YYMMDD... whhhhyyy)
txx_timevals =
  ncvar_get(txx, varid = 'time') %>%
  as.character()
str_sub(txx_timevals, start = 7, end = 8) = '15'
txx_timevals = txx_timevals %>% as.numeric()

# create new variable and write it with modified time values to gt37
gt37_time = ncvar_def('time', 'day as %Y%m%d.%f', gt37$dim$time,
  missval = NA, longname = 'Time')
gt37 = ncvar_add(gt37, gt37_time)
ncvar_put(gt37, varid = 'time', txx_timevals, start = 1, count = -1)

# may need to use cdo to copy file with the -r flag to change dates to
# 'days since X' instead!