# some useful cdo commands


# turn annualcounts into decadal averages of annual accounts
# (10 years per aggregation, skip 43 years first to start from 1954)
cdo timselmean,10,43 tn_gt20_annual.nc tn_gt20_decadalmean.nc