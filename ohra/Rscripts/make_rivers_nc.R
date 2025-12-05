library(pygetmtools)

setwd("/home/muhammed/mews/ohra/Rivers/dat/")
inflow <- read.table("Inflow_Gerastollen.dat", sep="\t", header = T)[,-6]
names(inflow) <- c("date", "flow", "temp","selmaprotbas_nn", "selmaprotbas_po","selmaprotbas_ddp", "selmaprotbas_pw")
write.table(inflow,"Inflow_Gerastollen.dat", quote = F, row.names = F, sep="\t")

create_inflow_nc_from_csv(filename = "Inflow_Gerastollen.dat",
                          lat = 50.74894,
                          lon = 10.72226,
                          file_out = "Inflow_Gerastollen.nc",
                          timestep = "1 day")





my_files <- list.files()

create_inflow_nc_from_csv(filename = "Inflow_Gerastollen.dat",
                          lat = 50.74894,
                          lon = 10.72226,
                          file_out = "Inflow_Gerastollen.nc",
                          timestep = "1 day")


create_inflow_nc_from_csv(filename = "Inflow_Silbergraben.dat",
                          lat = 50.74894,
                          lon = 10.72226,
                          file_out = "Inflow_Silbergraben.nc",
                          timestep = "1 day")



create_inflow_nc_from_csv(filename = "Inflow_Kernwasser.dat",
                          lat = 50.7581,
                          lon = 10.69327,
                          file_out = "Inflow_Kernwasser.nc",
                          timestep = "1 day")



create_inflow_nc_from_csv(filename = "Inflow_Schmalwasser.dat",
                          lat = 50.75887,
                          lon = 10.69465,
                          file_out = "Inflow_Schmalwasser.nc",
                          timestep = "1 day")



create_inflow_nc_from_csv(filename = "Inflow_Ungauged.dat",
                          lat = 50.76307,
                          lon = 10.71674,
                          file_out = "Inflow_Ungauged.nc",
                          timestep = "1 day")



inflow <- read.table("outflow.dat", sep="\t", header = T)
names(inflow) <- c("date", "flow")
write.table(inflow,"outflow.dat", quote = F, row.names = F, sep="\t")

create_inflow_nc_from_csv(filename = "outflow.dat",
                          lat = 50.76459,
                          lon = 10.72019,
                          file_out = "Outflow.nc",
                          timestep = "1 day")

setwd("/home/muhammed/mews/ohra/Bathymetry//")
mat <- read_bathy_as_matrix("bathymetry.nc",var_name = "bathymetry")
lat <- read_bathy_as_matrix("bathymetry.nc",var_name = "lat")
lon <- read_bathy_as_matrix("bathymetry.nc",var_name = "lon")
plot_interactive_bathymetry("bathymetry.nc")



setwd("/home/muhammed/mews/ohra_smoothed2/Rivers/dat/")


create_inflow_nc_from_csv(filename = "Inflow_Kernwasser.dat",
                          lat = lat[5,30],
                          lon = lon[5,30],
                          file_out = "Inflow_Kernwasser.nc",
                          timestep = "1 day")




create_inflow_nc_from_csv(filename = "Inflow_Schmalwasser.dat",
                          lat = lat[5,30],
                          lon = lon[5,30],
                          file_out = "Inflow_Schmalwasser.nc",
                          timestep = "1 day")



create_inflow_nc_from_csv(filename = "Inflow_Ungauged.dat",
                          lat = lat[37,42],
                          lon = lon[37,42],
                          file_out = "Inflow_Ungauged.nc",
                          timestep = "1 day")




create_inflow_nc_from_csv(filename = "outflow.dat",
                          lat = lat[41,46],
                          lon = lon[41,46],
                          file_out = "Inflow_Outflow.nc",
                          timestep = "1 day")






