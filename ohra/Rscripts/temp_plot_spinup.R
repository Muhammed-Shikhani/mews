# Load necessary libraries
library(pygetmtools)
library(ggplot2)
library(dplyr)
library(lubridate)

# Set working directory
setwd("/home/muhammed/mews/ohra_spinup/")

# Read observation data
obs <- read.csv("/home/muhammed/Projects/Mews_Data_Ohra/Processed_data/Temp_profiles.csv")

# Convert Datetime to POSIXct format for easier manipulation
obs$Datetime <- ymd_hms(paste0(obs$Datetime, " 12:00:00"))

# Create surface temperature data frame
surface_temp <- obs %>%
  group_by(Datetime) %>%
  filter(Depth == min(Depth)) %>%
  ungroup() %>%
  select(Datetime, Temp) %>%
  rename(Surface_Temp = Temp)

# Create bottom temperature data frame
bottom_temp <- obs %>%
  group_by(Datetime) %>%
  filter(Depth == max(Depth)) %>%
  ungroup() %>%
  select(Datetime, Temp) %>%
  rename(Bottom_Temp = Temp)

# Generate file paths for each month
# Generate years and months
years <- 2017:2021
months <- 1:12

# Create all combinations of year and month
ym <- expand.grid(year = years, month = months)

# Create the file paths
file_paths <- sprintf("%d%02d01/ohra_3d.nc", ym$year, ym$month)
# Read surface temperature data (z = 19)
my_temp_st <- read_multiple(
  ncdfs = file_paths,
  var = "temp",
  z = 19,
  save_everything = FALSE,
  round_depth = 2L,
  round_val = 3L
)

# Read bottom temperature data (z = 0)
my_temp_bt <- read_multiple(
  ncdfs = file_paths,
  var = "temp",
  z = 0,
  save_everything = FALSE,
  round_depth = 2L,
  round_val = 3L
)

# Round coordinates to match the point of interest
my_temp_st$x <- as.integer(round(my_temp_st$x, 0))
my_temp_st$y <- as.integer(round(my_temp_st$y, 0))
my_temp_bt$x <- as.integer(round(my_temp_bt$x, 0))
my_temp_bt$y <- as.integer(round(my_temp_bt$y, 0))


# Define the point of interest

the_point <- c(x = 4409749, y = 5626252)

# Calculate Euclidean distance to all points in my_temp_st
distances <- sqrt((my_temp_st$x - the_point[1])^2 + (my_temp_st$y - the_point[2])^2)

# Find the index of the closest point
closest_index <- which.min(distances)

# Optional: Get the closest point's coordinates
closest_point <- my_temp_st[closest_index, ]

# Print results
print(closest_index)
print(closest_point)

my_point <- c(closest_point$x, closest_point$y)


# Filter data for the point of interest
my_temp_point_st <- my_temp_st %>%
  filter(x == my_point[1], y == my_point[2])

my_temp_point_bt <- my_temp_bt %>%
  filter(x == my_point[1], y == my_point[2])

# Combine modeled and observed data for surface temperatures
surface_data <- my_temp_point_st %>%
  rename(Modeled_Temp = temp) %>%
  select(date, Modeled_Temp) %>%
  left_join(surface_temp, by = c("date" = "Datetime")) %>%
  rename(Observed_Temp = Surface_Temp)

# Combine modeled and observed data for bottom temperatures
bottom_data <- my_temp_point_bt %>%
  rename(Modeled_Temp = temp) %>%
  select(date, Modeled_Temp) %>%
  left_join(bottom_temp, by = c("date" = "Datetime")) %>%
  rename(Observed_Temp = Bottom_Temp)

# Create ggplot for surface temperatures
# Create ggplot for surface temperatures with a visible legend
p_surface <- ggplot(surface_data, aes(x = date)) +
  geom_line(aes(y = Modeled_Temp, color = "Modeled"), size = 1) +
  geom_point(aes(y = Observed_Temp, color = "Observed"), size = 2) +
  labs(title = "Surface Temperature Spinup", x = "Date", y = "Temperature", color = "Legend") +
  theme_bw() +
  scale_color_manual(values = c("Modeled" = "blue", "Observed" = "red")) +
  theme(legend.position = "bottom")


# Create ggplot for bottom temperatures
p_bottom <- ggplot(bottom_data, aes(x = date)) +
  geom_line(aes(y = Modeled_Temp, color = "Modeled"), size = 1) +
  geom_point(aes(y = Observed_Temp, color = "Observed"), size = 2) +
  labs(title = "Bottom Temperature Spinup", x = "Date", y = "Temperature", color = "Legend") +
  theme_bw() +
  scale_color_manual(values = c("Modeled" = "blue", "Observed" = "red")) +
  theme(legend.position = "bottom")


# Display the plot
print(p_surface)
print(p_bottom)

# Save the plot
# Save the plots
ggsave("surface_temperature_spinup.png", plot = p_surface, width = 10, height = 6)
ggsave("bottom_temperature_spinup.png", plot = p_bottom, width = 10, height = 6)

################
# Create a data frame with date, surface temperature, and bottom temperature
# Ensure one unique row per date for each dataset
st_unique <- my_temp_point_st %>%
  select(date, Surface_Temp = temp) %>%
  distinct(date, .keep_all = TRUE)

bt_unique <- my_temp_point_bt %>%
  select(date, Bottom_Temp = temp) %>%
  distinct(date, .keep_all = TRUE)

# Perform the join without triggering many-to-many warning
modeled_temp_data <- inner_join(st_unique, bt_unique, by = "date")

# Save to CSV
write.csv(modeled_temp_data, "modeled_surface_bottom_temperature_spinup.csv", row.names = FALSE)

# Combine modeled surface and bottom temperature data into a single data frame
modeled_temp_diff <- modeled_temp_data %>% 
  mutate(Temp_Diff = Surface_Temp - Bottom_Temp)

# Plot the modeled temperature difference using ggplot2
p_modeled_temp_diff <- ggplot(modeled_temp_diff, aes(x = date, y = Temp_Diff)) +
  geom_line(color = "darkgreen", size = 1) +
  labs(title = "Modeled Surface vs Bottom Temperature Difference Spinup",
       x = "Date", y = "Temperature Difference (°C)") +
  theme_bw() +
  theme(legend.position = "none")

# Display the plot
print(p_modeled_temp_diff)


# Save the plot
ggsave("modeled_temperature_difference_Spinup.png", plot = p_modeled_temp_diff, width = 10, height = 6)
