# Virtual environment -----------------------------------------------------
# https://rstudio.github.io/renv/articles/renv.html
# install.packages("renv")
# renv::init() #  to initialize a new project-local environment with a private R library
# renv::snapshot() # to save the state of your project to renv.lock; and
# renv::restore() # to restore the state of your project from renv.lock.

# Libraries ---------------------------------------------------------------
pkgs <- c("tidyverse", "tidymodels", "here", "Cairo", "colorspace",
          "janitor", "showtext", "rlang", "patchwork", "ggthemes", 
          "lubridate", "flextable", "tidytext", "arrow", "klaR", 
          "tidytuesdayR", "ggimage", "rsvg", "conflicted", "viridis",
          "renv", "ggrepel")

invisible(lapply(pkgs, library, character.only = TRUE))
conflict_prefer("filter", "dplyr")
conflict_prefer("select", "dplyr")
conflict_prefer("modify", "purrr")


# Themes, fonts, labels ---------------------------------------------------
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

