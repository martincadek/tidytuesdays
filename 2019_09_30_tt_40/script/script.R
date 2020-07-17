options(scipen = 999) # disable scientific notation


# Setup - Resources ---------------------------------------------------------------
# https://livebook.datascienceheroes.com/exploratory-data-analysis.html#correlation
# https://github.com/rfordatascience/tidytuesday/tree/master/data/2019/2019-10-01


# Setup - Libraries ---------------------------------------------------------------
library(funModeling)
library(tidyverse)
library(skimr)
library(correlationfunnel)
library(colorspace)
library(gghighlight)



# library(rayshader)

# Setup - Theme ----------------------------------------------------------------
# WIP set theme properly and pick colours
def_color_pal <- sequential_hcl(n = 7, h = c(-83, 20), c = c(65, NA, 18), l = c(32, 90), 
               power = c(0.5, 1))
def_color_pal

# scale_fill_discrete_sequential(name = "Categories", palette = "Purple-Orange")

theme_tidytuesday <- function(x) {
     theme(text = element_text(family = "Arial"),
           axis.text = element_text(size = 10, color = def_color_pal[2]),
           axis.title.x = 
                element_text(size = 14, face = "bold", color = def_color_pal[5]),
           axis.title.y = 
                element_text(size = 14, face = "bold", color = def_color_pal[5]),
           axis.line.x = element_line(color  = def_color_pal[1]), 
           axis.line.y = element_line(color  = def_color_pal[1]), 
           axis.ticks = element_line(color  = def_color_pal[1]),
           plot.title = element_text(size = 20, face = "bold.italic", color = def_color_pal[5]),
           plot.subtitle = element_text(size = 12, face = "bold.italic", color = def_color_pal[5]),
           plot.caption = element_text(color = def_color_pal[5]),
           legend.title = element_text(color = def_color_pal[2]),
           legend.text = element_text(face = "italic", color = def_color_pal[2]),
           plot.margin = margin(t = 0.5, r = 0.5, b = 0.5, l = 0.5, "cm"),
           panel.background = element_rect(fill = "white"),
           panel.grid.minor = element_blank())
}


# Import data - All -------------------------------------------------------------
pizza_jared <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-01/pizza_jared.csv")
pizza_barstool <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-01/pizza_barstool.csv")
pizza_datafiniti <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-01/pizza_datafiniti.csv")

# Select numerical data only - All ----------------------------------------------

pizza_jared_num <- pizza_jared %>%
        mutate(answer = factor(x = answer, 
                               levels = c("Never Again",
                                          "Poor",
                                          "Fair", # Single occurance, merged with Fair
                                          "Average",
                                          "Good",
                                          "Excellent"),
                               ordered = TRUE)) %>%
        mutate(answer = fct_recode(answer, "Average" = "Fair")) %>%
        mutate(answer_num = as.numeric(answer)) %>% 
        filter(!is.na(percent)) %>%
        select_if(is.numeric)

pizza_barstool_num <- pizza_barstool %>%
        select_if(is.numeric)

pizza_datafiniti_num <- pizza_datafiniti %>%
        select_if(is.numeric)

# Explore - All -----------------------------------------------------------------
skim(pizza_jared)
skim(pizza_barstool)
skim(pizza_datafiniti)

glimpse(pizza_jared)
glimpse(pizza_barstool)
glimpse(pizza_datafiniti)

plot_num(pizza_jared)
freq(pizza_jared)

plot_num(pizza_barstool)
freq(pizza_barstool)

plot_num(pizza_datafiniti)
freq(pizza_datafiniti)

# Jared - Coerce/Tidy -------------------------------------------------------
pizza_jared <- pizza_jared %>% 
        mutate(answer = factor(x = answer, 
                                     levels = c("Never Again",
                                                "Poor",
                                                "Fair", # Single occurance, merged with Fair
                                                "Average",
                                                "Good",
                                                "Excellent"),
                                     ordered = TRUE)) %>%
        mutate(answer = fct_recode(answer, "Average" = "Fair")) %>%
        mutate(answer_num = as.numeric(answer))
# select(answer, answer_num) %>%
# arrange(answer_num) %>% 
# group_by(answer, answer_num) %>%
# count()

# Jared - Cor funnel ------------------------------------------------------------
# https://business-science.github.io/correlationfunnel/
pizza_jared_num %>%
        select(-c(polla_qid, pollq_id)) %>%
        correlate(target = answer_num) %>%
        plot_correlation_funnel(interactive = FALSE) +
        xlab("Correlation of numeric variables with answer") +
        ylab("Features") +
        theme_tidytuesday()
ggsave("graphs/graph1.png", width = 7, height = 5, dpi = 320)

# Jared - Correlation -------------------------------------------
round(cov(pizza_jared_num), 2)

correlation_table(pizza_jared, target = "answer")



# Jared - Barchart ----------------------------------------------------
pizza_jared %>% 
        filter(total_votes != 0) %>%
        group_by(place, question, answer) %>%
        summarise(category_freq = sum(votes)) %>%
        ggplot(data = ., aes(x = fct_reorder(place, category_freq), y = category_freq, fill = answer)) +
        scale_fill_discrete_sequential(name = "Categories", palette = "Purple-Orange") + 
        geom_col() + 
        coord_flip() +
        theme_tidytuesday() +
        labs(title = "Top New York pizza restaurants", 
             caption = "Data source: Jared Lander") + 
        xlab("Pizza places") +
        ylab("Total votes per place")
ggsave("graphs/graph2.png", width = 8, height = 10, dpi = 320)

pizza_jared %>%
        filter(total_votes != 0) %>%
        group_by(place, question, answer) %>%
        summarise(category_freq = sum(votes)) %>%
        ggplot(data = ., aes(x = fct_reorder(place, category_freq), y = category_freq, fill = answer)) +
        scale_fill_discrete_sequential(name = "Categories", palette = "Purple-Orange") + 
        geom_col() + 
        coord_flip() +
        theme_tidytuesday() +
        labs(title = "Top New York pizza restaurants",
             subtitle = "Excellent rating only",
             caption = "Data source: Jared Lander") + 
        xlab("Pizza places") +
        ylab("Total votes per place") +
        gghighlight(answer == "Excellent")

ggsave("graphs/graph3.png", width = 8, height = 10, dpi = 320)

pizza_jared %>%
        filter(total_votes != 0) %>%
        group_by(place, question, answer) %>%
        summarise(category_freq = sum(votes)) %>%
        ungroup() %>%
        mutate(answer = fct_collapse(answer, 
                     Negative = c("Never Again", "Poor"),
                     Positive = c("Good", "Excellent"))) %>%
        mutate(answer = fct_recode(answer, 
                                     Neutral = "Average")) %>%
        ggplot(data = ., aes(x = fct_reorder(place, category_freq), y = category_freq, fill = answer)) +
        scale_fill_discrete_sequential(name = "Categories", palette = "Purple-Orange") + 
        geom_col() + 
        coord_flip() +
        theme_tidytuesday() +
        labs(title = "Top New York pizza restaurants", 
             subtitle = "Simpler rating",
             caption = "Data source: Jared Lander") + 
        xlab("Pizza places") +
        ylab("Total votes per place")

ggsave("graphs/graph4.png", width = 8, height = 10, dpi = 320)
