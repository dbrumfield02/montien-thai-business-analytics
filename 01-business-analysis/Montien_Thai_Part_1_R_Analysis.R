# BUS 536 BUSINESS ANALYTICS PROJECT
# Montien Thai Restaurant Analytics and Growth Strategy
# Portfolio-ready, reproducible analysis script
#
# PURPOSE
# This script evaluates three business questions using historical restaurant,
# Airbnb concentration, and neighborhood data for Boston's Chinatown:
#   1. Is Airbnb concentration related to out-of-state review share?
#   2. How do in-state and out-of-state customer ratings compare?
#   3. How did review activity change as more restaurants appeared in the data?
#
# DATA NOTE
# Out-of-state reviewers are used as an indicator of visiting customers. This
# does not prove that every out-of-state reviewer was a tourist. The analysis
# is observational and should not be interpreted as evidence of causation.

# =============================================================================
# 1. PACKAGES AND PROJECT SETTINGS
# =============================================================================

required_packages <- c("tidyverse", "janitor", "broom", "knitr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the following packages before running this script: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
  library(broom)
  library(knitr)
})

data_filename <- "restaurant_bostononly_long_withBNS_new_an6.csv"
data_candidates <- c(
  file.path("data", data_filename),
  data_filename
)
existing_data_files <- data_candidates[file.exists(data_candidates)]

if (length(existing_data_files) == 0) {
  stop(
    "Dataset not found. Place ", data_filename,
    " in the project root or in a data/ folder.",
    call. = FALSE
  )
}

csv_file <- existing_data_files[[1]]
output_dir <- "outputs"
figure_dir <- file.path(output_dir, "figures")
table_dir <- file.path(output_dir, "tables")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

montien_pattern <- regex("Montien Thai", ignore_case = TRUE)

# =============================================================================
# 2. HELPER FUNCTIONS
# =============================================================================

safe_mean <- function(x) {
  if (all(is.na(x))) {
    return(NA_real_)
  }

  mean(x, na.rm = TRUE)
}

safe_median <- function(x) {
  if (all(is.na(x))) {
    return(NA_real_)
  }

  median(x, na.rm = TRUE)
}

weighted_mean_complete <- function(x, weights) {
  keep <- complete.cases(x, weights) & weights >= 0

  if (!any(keep) || sum(weights[keep]) == 0) {
    return(NA_real_)
  }

  weighted.mean(x[keep], w = weights[keep])
}

model_result <- function(model, term_name, comparison) {
  coefficient <- broom::tidy(model, conf.int = TRUE) %>%
    filter(term == term_name)
  fit <- broom::glance(model)

  if (nrow(coefficient) != 1) {
    stop("Expected one model coefficient for ", comparison, ".", call. = FALSE)
  }

  tibble(
    Comparison = comparison,
    Estimate = coefficient$estimate,
    `95% CI Lower` = coefficient$conf.low,
    `95% CI Upper` = coefficient$conf.high,
    `p-value` = coefficient$p.value,
    `R-squared` = fit$r.squared,
    Observations = stats::nobs(model)
  )
}

paired_test_result <- function(x, y, comparison) {
  keep <- complete.cases(x, y)

  if (sum(keep) < 2) {
    stop("Not enough complete pairs for: ", comparison, call. = FALSE)
  }

  test <- t.test(x[keep], y[keep], paired = TRUE)

  tibble(
    Comparison = comparison,
    `Complete Pairs` = sum(keep),
    `Mean Difference` = mean(x[keep] - y[keep]),
    `95% CI Lower` = test$conf.int[[1]],
    `95% CI Upper` = test$conf.int[[2]],
    `p-value` = test$p.value
  )
}

shapiro_result <- function(x, comparison) {
  values <- x[!is.na(x)]

  if (length(values) < 3 || length(values) > 5000) {
    return(tibble(
      Comparison = comparison,
      Observations = length(values),
      W = NA_real_,
      `p-value` = NA_real_,
      Note = "Shapiro-Wilk test requires between 3 and 5,000 observations."
    ))
  }

  test <- shapiro.test(values)

  tibble(
    Comparison = comparison,
    Observations = length(values),
    W = unname(test$statistic),
    `p-value` = test$p.value,
    Note = ""
  )
}

save_table <- function(data, filename) {
  readr::write_csv(data, file.path(table_dir, filename), na = "")
}

portfolio_theme <- function() {
  theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11),
      panel.grid.minor = element_blank(),
      legend.position = "right"
    )
}

# =============================================================================
# 3. IMPORT, VALIDATE, AND PREPARE THE DATA
# =============================================================================

restaurant_data <- readr::read_csv(csv_file, show_col_types = FALSE) %>%
  janitor::clean_names()

required_columns <- c(
  "year",
  "rest_id",
  "nbhds891",
  "instateratio",
  "outstateratio",
  "parcelpct",
  "instate_ratings",
  "outstate_ratings",
  "instate_count",
  "outstate_count",
  "reviewcount"
)

missing_columns <- setdiff(required_columns, names(restaurant_data))

if (length(missing_columns) > 0) {
  stop(
    "The dataset is missing required columns: ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

chinatown <- restaurant_data %>%
  filter(str_to_lower(str_squish(nbhds891)) == "chinatown")

if (nrow(chinatown) == 0) {
  stop("No Chinatown observations were found in nbhds891.", call. = FALSE)
}

montien <- chinatown %>%
  filter(str_detect(rest_id, montien_pattern)) %>%
  arrange(year)

other_chinatown <- chinatown %>%
  filter(!str_detect(rest_id, montien_pattern))

if (nrow(montien) == 0) {
  stop("No Montien Thai observations were found in rest_id.", call. = FALSE)
}

duplicate_montien_years <- montien %>%
  count(year, name = "rows") %>%
  filter(rows > 1)

if (nrow(duplicate_montien_years) > 0) {
  stop(
    "The analysis expects one Montien Thai observation per year. ",
    "Review duplicate years before continuing.",
    call. = FALSE
  )
}

data_profile <- tibble(
  Measure = c(
    "Full dataset observations",
    "Full dataset variables",
    "Chinatown observations",
    "Chinatown restaurants",
    "Montien Thai observations",
    "First Montien year",
    "Last Montien year"
  ),
  Value = c(
    nrow(restaurant_data),
    ncol(restaurant_data),
    nrow(chinatown),
    n_distinct(chinatown$rest_id),
    nrow(montien),
    min(montien$year, na.rm = TRUE),
    max(montien$year, na.rm = TRUE)
  )
)

print(knitr::kable(data_profile, caption = "Dataset Profile"))
save_table(data_profile, "data_profile.csv")

# =============================================================================
# 4. QUESTION 1: AIRBNB CONCENTRATION AND OUT-OF-STATE REVIEW SHARE
# =============================================================================

q1_chinatown_yearly <- other_chinatown %>%
  group_by(year) %>%
  summarise(
    chinatown_instate_ratio = safe_mean(instateratio),
    chinatown_outstate_ratio = safe_mean(outstateratio),
    airbnb_proportion = safe_mean(parcelpct),
    restaurant_count = n_distinct(rest_id),
    .groups = "drop"
  )

q1_data <- montien %>%
  select(
    year,
    montien_instate_ratio = instateratio,
    montien_outstate_ratio = outstateratio,
    montien_airbnb_proportion = parcelpct
  ) %>%
  left_join(q1_chinatown_yearly, by = "year") %>%
  arrange(year)

q1_summary <- q1_data %>%
  summarise(
    montien_avg_instate = safe_mean(montien_instate_ratio),
    montien_avg_outstate = safe_mean(montien_outstate_ratio),
    chinatown_avg_instate = safe_mean(chinatown_instate_ratio),
    chinatown_avg_outstate = safe_mean(chinatown_outstate_ratio),
    avg_airbnb_proportion = safe_mean(airbnb_proportion)
  )

q1_montien_model <- lm(
  montien_outstate_ratio ~ montien_airbnb_proportion,
  data = q1_data,
  na.action = na.exclude
)

q1_chinatown_model <- lm(
  chinatown_outstate_ratio ~ airbnb_proportion,
  data = q1_data,
  na.action = na.exclude
)

q1_results <- bind_rows(
  model_result(
    q1_montien_model,
    "montien_airbnb_proportion",
    "Montien Thai"
  ),
  model_result(
    q1_chinatown_model,
    "airbnb_proportion",
    "Other Chinatown Restaurants"
  )
) %>%
  mutate(
    across(
      c(Estimate, `95% CI Lower`, `95% CI Upper`, `R-squared`),
      ~ round(.x, 3)
    ),
    `p-value` = round(`p-value`, 4)
  )

print(knitr::kable(
  q1_summary,
  digits = 3,
  caption = "Question 1 Summary Statistics"
))
print(knitr::kable(
  q1_results,
  caption = "Airbnb Concentration and Out-of-State Review Share"
))

save_table(q1_summary, "question1_summary.csv")
save_table(q1_results, "question1_regression_results.csv")

# Figure used in the portfolio case study: review shares over time.
q1_share_plot_data <- bind_rows(
  q1_data %>%
    transmute(
      year,
      Restaurant = "Montien Thai",
      `In-State` = montien_instate_ratio,
      `Out-of-State` = montien_outstate_ratio
    ),
  q1_data %>%
    transmute(
      year,
      Restaurant = "Other Chinatown Restaurants",
      `In-State` = chinatown_instate_ratio,
      `Out-of-State` = chinatown_outstate_ratio
    )
) %>%
  pivot_longer(
    cols = c(`In-State`, `Out-of-State`),
    names_to = "Customer Type",
    values_to = "Review Share"
  )

q1_share_plot <- ggplot(
  q1_share_plot_data,
  aes(x = year, y = `Review Share`, color = `Customer Type`)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.2) +
  facet_wrap(~ Restaurant, ncol = 2) +
  scale_color_manual(values = c(
    "In-State" = "#F8766D",
    "Out-of-State" = "#00BFC4"
  )) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  coord_cartesian(ylim = c(0, 0.75)) +
  labs(
    title = "In-State and Out-of-State Review Shares Over Time",
    subtitle = "Montien Thai compared with other Chinatown restaurants",
    x = "Year",
    y = "Share of Reviews",
    color = "Customer Type"
  ) +
  portfolio_theme()

print(q1_share_plot)

ggsave(
  file.path(figure_dir, "figure1_review_shares_over_time.png"),
  plot = q1_share_plot,
  width = 10,
  height = 5,
  dpi = 300
)

# Supporting diagnostic: the relationship tested by the regressions.
q1_relationship_plot_data <- bind_rows(
  q1_data %>%
    transmute(
      `Airbnb Proportion` = montien_airbnb_proportion,
      `Out-of-State Review Share` = montien_outstate_ratio,
      Restaurant = "Montien Thai"
    ),
  q1_data %>%
    transmute(
      `Airbnb Proportion` = airbnb_proportion,
      `Out-of-State Review Share` = chinatown_outstate_ratio,
      Restaurant = "Other Chinatown Restaurants"
    )
)

q1_relationship_plot <- ggplot(
  q1_relationship_plot_data,
  aes(x = `Airbnb Proportion`, y = `Out-of-State Review Share`)
) +
  geom_point(size = 2.5, color = "#3F4A45") +
  geom_smooth(method = "lm", se = TRUE, color = "#2F5597") +
  facet_wrap(~ Restaurant, ncol = 2) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title = "Airbnb Concentration and Out-of-State Review Share",
    subtitle = "Regression lines show association, not causation",
    x = "Share of Parcels Associated with Airbnb",
    y = "Out-of-State Review Share"
  ) +
  portfolio_theme() +
  theme(legend.position = "none")

print(q1_relationship_plot)

ggsave(
  file.path(figure_dir, "question1_airbnb_relationship.png"),
  plot = q1_relationship_plot,
  width = 10,
  height = 5,
  dpi = 300
)

# =============================================================================
# 5. QUESTION 2: IN-STATE AND OUT-OF-STATE CUSTOMER RATINGS
# =============================================================================

q2_missing_values <- montien %>%
  summarise(
    missing_instate_ratings = sum(is.na(instate_ratings)),
    missing_outstate_ratings = sum(is.na(outstate_ratings)),
    missing_instate_counts = sum(is.na(instate_count)),
    missing_outstate_counts = sum(is.na(outstate_count))
  )

q2_chinatown_yearly <- other_chinatown %>%
  group_by(year) %>%
  summarise(
    chinatown_instate_rating = weighted_mean_complete(
      instate_ratings,
      instate_count
    ),
    chinatown_outstate_rating = weighted_mean_complete(
      outstate_ratings,
      outstate_count
    ),
    .groups = "drop"
  )

q2_data <- montien %>%
  select(
    year,
    montien_instate_rating = instate_ratings,
    montien_outstate_rating = outstate_ratings,
    montien_instate_count = instate_count,
    montien_outstate_count = outstate_count
  ) %>%
  left_join(q2_chinatown_yearly, by = "year") %>%
  arrange(year)

q2_summary <- q2_data %>%
  summarise(
    montien_avg_instate = safe_mean(montien_instate_rating),
    montien_avg_outstate = safe_mean(montien_outstate_rating),
    chinatown_avg_instate = safe_mean(chinatown_instate_rating),
    chinatown_avg_outstate = safe_mean(chinatown_outstate_rating)
  )

q2_differences <- q2_data %>%
  transmute(
    year,
    montien_instate_vs_outstate =
      montien_instate_rating - montien_outstate_rating,
    montien_vs_chinatown_instate =
      montien_instate_rating - chinatown_instate_rating,
    montien_vs_chinatown_outstate =
      montien_outstate_rating - chinatown_outstate_rating
  )

q2_normality_results <- bind_rows(
  shapiro_result(
    q2_differences$montien_instate_vs_outstate,
    "Montien: In-State vs. Out-of-State"
  ),
  shapiro_result(
    q2_differences$montien_vs_chinatown_instate,
    "In-State: Montien vs. Chinatown"
  ),
  shapiro_result(
    q2_differences$montien_vs_chinatown_outstate,
    "Out-of-State: Montien vs. Chinatown"
  )
) %>%
  mutate(
    W = round(W, 3),
    `p-value` = round(`p-value`, 4)
  )

q2_test_results <- bind_rows(
  paired_test_result(
    q2_data$montien_instate_rating,
    q2_data$montien_outstate_rating,
    "Montien: In-State vs. Out-of-State"
  ),
  paired_test_result(
    q2_data$montien_instate_rating,
    q2_data$chinatown_instate_rating,
    "In-State: Montien vs. Chinatown"
  ),
  paired_test_result(
    q2_data$montien_outstate_rating,
    q2_data$chinatown_outstate_rating,
    "Out-of-State: Montien vs. Chinatown"
  )
) %>%
  mutate(
    across(
      c(`Mean Difference`, `95% CI Lower`, `95% CI Upper`),
      ~ round(.x, 3)
    ),
    `p-value` = round(`p-value`, 4)
  )

print(knitr::kable(
  q2_missing_values,
  caption = "Question 2 Missing-Value Check"
))
print(knitr::kable(
  q2_summary,
  digits = 3,
  caption = "Question 2 Average Ratings"
))
print(knitr::kable(
  q2_normality_results,
  caption = "Normality Checks for Paired Differences"
))
print(knitr::kable(
  q2_test_results,
  caption = "Question 2 Paired Rating Comparisons"
))

save_table(q2_missing_values, "question2_missing_values.csv")
save_table(q2_summary, "question2_summary.csv")
save_table(q2_normality_results, "question2_normality_results.csv")
save_table(q2_test_results, "question2_paired_test_results.csv")

q2_plot_data <- q2_data %>%
  select(
    year,
    `Montien - In-State` = montien_instate_rating,
    `Montien - Out-of-State` = montien_outstate_rating,
    `Chinatown - In-State` = chinatown_instate_rating,
    `Chinatown - Out-of-State` = chinatown_outstate_rating
  ) %>%
  pivot_longer(
    cols = -year,
    names_to = "Customer Group",
    values_to = "Average Rating"
  )

q2_plot <- ggplot(
  q2_plot_data,
  aes(x = year, y = `Average Rating`, color = `Customer Group`)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.2) +
  scale_color_manual(values = c(
    "Chinatown - In-State" = "#F8766D",
    "Chinatown - Out-of-State" = "#7CAE00",
    "Montien - In-State" = "#00BFC4",
    "Montien - Out-of-State" = "#C77CFF"
  )) +
  scale_y_continuous(limits = c(2.5, 4.5)) +
  labs(
    title = "In-State and Out-of-State Customer Ratings",
    subtitle = "Montien Thai compared with other Chinatown restaurants",
    x = "Year",
    y = "Average Rating",
    color = "Customer Group"
  ) +
  portfolio_theme()

print(q2_plot)

ggsave(
  file.path(figure_dir, "figure2_customer_ratings.png"),
  plot = q2_plot,
  width = 10,
  height = 5,
  dpi = 300
)

# =============================================================================
# 6. QUESTION 3: COMPETITION AND ANNUAL REVIEW ACTIVITY
# =============================================================================

q3_chinatown_yearly <- other_chinatown %>%
  group_by(year) %>%
  summarise(
    chinatown_avg_reviewcount = safe_mean(reviewcount),
    chinatown_median_reviewcount = safe_median(reviewcount),
    other_restaurant_count = n_distinct(rest_id),
    .groups = "drop"
  ) %>%
  arrange(year)

q3_data <- montien %>%
  select(
    year,
    montien_reviewcount = reviewcount
  ) %>%
  left_join(q3_chinatown_yearly, by = "year") %>%
  arrange(year) %>%
  mutate(
    review_gap = montien_reviewcount - chinatown_avg_reviewcount
  )

q3_yearly_table <- q3_data %>%
  transmute(
    Year = year,
    `Montien Reviews` = montien_reviewcount,
    `Other Chinatown Average` = round(chinatown_avg_reviewcount, 1),
    `Other Chinatown Restaurants` = other_restaurant_count,
    `Montien Minus Chinatown` = round(review_gap, 1)
  )

q3_summary <- q3_data %>%
  summarise(
    montien_avg_reviews = safe_mean(montien_reviewcount),
    chinatown_avg_reviews = safe_mean(chinatown_avg_reviewcount),
    avg_review_gap = safe_mean(review_gap),
    competition_start = first(other_restaurant_count),
    competition_end = last(other_restaurant_count)
  )

q3_montien_model <- lm(
  montien_reviewcount ~ other_restaurant_count,
  data = q3_data,
  na.action = na.exclude
)

q3_chinatown_model <- lm(
  chinatown_avg_reviewcount ~ other_restaurant_count,
  data = q3_data,
  na.action = na.exclude
)

q3_gap_model <- lm(
  review_gap ~ other_restaurant_count,
  data = q3_data,
  na.action = na.exclude
)

q3_results <- bind_rows(
  model_result(
    q3_montien_model,
    "other_restaurant_count",
    "Montien Thai"
  ),
  model_result(
    q3_chinatown_model,
    "other_restaurant_count",
    "Other Chinatown Restaurants"
  ),
  model_result(
    q3_gap_model,
    "other_restaurant_count",
    "Montien Relative to Chinatown"
  )
) %>%
  mutate(
    across(
      c(Estimate, `95% CI Lower`, `95% CI Upper`, `R-squared`),
      ~ round(.x, 3)
    ),
    `p-value` = round(`p-value`, 4)
  )

print(knitr::kable(
  q3_yearly_table,
  caption = "Montien Thai Review Count Compared with Chinatown"
))
print(knitr::kable(
  q3_summary,
  digits = 2,
  caption = "Question 3 Summary Statistics"
))
print(knitr::kable(
  q3_results,
  caption = "Competition and Annual Review Activity"
))

save_table(q3_yearly_table, "question3_yearly_comparison.csv")
save_table(q3_summary, "question3_summary.csv")
save_table(q3_results, "question3_regression_results.csv")

q3_plot_data <- q3_data %>%
  select(
    year,
    `Montien Thai` = montien_reviewcount,
    `Other Chinatown Restaurants` = chinatown_avg_reviewcount
  ) %>%
  pivot_longer(
    cols = -year,
    names_to = "Restaurant Group",
    values_to = "Review Count"
  )

competition_subtitle <- sprintf(
  "Other Chinatown restaurants represented increased from %s in %s to %s in %s",
  first(q3_data$other_restaurant_count),
  first(q3_data$year),
  last(q3_data$other_restaurant_count),
  last(q3_data$year)
)

q3_plot <- ggplot(
  q3_plot_data,
  aes(x = year, y = `Review Count`, color = `Restaurant Group`)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c(
    "Montien Thai" = "#F8766D",
    "Other Chinatown Restaurants" = "#00BFC4"
  )) +
  scale_x_continuous(breaks = sort(unique(q3_plot_data$year))) +
  labs(
    title = "Annual Review Counts: Montien Thai vs. Chinatown",
    subtitle = competition_subtitle,
    x = "Year",
    y = "Annual Review Count",
    color = "Restaurant Group"
  ) +
  portfolio_theme() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(q3_plot)

ggsave(
  file.path(figure_dir, "figure3_annual_review_counts.png"),
  plot = q3_plot,
  width = 10,
  height = 5,
  dpi = 300
)

# =============================================================================
# 7. REPRODUCIBILITY RECORD
# =============================================================================

capture.output(
  sessionInfo(),
  file = file.path(output_dir, "session_info.txt")
)

message(
  "Analysis complete. Tables were saved to ", table_dir,
  " and figures were saved to ", figure_dir, "."
)

