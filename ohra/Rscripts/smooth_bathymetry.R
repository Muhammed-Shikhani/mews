library(pygetmtools)
library(ncdf4)

setwd("/home/muhammed/mews/ohra_smoothed2/Bathymetry//")


#nc <- nc_open("bathymetry.nc")
mat <- read_bathy_as_matrix("bathymetry.nc")
plot_bathy(mat)


plot_interactive_bathymetry("bathymetry.nc")

#read_coord_maintain_file() csv file with x and  y coordinates of points of interest to keep as per origignal depth 

pts <- data.table(ind_x= c(43,33), ind_y = c(46,40))

# mat_snoothed <- smooth_bathy_matrix(mtrx = mat,
#                     maintain_coords = pts,
#                     max_val = 0.2,
#                     method="rx0")
# #
# 
# mat_snoothed_local <- smooth_bathy_matrix(mtrx = mat,
#                                     maintain_coords = pts,
#                                     max_val = 0.2,
#                                     method="rx0",
#                                     global_smoothing = F)
# #

mat_smoothed_local_v <- smooth_bathy_matrix(mtrx = mat,
                                          maintain_coords = pts,
                                          max_val = 0.1,
                                          method="rx0",
                                          track_volume = T,
                                          global_smoothing = F,
                                          max_vol_adj_step_local = 18
                                          )
plot_bathy(mtrx = mat_smoothed_local_v, mtrx_ref = mat)

plot_bathy(mat)
plot_bathy(mat_smoothed_local_v, maintain_coords = pts)

plot_bathy(mat, maintain_coords = pts)

file.copy(from="bathymetry.nc", to ="bathymetry_smoothed_local_v.nc" )
add_bathy_to_ncdf(mtrx = mat_smoothed_local_v, ncdf = "bathymetry_smoothed_local_v.nc", depth_name_new = "bathymetry_rx01_local_v")
