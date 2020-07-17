#Resources_TidyT_32 -------------------------------------------------------------
https://github.com/rfordatascience/tidytuesday/blob/master/README.md
https://github.com/rfordatascience/tidytuesday/tree/master/data/2018-11-06
https://tidyr.tidyverse.org/reference/replace_na.html

# libraries -----------------------------------------------------------------
library(tidyverse)
library(tmaptools)
library(tmap)
library(rnaturalearth)
library(sf)
library(spdplyr)

# load_data ---------------------------------------------------------------
url <- c("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2018-11-06/us_wind.csv")
# This line needs to be run only once:
download.file(url, destfile = "Data/us_wind.csv")
# Run only this once data are downlaoded:
us_wind <- read_csv("Data/us_wind.csv")

# explore_data --------------------------------------------------------------
dim(us_wind) # 24 columns and 58k of rows
head(us_wind) # The file looks cleanish but some variables are labeled as "missing"
glimpse(us_wind) # seems to be coerced fine...
# Test if there are any NAs:
sum(is.na(us_wind)) # results in zero but there are some weird values...



# Plotting all "character" columns ----------------------------------------
# Looking at all categorical data is better via a simple summary
# There are 10 categorical or character data
us_wind %>%
  select_if(funs(is.character)) %>%
  gather(key = "var_name", value = "var_content") %>%
  group_by(var_name, var_content) %>%
  summarise(total = n())
# I can use %>% View() to explore the values more closely

# We can see how many times missing occurs using the following lines
us_wind %>%
  select_if(funs(is.character)) %>%
  gather(key = "var_name", value = "var_content") %>%
  group_by(var_name, var_content) %>%
  summarise(total = n()) %>%
  arrange(desc(total)) %>% 
  filter(var_content == "missing") # Five out of ten have missing values


# Looking at this visually, it's better to use some cut-off value on total to reduce overplotting.
us_wind %>%
  select_if(funs(is.character)) %>%
  gather(key = "var_name", value = "var_content") %>%
  group_by(var_name, var_content) %>%
  summarise(total = n()) %>%
  arrange(desc(total)) %>% 
  filter(total > 500) %>%
  ggplot(., aes(x = var_content, y = total)) +
  geom_bar(stat = "identity") +
  facet_wrap(~var_name, scales = "free")
# faa_asn, faa_ors is just missing and we see the "missing" label in other columns too.
# It's clear we'll need to relabel "missing" as NA



# Plotting all "numeric" columns ------------------------------------------
# Takes a while as I am using the whole data
# There are 14 numerical columns
us_wind %>%
  select_if(funs(is.numeric)) %>%
  gather(key = "var_name", value = "var_content") %>%
  ggplot(., aes(x = var_content)) +
  geom_histogram() +
  facet_wrap(~var_name, scales = "free")
# The obvious pattern is that some values (particularly those at -10 000) are represented quite a few times.

# We can see the occurence of -9999 using the lines below...
us_wind %>%
  select_if(funs(is.numeric)) %>%
  gather(key = "var_name", value = "var_content", -case_id) %>%
  group_by(var_name, var_content) %>%
  summarise(total = n()) %>%
  filter(total > 500) %>%
  arrange(desc(total)) %>%
  filter(var_content == "-9999") # 7 out of 14 columns contains -9999


# Without going into too much detail I can clearly see that half of categorical data are using labels "missing"
# and half of numerical data are using label "-9999". After re-labeling these values as NAs, I can check if
# there are other missing values.


# Relabel_missing_values --------------------------------------------------
# "-9999" and "missing"
us_wind_NA <-  us_wind %>%
  mutate_all(funs(na_if(., "missing"))) %>%
  mutate_all(funs(na_if(.,"-9999")))

# Check number of NA
sum(is.na(us_wind_NA)) # 93324


# Visualise_without_NAs ----------------------------------------------------
# Categorical 
us_wind_NA %>%
  select_if(funs(is.character)) %>%
  gather(key = "var_name", value = "var_content") %>%
  group_by(var_name, var_content) %>%
  summarise(total = n()) %>%
  arrange(desc(total)) %>% 
  filter(total > 100) %>%
  filter_all(all_vars(!is.na(.))) %>% # Exclude all NAs
  ggplot(., aes(x = var_content, y = total)) +
  geom_bar(stat = "identity") +
  facet_wrap(~var_name, scales = "free")
# I have decreased the total number. The NAs are removed but what seems to be the case now
# is that some values are represented much more than others. I can plot the most common ones
# and check if there's anything strange.
us_wind_NA %>%
  select_if(funs(is.character)) %>%
  gather(key = "var_name", value = "var_content") %>%
  group_by(var_name, var_content) %>%
  summarise(total = n()) %>%
  arrange(desc(total)) %>% 
  filter_all(all_vars(!is.na(.))) %>% # Exclude all NAs
  filter(total == max(total)) # Show most occuring values only
# The only one that might be intuitively strange is "unknown Tehachapi Wind Resource Area 1"
# Probablu could be relabeled as "unknown"


# Numerical
us_wind_NA %>%
  select_if(funs(is.numeric)) %>%
  gather(key = "var_name", value = "var_content") %>%
  filter_all(all_vars(!is.na(.))) %>% # Exclude all NAs
  ggplot(., aes(x = var_content)) +
  geom_histogram() +
  facet_wrap(~var_name, scales = "free")
# After removing all NAs, numerical columns look fine on the first glance.


# Plot_map -----------------------------------------------------------
# Summarise number of power plants from the dataset, exclude missing vars
map_us_wind <- us_wind_NA %>%
  mutate(t_state = paste0("US-", t_state)) %>% # Ensures state columns are identical
  filter_all(all_vars(!is.na(.))) %>% # Removes NAs
  group_by(t_state) %>% # Groups by state
  summarise(N_of_Wind = n()) %>% # Total N
  ungroup() # Removes grouping

# Get shapefile of USA using natural earth database
usa <- ne_states(country = "United States of America")

# Get raster of the same
data("land") # Load data from tmap


# I need only States, not all of USA. I am using iso_3166_2 to get only
# the states I need. This is quite crude method but I did not figure out
# how to do it differently.

# The method relies on package spdplyr for manipulating shapefiles.
states_fortyeight <- c("US-AL", "US-AZ", "US-AR", "US-CA", "US-CO", "US-CT", "US-DE", "US-FL", "US-GA", "US-ID", "US-IL", "US-IN", "US-IA", "US-KS", "US-KY", "US-LA", "US-ME", "US-MD", "US-MA", "US-MI", "US-MN", "US-MS", "US-MO", "US-MT", "US-NE", "US-NV", "US-NH", "US-NJ", "US-NM", "US-NY", "US-NC", "US-ND", "US-OH", "US-OK", "US-OR", "US-PA", "US-RI", "US-SC", "US-SD", "US-TN", "US-TX", "US-UT", "US-VT", "US-VA", "US-WA", "US-WV", "US-WI", "US-WY")
usa <- usa %>% filter(iso_3166_2 %in% states_fortyeight) %>% 
  left_join(., map_us_wind, by = c("iso_3166_2" = "t_state")) # Merge with wind total

# crop shap is from tmap tools
usa_raster_crop <- crop_shape(land, usa) # get only selection of raster

# Save USA raster
usa_raster_wind1 <- tm_shape(usa_raster_crop) +
  tm_raster("elevation", 
            palette = terrain.colors(10),
            title = "Elevation") +
  tm_credits("TidyTuesday 32",
             position = c("left", "bottom")) +
  tm_layout(title = "Wind Turbines in US", 
            title.position = c("left", "top"),
            legend.position = c("right", "bottom"), 
            frame = FALSE)

# Save USA Wind poly
usa_poly_wind2 <- tm_shape(usa) +
  tm_polygons("N_of_Wind", title = "Number of Wind Turbines", 
              palette = "-Blues")  + 
tm_layout(legend.position = c("right", "bottom"), 
          frame = FALSE)

# Combine both together and plot it.
tmap_arrange(usa_raster_wind1, usa_poly_wind2)
