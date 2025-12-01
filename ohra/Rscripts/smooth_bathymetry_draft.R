library(pygetmtools)
library(ncdf4)

setwd("/home/muhammed/mews/ohra_smoothed2/Bathymetry//")


nc <- nc_open("bathymetry.nc")
mat <- read_bathy_as_matrix("bathymetry_smoothed_jorrit.nc")
plot_bathy(mat)


plot_interactive_bathymetry("bathymetry_smoothed_jorrit.nc")

#read_coord_maintain_file() csv file with x and  y coordinates of points of interest to keep as per origignal depth 

pts <- data.table(ind_x= c(43,33), ind_y = c(46,40))

mat_snoothed <- smooth_bathy_matrix(mtrx = mat,
                    maintain_coords = pts,
                    max_val = 0.2,
                    method="rx0")
#

mat_snoothed_local <- smooth_bathy_matrix(mtrx = mat,
                                    maintain_coords = pts,
                                    max_val = 0.2,
                                    method="rx0",
                                    global_smoothing = F)
#

mat_snoothed_local_v <- smooth_bathy_matrix(mtrx = mat,
                                          maintain_coords = pts,
                                          max_val = 0.1,
                                          method="rx0",
                                          global_smoothing = F,
                                          max_vol_adj_step_local = 15
                                          )
plot_bathy(mat_snoothed, maintain_coords = pts)

plot_bathy(mat)
plot_bathy(mat_snoothed_local, maintain_coords = pts)

plot_bathy(mtrx = mat_snoothed, mtrx_ref = mat)
plot_bathy(mtrx = mat_snoothed_local, mtrx_ref = mat)
plot_bathy(mtrx = mat_snoothed_local_v, mtrx_ref = mat)
plot_bathy(mtrx = mat_snoothed_local_v, mtrx_ref = mat_snoothed)

add_bathy_to_ncdf(mtrx = mat_snoothed_local_v, ncdf = "bathymetry_smoothed_jorrit.nc", depth_name_new = "bathymetry_rx01_local_v")
