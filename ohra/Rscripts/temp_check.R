# Load necessary libraries
library(pygetmtools)
library(ggplot2)
library(dplyr)
library(lubridate)

# Set working directory
setwd("/home/muhammed/mews/ohra/")

# Read observation data
#obs <- read.csv("/home/muhammed/Projects/Mews_Data_Ohra/Processed_data/Temp_profiles.csv")
obs <- read.csv("/home/muhammed/Projects/Mews_Data_Ohra/Processed_data/Processed_obs_data/Profiles_Nutrients/csv_mg_per_l/Ohra_Temperature_2015-2024.csv")
names(obs)[1] <- "Datetime"
names(obs)[3] <- "Temp"

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

# Define the point of interest
my_point <- c(x = 4409749, y = 5626252)

# Generate file paths for each month
file_paths <- sprintf("2021%02d01/ohra_3d.nc", 4:7)

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
my_temp_st$x <- round(my_temp_st$x, 0)
my_temp_st$y <- round(my_temp_st$y, 0)
my_temp_bt$x <- round(my_temp_bt$x, 0)
my_temp_bt$y <- round(my_temp_bt$y, 0)

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
  labs(title = "Surface Temperature", x = "Date", y = "Temperature", color = "Legend") +
  theme_bw() +
  scale_color_manual(values = c("Modeled" = "blue", "Observed" = "red")) +
  theme(legend.position = "bottom")


# Create ggplot for bottom temperatures
p_bottom <- ggplot(bottom_data, aes(x = date)) +
  geom_line(aes(y = Modeled_Temp, color = "Modeled"), size = 1) +
  geom_point(aes(y = Observed_Temp, color = "Observed"), size = 2) +
  labs(title = "Bottom Temperature", x = "Date", y = "Temperature", color = "Legend") +
  theme_bw() +
  scale_color_manual(values = c("Modeled" = "blue", "Observed" = "red")) +
  theme(legend.position = "bottom")


# Display the plot
print(p_surface)
print(p_bottom)

# Save the plot
# Save the plots
ggsave("surface_temperature_fixed.png", plot = p_surface, width = 10, height = 6)
ggsave("bottom_temperature_fixed.png", plot = p_bottom, width = 10, height = 6)

################



# Filter observation data for the year 2021
obs_2021 <- obs %>%
  filter(year(Datetime) == 2021)

# Create surface temperature data frame for 2021
surface_temp_2021 <- obs_2021 %>%
  group_by(Datetime) %>%
  filter(Depth == min(Depth)) %>%
  ungroup() %>%
  select(Datetime, Temp) %>%
  rename(Surface_Temp = Temp)

# Create bottom temperature data frame for 2021
bottom_temp_2021 <- obs_2021 %>%
  group_by(Datetime) %>%
  filter(Depth == max(Depth)) %>%
  ungroup() %>%
  select(Datetime, Temp) %>%
  rename(Bottom_Temp = Temp)

# Merge surface and bottom temperature data frames
temp_diff_2021 <- inner_join(surface_temp_2021, bottom_temp_2021, by = "Datetime") %>%
  mutate(Temp_Diff = Surface_Temp - Bottom_Temp)

# Plot the temperature differences using ggplot2
p_temp_diff <- ggplot(temp_diff_2021, aes(x = Datetime, y = Temp_Diff)) +
  geom_point(color = "blue", size = 1) +
  labs(title = "Surface vs Bottom Temperature Difference (2021)", x = "Date", y = "Temperature Difference (°C)") +
  theme_bw() +
  theme(legend.position = "none")

# Display the plot
print(p_temp_diff)

# Save the plot
ggsave("temperature_difference_2021.png", plot = p_temp_diff, width = 10, height = 6)

