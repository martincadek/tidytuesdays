# Virtual environment -----------------------------------------------------
# https://rstudio.github.io/renv/articles/renv.html
# install.packages("renv")
# renv::init() #  to initialize a new project-local environment with a private R library
# renv::snapshot() # to save the state of your project to renv.lock; and
# renv::restore() # to restore the state of your project from renv.lock.


# SETUP -------------------------------------------------------------------
# Packages
pkgs <- c("tidyverse", "tidymodels", "here", "Cairo", "colorspace",
          "janitor", "showtext", "rlang", "patchwork", "ggthemes", 
          "lubridate", "flextable", "tidytext", "arrow", "klaR", 
          "tidytuesdayR", "ggimage", "rsvg", "conflicted", "viridis",
          "renv", "ggrepel")
# install.packages(pkgs)


invisible(lapply(pkgs, library, character.only = TRUE))
conflict_prefer("filter", "dplyr")
conflict_prefer("select", "dplyr")
conflict_prefer("modify", "purrr")

# Note - if the following error occurs run the source again:
# Error: [conflicted] `modify` found in 2 packages.
# Either pick the one you want with `::` 


# Set theme
default_theme <- theme_clean() + # requires ggplot
     theme(
       # text = element_text(family = "Nunito"),
       axis.text.x = element_text(angle = 90, hjust = 0.5, vjust = 0.5),
       plot.background = element_blank()
       )

dark_theme <- function(...) {
    theme(
      # text = element_text(family = "Nunito"),
      legend.text = element_text(color = "white"),
      legend.background = element_rect(fill = "#1e1e1e", color = "#1e1e1e"),
      legend.key = element_rect(fill = "#1e1e1e"),
      title = element_text(colour = "white"),
      axis.text = element_text(color = "white"), 
      axis.line = element_line(color = "white"), 
      axis.line.x.bottom = element_blank(),
      axis.line.y.left = element_blank(),
      axis.title = element_text(color = "white"),
      axis.ticks = element_blank(),
      panel.border = element_blank(),
      panel.background = element_blank(),
      plot.background = element_rect(fill = "#1e1e1e", color = "#1e1e1e"),
      strip.background = element_rect(fill = "#1e1e1e"),
      strip.text = element_text(colour = "white"),
      ...
      )
  }

old_theme <- theme_gray() # in case I need to revert back to original theme

theme_set(default_theme)

# Colours
c_blue <- "#2D98D9"
c_red <- "#DE6B97"
c_orange <- "#BF8521"
c_green <- "#59A229"

# Fonts
# Source: https://fonts.google.com/featured/Superfamilies
# font_add_google("Nunito", "Nunito")
# font_families()
# showtext_auto()

# Graphical device
# options("device" = "windows")
# options("device")
# options("device" = "RStudioGD")
# knitr::opts_knit$set(dev.args = list(type = "cairo"))
trace(grDevices::png, quote({
  if (missing(type) && missing(antialias)) {
    type <- "cairo-png"
    antialias <- "subpixel"
  }
}), print = FALSE)

options(scipen = 999)

# LOAD DATA ---------------------------------------------------------------
tt_cocktails <- tidytuesdayR::tt_load(x = "2020-05-26", download_files = "cocktails")
data <- tt_cocktails$cocktails
data <- data %>%
  select(-c(iba, video)) # drop iba and video columns with lot of NAs

#write_rds(x = data, path = here("data/raw/cocktails.rds"))

# * 1 * PART --------------------------------------------------------------

# EDA ---------------------------------------------------------------------

# Explore data ------------------------------------------------------------
glimpse(data)
table(data.frame(unlist(sapply(data, class))))

# Show NA
data %>% summarise_all(~sum(is.na(.)))

# Remove NA
# data <- data %>%
#      select(-c(iba, video)) # drop iba and video columns

# Create temporary data frame for EDA visualisation
t_categorical <- data %>% 
  select_if(list(Negate(is.numeric))) %>% 
  select(-date_modified) %>%
  mutate_all(as.factor)

t_numerical <- data %>% 
  select_if(Negate(is.character))

ingr_per_cocktail <- t_numerical %>% select(id_drink) %>% group_by(id_drink) %>% count() %>% pull(n)

# Visualise Numerical
summary(t_numerical, maxsum = 10)

ingr_per_drinks <- t_numerical %>%
  count(id_drink) %>%
  mutate(id_drink = as.factor(id_drink)) %>% 
  pull(n) %>% table() %>% as_tibble()

gg_id_drink1 <- t_numerical %>%
  count(id_drink) %>%
  mutate(id_drink = as.factor(id_drink)) %>% 
  slice_max(n = 20, order_by = n) %>%
  ggplot(aes(x = fct_reorder(id_drink, n,  .desc = TRUE), y = n)) +
  geom_col() +
  scale_y_continuous(n.breaks = 12) +
  labs(title = "The ingredient-heavy drinks (grouped by drink id)", x = NULL, y = NULL)

gg_id_drink2 <- t_numerical %>%
  count(id_drink) %>%
  mutate(id_drink = as.factor(id_drink)) %>% 
  slice_min(n = 1, order_by = n) %>%
  ggplot(aes(x = fct_reorder(id_drink, n,  .desc = FALSE, ), y = n)) +
  geom_col() +
  scale_y_continuous(n.breaks = 2) +
  labs(title = "The ingredient-light drinks (grouped by drink id)", x = NULL, y =
         NULL)

gg_ingr <- t_numerical %>%
  distinct(id_drink, ingredient_number) %>%
  ggplot(aes(x = ingredient_number)) +
  geom_histogram(bins = 12) +
  scale_x_continuous(n.breaks = 12) +
  labs(title = "Frequency of ingredient order", x = NULL, y = NULL)

gg_date <- t_numerical %>%
  select(date_modified) %>%
  mutate(date_modified = ymd_hms(date_modified)) %>%
  ggplot(aes(x = date_modified)) +
  geom_histogram() +
  scale_x_datetime(date_breaks = "1 month") +
  labs(title = "Dates", x = NULL, y = NULL)

(gg_id_drink1 / gg_id_drink2) + 
  plot_annotation(caption = "by @m_cadek; #TidyTuesday 2020") & 
  dark_theme() 

(gg_ingr + gg_date) + 
  plot_annotation(caption = "by @m_cadek; #TidyTuesday 2020") &  
  dark_theme()

# Visualise Categorical
summary(t_categorical, maxsum = 5)
t_categorical %>%
  count("The most frequent ingredients" = ingredient) %>%
  slice_max(n = 10, order_by = n) %>%
  rename("Frequency" = n)

t_categorical %>%
  count("The frequent measures" = measure) %>%
  slice_max(n = 10, order_by = n) %>%
  rename("Frequency" = n)

gg_alc1 <- t_categorical %>%
  distinct(drink, alcoholic) %>%
  count(alcoholic) %>%
  ggplot(aes(x = fct_reorder(alcoholic, -n), y = n)) +
  geom_bar(stat = "identity") +
  labs(title = "Frequency of drink versions", x = NULL, y = NULL)

gg_alc2 <- data %>%
  ggplot(aes(x = row_id, color = alcoholic)) +
  geom_freqpoly(bins = 100, binwidth = 20) + 
  labs(title = "Frequency of observations across drink version", x = NULL, y = NULL, color = "Drink version")

gg_glas <- t_categorical %>%
  distinct(drink, glass) %>%
  count(glass) %>%
  ggplot(aes(x = fct_reorder(glass, -n), y = n)) +
  geom_bar(stat = "identity") +
  labs(title = "Frequency of the type of a glass", x = NULL, y = NULL)

gg_cat <- t_categorical %>%
  distinct(drink, category) %>%
  count(category) %>%
  ggplot(aes(x = fct_reorder(category, -n), y = n)) +
  geom_bar(stat = "identity") +
  labs(title = "Frequency of drink category", x = NULL, y = NULL)

gg_alc1 / gg_alc2 + 
  plot_annotation(caption = "by @m_cadek; #TidyTuesday 2020") & 
  dark_theme()

gg_cat / gg_glas + 
  plot_annotation(caption = "by @m_cadek; #TidyTuesday 2020") & 
  dark_theme()

# * 2 * PART --------------------------------------------------------------
# Tidy --------------------------------------------------------------------
data_tidy <- data %>%
  # Remove drink image
  select(-drink_thumb) %>%
  mutate( 
    # Trim white space from measure
    measure = str_trim(measure),
    # Trim repeated white space from measure
    measure = str_squish(measure),
    # Change letter case
    measure = str_to_lower(measure)
    # Extract values of measure
  ) %>%
  ## Extract the numeric values from measure, there are three notable types (possibly more)
  ## Fraction, i.e., 1/2 or 2 1/2, Decimals, i.e., 1.5, and "dashes", i.e. 1 - 2
  ## The code below extracts these values into separate new columns
  mutate(measure_vol_frc = str_extract(measure, "^([0-9]*(\\s?\\d*\\/\\d)?)"),
         measure_vol_dec = str_extract(measure, "([0-9]+(?:\\.[0-9]+)?)"),
         measure_vol_dsh = str_extract(measure, "([0-9]+(?:\\-[0-9]+)?)"),
         measure_unit = str_extract(
           string = measure, 
           pattern = "[a-zA-Z]+ [a-zA-Z]+ [a-zA-Z]+ [a-zA-Z]+|[a-zA-Z]+ [a-zA-Z]+ [a-zA-Z]+|[a-zA-Z]+ [a-zA-Z]+|[a-zA-Z]+"
           ),
         # Remove any white space in new measure
         across(starts_with("measure"), str_trim)) %>%
  ## The regex above does not handle the fractions very well and leaves
  ## the first parts of them, e.g. 1 from 1 / 2 in the _dec and _dsh.
  ## The following replaces it to the NA...
  mutate(
    ## ...for decimals type, i.e. 1.5
    measure_vol_dec = 
      case_when(
        str_detect(string = measure_vol_dec, pattern = "\\.") == TRUE ~ measure_vol_dec,
        str_detect(string = measure_vol_dec, pattern = "\\.") == FALSE ~ NA_character_
      ),
    ## ...for dash type, i.e. 1 - 2 (reads as 1 to 2)
    measure_vol_dsh =
      case_when(
        str_detect(string = measure_vol_dsh, pattern = "\\-") == TRUE ~ measure_vol_dsh,
        str_detect(string = measure_vol_dsh, pattern = "\\-") == FALSE ~ NA_character_
      )
    ## It can't be done in my view for fractions as it would also remove the whole numbers,
    ## e.g. 16 as NA. So I do not do it for fractions and accept there might be some hiccups.
  ) %>% 
    ## Turn empty rows into NA for R to be able to handle it.
  mutate(measure_vol_frc = na_if(x = measure_vol_frc, y = ""),
         ## Now, turn "fractions" into decimals. Save as "_new"
         measure_new = map_dbl(sub(" ", "+", measure_vol_frc), ~ eval(parse(text = .x))),
         measure_vol_dec = as.double(measure_vol_dec), 
         # Merge with frc_ and _dec
         # NOTE: The _dsh is left out and lower boundary value is used, e.g. 1 from 1 - 2.
         measure_new = 
           case_when(
             is.na(measure_vol_dec) ~ measure_new,
             !is.na(measure_vol_dec) ~ measure_vol_dec,
             TRUE ~ measure_new
           ),
         # Convert oz, cl, l, etc. to ml units
         measure_ml =
           # Note, be careful not to match something multiple times!
           case_when(
             str_detect(measure_unit, "ml") == TRUE ~ measure_new,
             str_detect(measure_unit, "^cl$") == TRUE ~ measure_new * 10,
             str_detect(measure_unit, "^l$") == TRUE ~ measure_new * 1000,
             str_detect(measure_unit, "^oz") == TRUE ~ measure_new * 28,
             str_detect(measure_unit, "shot") == TRUE ~ measure_new * 30, # 44.36 was again too much. rounded up to 30
             str_detect(measure_unit, "cup") == TRUE ~ measure_new * 250,
             str_detect(measure_unit, "pint") == TRUE ~ measure_new * 473,
             str_detect(measure_unit, "^splash") == TRUE ~ measure_new * 3.5,
             str_detect(measure_unit, "^part") == TRUE ~ measure_new * 5, # Initially I put it as 44.36 but that created a massive outlier, putting 1 part as = 5 ml seemed reasonable
             str_detect(measure_unit, "^jigger") == TRUE ~ measure_new * 30,
             str_detect(measure_unit, "^dash") == TRUE ~ measure_new * 0.60,
             is.na(measure_unit) ~ measure_new,
             TRUE ~ NA_real_
           ),
         #  ...OR use scale in exchange for interpretability.
         measure_stdz = as.vector(scale(measure_new))) %>% 
  # select(ingredient, measure_ml, measure, measure_unit) %>%
    # This replaces few NA values in alcoholic (see; cocktails %>% summarise_all(~sum(is.na(.))))
  mutate(
    alcoholic = case_when(
      drink == "Cherry Electric Lemonade" ~ "alcoholic",
      TRUE ~ as.character(alcoholic)
      )
    ) %>%
  mutate(
    # Change letter case
    glass = str_to_lower(glass),
    category = str_to_lower(category),
    alcoholic = str_to_lower(alcoholic),
    ingredient = str_to_lower(ingredient),
    # Fill missing values in alcoholic Cherry Electric Lemonade
    
    # Coerce vars to factors
    across(.cols = c(alcoholic, category, glass, ingredient), .fns = as.factor), 
    # make the ingredient number an integer
    ingredient_number = as.integer(ingredient_number), 
    # Coerce vars to date
    date_modified = ymd_hms(date_modified), 
    # Collapse selected levels in glass
    glass = fct_collapse(glass, 
                         `beer glass` = c("beer glass", "beer mug", "beer pilsner"),
                         `margarita glass` = c("margarita glass", "margarita/coupette glass"),
                         `coffee mug` = c("coffee mug", "irish coffee cup"),
                         `wine glass` = c("white wine glass", "wine glass")),
    # Collapse ingredients below 11 into separate level
    ingredient_and_others = fct_lump_min(ingredient, min = 11, other_level = "uncommon ingredient")
           ) %>%
    # Create a column called original_ingredient
  mutate(original_ingredient = ingredient)

# * 3 * PART --------------------------------------------------------------

# Explore tidy ------------------------------------------------------------
gg_tidy_glass <- data_tidy %>%
  ggplot(aes(x = fct_infreq(glass))) +
  geom_bar() +
  labs(title = "Frequent glass type", x = NULL, y = NULL)

gg_alc_glass <- data_tidy %>%
  count(alcoholic, glass) %>%
  ggplot(aes(x = reorder_within(glass, -n, alcoholic), y = n)) +
  geom_bar(stat = "identity") +
  scale_x_reordered() +
  facet_wrap(~alcoholic, scales = "free_x") +
  labs(title = "Frequent glass type across alcoholic and other drinks", x = NULL, y = NULL)

# Visualisation of glass type (after coercion)
gg_tidy_glass / gg_alc_glass +
  plot_annotation(caption = "by @m_cadek; #TidyTuesday 2020") & 
  dark_theme()

gg_alc_category <- data_tidy %>%
  count(alcoholic, category) %>%
  ggplot(aes(x = reorder_within(category, -n, alcoholic), y = n)) +
  geom_bar(stat = "identity") +
  scale_x_reordered() +
  facet_wrap(~alcoholic, scales = "free_x") +
  labs(title = "Frequent category across alcoholic and other drinks", x = NULL, y = NULL)

# Visualisation of alcoholic / non-alc
gg_alc_category + 
  labs(caption = "by @m_cadek; #TidyTuesday 2020") + 
  dark_theme()

gg_common_ingr <- data_tidy %>%
  filter(ingredient_and_others != "uncommon ingredient") %>%
  ggplot(aes(x = fct_infreq(ingredient_and_others))) +
  geom_bar() +
  labs(title = "Frequent ingredients", x = NULL, y = NULL)

# Visualisation of common ingredients
gg_common_ingr +
labs(caption = "by @m_cadek; #TidyTuesday 2020") + 
dark_theme()

gg_common_ingr_in_ord <- data_tidy %>%
  count(ingredient_number, ingredient, sort = TRUE) %>%
  group_by(ingredient_number) %>%
  slice_max(n, n = 3) %>% 
  ggplot(aes(x = reorder_within(ingredient, -n, ingredient_number), y = n)) +
  geom_bar(stat = "identity") +
  scale_x_reordered() +
  scale_y_continuous(n.breaks = 4) +
  facet_wrap(~ingredient_number, scales = "free", ) +
  labs(title = "Frequent ingredients and as they are added", x = NULL, y = NULL)

# Visualisation of common ingredients as they are added
gg_common_ingr_in_ord +
  labs(caption = "by @m_cadek; #TidyTuesday 2020") +
  dark_theme()


# Series of visualisations regarding the measure unit (ml) after coercion
scaled_d_t <- data_tidy %>%
  mutate(measure_ml = as.vector(scale(measure_ml)))

# Comparison of scaled and raw ml units (scaled uses all units across) across all data
# The scaled measure scaled all of the data in measure new (i.e., standard score from oz, tbps, etc.)
# The ml measure converted most of liquid scales to ml (should be more specific)
gg_raw_measure <- (ggplot(data = data_tidy) +
  geom_histogram(aes(x = measure_ml, fill = "Milliliters"), bins = 40) +
  scale_fill_manual(values = c("Milliliters" = c_blue)) +
    scale_x_sqrt() +
  labs(fill = "Legend", y = "Density", x = NULL)) +
  (ggplot(data = data_tidy) +
  geom_histogram(aes(x = measure_stdz, fill = "Scaled"), bins = 40) +
    scale_fill_manual(values = c("Scaled" = c_red)) +
    scale_x_sqrt() +
  labs(fill = "Legend", y = NULL, x = NULL)) +
  plot_annotation(subtitle = "Comparison of measure in raw and scaled units", 
                  caption = "Square root of x transformation") +
  plot_layout(guides = "collect") &
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.line.x = element_blank(),
        legend.background = element_blank(),
        legend.title = element_blank(),
        legend.key.size = unit(1,"line"))

# Comparison of scaled and raw ml units (scaled uses all units across) in gin drinks
gg_gin_measure <- ggplot(data = scaled_d_t %>%
                        filter(ingredient == "gin")) +
  geom_density(aes(x = measure_ml, colour = "Scaled milliliters"), size = 1.5) +
  geom_density(aes(x = measure_stdz, colour = "Scaled all"), size = 1.5) +
  scale_colour_manual(values = c("Scaled milliliters" = c_blue, 
                                 "Scaled all" = c_red)) +
  labs(subtitle = "Gin drinks", colour = "Legend", y = "Density", x = NULL)

# Comparison of scaled and raw ml units (scaled uses all units across) in alcoholic drinks
gg_alc_measure <- ggplot(data = scaled_d_t %>%
                        filter(alcoholic == "alcoholic")) +
  geom_density(aes(x = measure_ml, colour = "Scaled milliliters"), size = 1.5) +
  geom_density(aes(x = measure_stdz, colour = "Scaled all"), size = 1.5) +
  scale_x_log10() +
  scale_colour_manual(values = c("Scaled milliliters" = c_blue, 
                                 "Scaled all" = c_red)) +
  labs(subtitle = "Alcoholic drinks", colour = "Legend", y = "Density", x = NULL)

# Comparison of scaled and raw ml units (scaled uses all units across) in all drinks
gg_all_measure <- ggplot(data = scaled_d_t) +
  geom_density(aes(x = measure_ml, colour = "Scaled milliliters"), size = 1.5) +
  geom_density(aes(x = measure_stdz, colour = "Scaled all"), size = 1.5) +
  scale_x_log10() +
  scale_colour_manual(values = c("Scaled milliliters" = c_blue, 
                                 "Scaled all" = c_red)) +
  labs(subtitle = "All drinks", colour = "Legend", y = "Density", x = NULL)

# Patched comparison of measure in raw and scaled units
gg_raw_measure +
  plot_annotation(caption = "by @m_cadek; #TidyTuesday 2020") & 
  dark_theme()

# Patched comparison of measure units across gin, alcoholic, and all drinks
gg_gin_measure / gg_alc_measure / gg_all_measure + 
  plot_annotation(caption = "*logarithm to base 10\n by @m_cadek; #TidyTuesday 2020") +
  plot_layout(guides = "collect") & theme(axis.text.x = element_blank(),
                                          axis.ticks.x = element_blank(),
                                          axis.line.x = element_blank(),
                                          legend.background = element_blank(),
                                          legend.title = element_blank(),
                                          legend.key.size = unit(1,"line")) &
  dark_theme()

# ANALYSIS ----------------------------------------------------------------
# A] Nest data -----------------------------------------------------------
# Nest alcoholic and gin drinks
system.time(
data_gin_nested <- data_tidy %>%
  # Remove non-alcoholic drinks and other drinks # The first filter.
  filter(alcoholic == "alcoholic") %>%
  # Nesting
  group_by(drink, id_drink, row_id) %>%
  nest() %>%
  # pluck("data") %>% head # sanity check
  # Get a column where I can show only drinks with gin, I like gin.
  # Use map()
  mutate(
    gin_true = map(data, select, ingredient),
         gin_true = map(gin_true, filter, ingredient == "gin"),
         gin_true = map(gin_true, pull, ingredient),
         gin_true = map(gin_true, str_detect, pattern = "gin"),
         gin_true = map_lgl(gin_true, any)
    ) %>%
  # Include only drinks containing gin! # The second filter.
  filter(gin_true == "TRUE")
            ) # Measure elapsed time, takes about


# [optional] SAVE - parquet -----------------------------------------------
## WRITE
# write_parquet(data_gin_nested %>%
#                  # Unnest and save as parquet file which will have few KB
#                unnest(cols = c(data)),
#                "data/tidy/data_gin_unnested.parquet")
## READ
# data_gin_nested <- read_parquet(file = here("data/tidy/data_gin_unnested.parquet"),
#                                as_tibble = TRUE)

data_gin_unnested <- data_gin_nested %>% 
  unnest(cols = c(data))


# Narrow the focus --------------------------------------------------------
# Let's focus only on alcoholic drinks containing gin; I'll split it to data
# about other ingredients in gin and data about gin ingredient specifically

# Note, 127 of measures in ml are NA of which 36 are probably intentional.
# It usually concerns awkward measures such as splash, or measures for mixed 
# contents (solid and liquid) such as spoon. See below:

summary(data_gin_unnested)
na_ml_index <- which(is.na(data_gin_unnested$measure_ml))
data_gin_unnested %>% 
  mutate(rows_numbers = row_number()) %>%
  filter(rows_numbers %in% na_ml_index) %>%
  count(measure_unit, ingredient, sort = TRUE) %>%
  print(n = 60)

# Prepare data with only gin as ingredient - used for visualising complexity
only_gin_data <- data_gin_unnested %>%
  ungroup() %>%
  select(-c(row_id, id_drink, category, date_modified, measure, original_ingredient, gin_true, alcoholic)) %>%
  group_by(drink) %>%
  mutate(total_ingredients = max(ingredient_number)) %>%
  filter(ingredient == "gin") 
# calculate measure and importance of gin

# Prepare data without gin as ingredient - used for visualising ingredients
no_gin_data <- data_gin_unnested %>%
  # Remove columns that won't be used
  ungroup() %>%
  select(-c(row_id, id_drink, date_modified, measure, original_ingredient, gin_true, alcoholic)) %>%
  # Aggregate by drinks and compute total number of ingredients
  group_by(drink) %>%
  mutate(total_ingredients = max(ingredient_number)) %>%
  # Summary excluding gin!
  filter(ingredient!= "gin") %>%
  group_by(ingredient) %>%
  mutate(freq_non_gin_ingredients = n()) %>%
  ungroup() %>%
  mutate(prop_non_gin_ingredients = freq_non_gin_ingredients/n()*100)

# Visualisations of gin drinks complexity (Only gin)
(gg_heat_drink_complexity <- only_gin_data %>%
    ggplot(aes(fct_reorder(drink, total_ingredients), 
               ingredient, fill = total_ingredients)) + 
    scale_fill_viridis(
      discrete = FALSE,
      guide = guide_colorbar(
        direction = "horizontal",
        barheight = unit(2, units = "mm"),
        barwidth = unit(80, units = "mm"),
        draw.ulim = TRUE,
        title.position = "left",
        title.hjust = 0.5,
        title.vjust = 1,
        label.hjust = 0.5
      ))  +
    geom_tile(width = 0.7, height = 2) +
    labs(title = "Complexity of gin drinks", 
         caption = "*Gin was included as one of the ingredients\n by @m_cadek; #TidyTuesday 2020",
         x = NULL, y = NULL, fill = "Total number of ingredients:") + 
    dark_theme(axis.text.y = element_blank(),
               axis.ticks.y = element_blank(),
               panel.grid.major.y = element_blank(),
               legend.position = "bottom")) 

# Visualisations of common ingredients in gin drinks
(gg_heat_gin <- no_gin_data %>%
  ggplot(aes(drink, fct_reorder(ingredient, freq_non_gin_ingredients), fill = freq_non_gin_ingredients)) + 
    scale_fill_viridis(
      discrete = FALSE,
      guide = guide_colorbar(
        direction = "vertical",
        barheight = unit(50, units = "mm"),
        barwidth = unit(2, units = "mm"),
        draw.ulim = TRUE,
        title.position = "top",
        title.hjust = 0.5,
        title.vjust = 1,
        label.hjust = 0.5
        ))  +
  geom_point(shape = 21, size = 3) +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank()) +
  labs(title = "Common ingredients in gin drinks", 
       subtitle = "Colour represents frequency (commonness) of ingredient across all drinks",
       caption = "*Gin excluded from overall frequency\n by @m_cadek; #TidyTuesday 2020",
       x = NULL, y = NULL, fill = "Frequency of \ningredient") +
  dark_theme())


# Finally, graph about importance of gin ingredient in drink (by measure ml)
(gg_gin_importance_ml <- only_gin_data %>%
  mutate(icon_gin = case_when(
    measure_ml == 310.52000 ~ "wine",
    TRUE ~ NA_character_
    )) %>% 
    filter(!is.na(measure_ml)) %>%
  ggplot(aes(y = fct_reorder(drink, measure_ml), x = measure_ml, group = ingredient)) +
  ## The ggimage works by using icons from https://ionicons.com/ & https://github.com/ionic-team/ionicons/find/master
  ## You need to create new column with the icon name
  ## This name is used in geom_icon. list.icon() does not do anything.
  ## Package function is poorly documented.
  # geom_icon(aes(y = 65, x = 200, by = "height",
  #               image = icon_gin), colour = "white", size = 0.5, na.rm = TRUE,
  #           alpha = 0.5) +
  stat_summary_bin(fun = mean, bins = 30, colour = "white", alpha = 0.8, geom = "line", na.rm = TRUE) +
  geom_point(aes(size = measure_ml), 
             show.legend = FALSE, 
             colour = c_blue, 
             alpha =  0.8, na.rm = TRUE) +
  scale_x_continuous(name = "volume [ml]") +
  labs(title = "Gin volume in the drinks",
        x = NULL, y = NULL, caption = "by @m_cadek; #TidyTuesday 2020") +
  coord_flip() +
  dark_theme(axis.text.x = element_text(colour = "white", 
                                        angle = 90, 
                                        hjust = 1, 
                                        vjust = 0)))


# Prepare k-means data ----------------------------------------------------
# Let's prepare numerical data which can be used in k-means
aggregated_gin <- data_gin_unnested %>%
  group_by(drink) %>%
  # I will create:
  # * sum of ingredients, 
  # * approximate sum of volume, 
  # * approximate average ingredient volume, and 
  # * approximate proportion of gin
  # It is approximate because the ml unit were computed only roughly.
  summarise(sum_ingredients = n(),
            aprx_sum_volume_ml = sum(measure_ml, na.rm = TRUE),
            aprx_avg_ingredient_volume_ml = mean(measure_ml, na.rm = TRUE),
            aprx_prop_of_gin_ml = case_when(
              ingredient == "gin" ~ measure_ml/aprx_sum_volume_ml
            )) %>%
  arrange(-aprx_prop_of_gin_ml) %>%
  ungroup() %>%
  drop_na() %>% 
  # I'll save drink names as rownames to keep the labels. K means accepts only numerical values.
  column_to_rownames(var = "drink")

# Visualise k-means data  -------------------------------------------------
# Visualise the aggregated data to show what is k-means utilised on
set.seed(2020)
(gg_aggregated <- ggplot(aggregated_gin, aes(y = aprx_sum_volume_ml, x = aprx_avg_ingredient_volume_ml, 
                           colour = aprx_prop_of_gin_ml, alpha = sum_ingredients)) +
  geom_jitter(size = 5, width = 2, height = 2) +
  guides(colour = guide_legend("Gin proportion")) +
  scale_alpha_continuous(range = c(0.5, 1), guide = FALSE) +
  scale_colour_viridis(alpha = 1) +
  labs(title = "Aggregated data about gin drinks",
       subtitle = 
       "Total volume vs average volume is plotted on axes. The alpha shows number of ingredients,\nthe colour represents how much gin is in a given drink.",
       y = "Total volume [ml]", x = "Average volume of ingredients [ml]",
       caption = "*alpha indicates number of ingredients, added jitter\nby @m_cadek; #TidyTuesday 2020") +
  dark_theme())

# What the data look like


# Let's run the k-mean algorithm on the aggregated data
kmeans_summary <- 
  tibble(k = 1:8) %>%
  mutate(
    # Do the cluster analysis from one to 8 clusters
    kmeans = map(k, ~kmeans(aggregated_gin, centers = .x)),
    # Show summary per each cluster
    kmeans_tidy = map(kmeans, tidy),
    # Show summary of key statistics
    kmeans_glan = map(kmeans, glance),
    # Clusters with the original data
    kmeans_augm = map(kmeans, augment, aggregated_gin)
  )

# Show clusters
kmeans_summary

# Extract statistics ------------------------------------------------------
# glance() function extracts a summary stats for models
clusters_statistics <- kmeans_summary %>%
  unnest(cols = c(kmeans_glan))

# tidy() function summarizes per cluster stats
clusters_summary <- kmeans_summary %>%
  unnest(cols = c(kmeans_tidy))

# augment adds predicted classifications to the original data set
data_predicted <- kmeans_summary %>% 
  unnest(cols = c(kmeans_augm))

# Visualise ---------------------------------------------------------------

# Now we can plot the original points using the data from augment(), 
# with each point coloured according to the predicted cluster.
set.seed(2020)
# Show the visualisation of predicted clusters across the data
(gg_predicted <- ggplot(data_predicted, aes(y = aprx_sum_volume_ml, x = aprx_avg_ingredient_volume_ml, 
                           colour = .cluster)) +
  geom_jitter(size = 3, alpha = 0.5, width = 2, height = 2) +
  guides(colour = guide_legend("Clusters")) +
  scale_color_discrete_qualitative(palette = "Dark 3") +
  labs(y = "Total volume [ml]", 
       x = "Average volume of ingredients [ml]",
       caption = "*added jitter\nby @m_cadek; #TidyTuesday 2020") +
  facet_wrap(~ k, ncol = 2) +
  dark_theme())

set.seed(2020)
# Show the predicted clusters and their centroids
(gg_centres <- gg_predicted + geom_point(data = clusters_summary %>% 
                                           rename(".cluster" = cluster),
                          size = 4, fill = "white", shape = 22,
                          alpha = 0.8) + 
    guides(colour = guide_legend("Clusters \n& centers"),
           fill = guide_legend("Clusters \n& centers")))

# Visualise the predicted clusters with labels
row_names_labels <- c("Gin Swizzle", "Ace", "Negroni", "White Lady", "Gin Fizz", "Casino", "Martini", "Casino Royale", "Pink Gin",
                      "Abbey Cocktail", "Cherry Electric Lemonade", "Dragonfly", "Orange Oasis", 'French "75"')

set.seed(2020)
(gg_predicted_labels <- ggplot(data_predicted, aes(y = aprx_sum_volume_ml, x = aprx_avg_ingredient_volume_ml, 
                           colour = .cluster)) +
    geom_jitter(size = 3, alpha = 0.5, width = 2, height = 2) +
    guides(colour = guide_legend("Clusters")) +
    scale_color_discrete_qualitative(palette = "Dark 3") +
    facet_wrap(~ k, ncol = 2) +
    geom_point(data = clusters_summary %>% 
                 rename(".cluster" = cluster),
               size = 4, fill = "white", shape = 22,
               alpha = 0.8) + 
    geom_text_repel(data = data_predicted %>%
                      filter(.rownames %in% row_names_labels),
                    aes(label = .rownames), 
                    segment.size  = 0.2,
                    force = 2, max.iter = 10000,
                    segment.color = "grey50") +
    guides(colour = guide_legend("Clusters \n& centers"),
           fill = guide_legend("Clusters \n& centers")) +
    labs(title = "Predicted clusters",
         subtitle = "Manual label was added to interesting points close to centroids",
         y = "Total volume [ml]", 
         x = "Average volume of ingredients [ml]",
         caption = "*added jitter\nby @m_cadek; #TidyTuesday 2020") +
    dark_theme())


# Elbow method ------------------------------------------------------------

# cluster (300 values) contains information about each point
# centers, withinss, and size (3 values) contain information about each cluster
# totss, tot.withinss, betweenss, and iter (1 value) contain information about the full clustering

# Show the elbow graph
(gg_elbow <- ggplot(clusters_statistics, aes(k, tot.withinss)) +
    geom_line(size = 1.5, color = "white") +
    geom_point(size = 3, color = c_red) +
    scale_x_continuous(n.breaks = 8, name = "Number of clusters (k)") +
    scale_y_continuous(name = "Total within cluster sum of squares") +
    dark_theme() +
    labs(subtitle = "Elbow method estimating the optimal number of clusters",
         caption = "by @m_cadek; #TidyTuesday 2020"))


