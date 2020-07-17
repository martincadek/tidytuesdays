
# Resources ---------------------------------------------------------------
https://github.com/rfordatascience/tidytuesday/tree/master/data/2018-11-27
http://www.sthda.com/english/articles/36-classification-methods-essentials/151-logistic-regression-essentials-in-r/

# Libraries ---------------------------------------------------------------
library(tidyverse)
library(tidymodels)
library(caret)

# Load Data ---------------------------------------------------------------
bridges <- read_csv(file = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2018-11-27/baltimore_bridges.csv") 


# explore -----------------------------------------------------------------
glimpse(bridges)
dim(bridges)

# Missing Values
missing_values <- VIM::aggr(bridges)
plot(missing_values, cex.lab = 1, cex.axis = 0.4, bars = FALSE,
     prop = TRUE, numbers = FALSE)
summary(missing_values)

missing_values_2 <- naniar::gg_miss_var(bridges, show_pct = TRUE)
missing_values_2

missing_values_3 <- naniar::gg_miss_which(bridges)
missing_values_3

# Improve Cost thousand is often missing
View(bridges)
bridges$total_improve_cost_thousands

# Which are missing
which_na(bridges$responsibility)
which_na(bridges$owner)

# Plot subset of missing
bridges[c(283,284),]

remove_na <- c(283, 284)

# Remove NA sensibly ------------------------------------------------------

bridges %>% filter(!row_number() %in% remove_na)


# model -------------------------------------------------------------------
model <- glm( diabetes ~., data = train.data, family = binomial)


# My aim here would be to run logistic regression
