# Get data ----------------------------------------------------------------
tt_cocktails <- tidytuesdayR::tt_load(x = "2020-05-26", download_files = "cocktails")
data <- tt_cocktails$cocktails
data <- data %>%
     select(-c(iba, video)) # drop iba and video columns with lot of NAs

#write_rds(x = data, path = here("data/raw/cocktails.rds"))