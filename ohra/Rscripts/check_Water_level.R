# Load necessary library
library(pygetmtools)

# Set working directory
setwd("/home/muhammed/mews/ohra_warm_new_years/")

# Define the point of interest
my_point <- c(x = 4409749, y = 5626252)

# Initialize a list to store the results
z_list <- list()

# Loop over the months
for (month in 1:12) {
  # Construct the file path
  file_path <- sprintf("2021%02d01/ohra_2d.nc", month)
  
  # Read the data
  x1 <- read_pygetm_output_2d(ncdf = file_path, var = "zt", round_val = 3L)
  x1$x <- round(x1$x, 0)
  x1$y <- round(x1$y, 0)
  
  # Extract the data for the point of interest
  z_list[[month]] <- x1[which(x1$x == my_point[1] & x1$y == my_point[2]), ]
}

# Bind the results together
z_combined <- do.call(rbind, z_list)[,c(1,4)]

# Print the combined result
print(z_combined)

z_combined <- z_combined[- which(duplicated(z_combined$date)),]
str(z_combined)



lvl <- read.csv("/home/muhammed/Downloads/water_level.csv")
lvl <- lvl[c(which(year(lvl$date)== 2021), which(year(lvl$date)== 2021)[length(which(year(lvl$date)== 2021))]+1),]


plot(z_combined$date, z_combined$zt, type = "l")

lines(z_combined$date, lvl$water_level-43.65, col=2)

llv_diff <-  z_combined$zt - (lvl$water_level-43.65)
plot(llv_diff, type = "l")
mean(llv_diff)


# Load necessary libraries
library(ggplot2)
library(dplyr)
library(lubridate)
library(viridis)
# Assuming z_combined and lvl are your data frames
# z_combined should have columns 'date' and 'zt'
# lvl should have columns 'date' and 'water_level'

# Combine the data into one data frame for plotting
combined_data <- z_combined %>%
  mutate(type = "GETM") %>%
  select(date, water_level = zt, type) %>%
  bind_rows(
    lvl %>%
      mutate(date = ymd(date)) %>%
      mutate(water_level = water_level - 43.65, type = "Observed") %>%
      select(date, water_level, type)
  )

# Create the combined plot
p <- ggplot(combined_data, aes(x = date, y = water_level, color = type)) +
  geom_line() +
  labs(title = "Modeled vs Observed Water Level", x = "Date", y = "Water Level", color = "Legend") +
  theme_minimal() +
  scale_color_manual(values = c("GETM" = "blue", "Observed" = "red"))


# Create the combined plot with colorblind-friendly palette
p <- ggplot(combined_data, aes(x = date, y = water_level, color = type)) +
  geom_line(size = 1) +
  labs(title = "Modeled vs Observed Water Level", x = "Date", y = "Water Level", color = "Legend") +
  theme_bw() +
  scale_color_viridis(discrete = TRUE, option = "plasma", begin = 0.6, end = 0.3) +
  theme(legend.position = "bottom")

p
# Save the plot
ggsave("combined_water_level.png", plot = p, width = 10, height = 6)
