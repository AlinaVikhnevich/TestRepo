# Diagnostics script for Kosovo/Cyprus/Somalia polygon coverage
library(tidyverse)
library(readr)
library(jsonlite)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(dplyr)

`%||%` <- function(x, y) {
  if (is.null(x) || (is.character(x) && all(is.na(x)))) {
    return(y)
  }
  x
}

# Data load and targeted recodes only
df <- read_csv("life-expectancy.csv")
df <- df %>%
  mutate(
    Code = case_when(
      Entity == "Kosovo" & Code %in% c("OWID_KOS", "-99") ~ "XKX",
      Entity == "Kosovo" & is.na(Code) ~ "XKX",
      TRUE ~ Code
    )
  ) %>%
  mutate(Code = stringr::str_trim(toupper(Code))) %>%
  filter(!is.na(Code) & Code != "") %>%
  select(Entity, Code, Year, `Period life expectancy at birth`) %>%
  rename(life_expectancy = `Period life expectancy at birth`)

# Base Natural Earth polygons
world_raw <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

cyprus_name_match <- function(x) {
  stringr::str_detect(x, regex("^Cyprus$|^N\\.?\\s*Cyprus$|^Northern Cyprus$", ignore_case = TRUE))
}

somaliland_name_match <- function(x) {
  stringr::str_detect(x, regex("Somaliland", ignore_case = TRUE))
}

world <- world_raw %>%
  mutate(
    iso_a3 = case_when(
      cyprus_name_match(name)                    ~ "CYP",
      somaliland_name_match(name)                ~ "SOM",
      stringr::str_detect(name, regex("Kosovo", ignore_case = TRUE)) ~ "XKX",
      TRUE ~ iso_a3
    )
  ) %>%
  mutate(
    iso_a3 = as.character(iso_a3),
    iso_a3 = stringr::str_trim(toupper(iso_a3))
  ) %>%
  filter(!is.na(iso_a3) & iso_a3 != "")

map_df <- world %>%
  left_join(df, by = c("iso_a3" = "Code")) %>%
  filter(!is.na(geometry), !is.na(Year))

tmp_geojson <- tempfile(fileext = ".geojson")
sf::st_write(world, tmp_geojson, driver = "GeoJSON", quiet = TRUE)
world_geojson <- jsonlite::read_json(tmp_geojson, simplifyVector = FALSE)

feature_rows <- purrr::imap_dfr(world_geojson$features, function(feat, idx) {
  props <- feat$properties
  tibble::tibble(
    feature_index = idx,
    name = props$name %||% props$NAME %||% NA_character_,
    admin = props$admin %||% props$ADMIN %||% NA_character_,
    sovereignt = props$sovereignt %||% props$SOVEREIGNT %||% NA_character_,
    iso_a3 = props$iso_a3 %||% props$ISO_A3 %||% NA_character_
  )
})

cyprus_features_before <- feature_rows %>%
  filter(
    stringr::str_detect(name, regex("Cyprus", ignore_case = TRUE)) |
      stringr::str_detect(admin, regex("Cyprus", ignore_case = TRUE)) |
      stringr::str_detect(sovereignt, regex("Cyprus", ignore_case = TRUE))
  )

somalia_features_before <- feature_rows %>%
  filter(
    stringr::str_detect(name, regex("Somali", ignore_case = TRUE)) |
      stringr::str_detect(admin, regex("Somali", ignore_case = TRUE)) |
      stringr::str_detect(sovereignt, regex("Somali", ignore_case = TRUE))
  )

world_geojson$features <- purrr::map(world_geojson$features, function(feat) {
  props <- feat$properties
  name_val <- props$name %||% props$NAME %||% ""
  admin_val <- props$admin %||% props$ADMIN %||% ""
  sovereignt_val <- props$sovereignt %||% props$SOVEREIGNT %||% ""

  if (
    stringr::str_detect(name_val, regex("N\\.?\\s*Cyprus|Northern Cyprus", ignore_case = TRUE)) |
      stringr::str_detect(admin_val, regex("N\\.?\\s*Cyprus|Northern Cyprus", ignore_case = TRUE)) |
      stringr::str_detect(sovereignt_val, regex("N\\.?\\s*Cyprus|Northern Cyprus", ignore_case = TRUE))
  ) {
    props$iso_a3 <- "CYP"
    props$admin <- if (nzchar(admin_val)) admin_val else "Cyprus"
    props$sovereignt <- if (nzchar(sovereignt_val)) sovereignt_val else "Cyprus"
  }

  if (
    stringr::str_detect(name_val, regex("Somaliland", ignore_case = TRUE)) |
      stringr::str_detect(admin_val, regex("Somaliland", ignore_case = TRUE)) |
      stringr::str_detect(sovereignt_val, regex("Somaliland", ignore_case = TRUE))
  ) {
    props$iso_a3 <- "SOM"
    if (!nzchar(admin_val)) props$admin <- "Somalia"
    if (!nzchar(sovereignt_val)) props$sovereignt <- "Somalia"
  }

  if (stringr::str_detect(name_val, regex("Kosovo", ignore_case = TRUE)) ||
      stringr::str_detect(admin_val, regex("Kosovo", ignore_case = TRUE)) ||
      stringr::str_detect(sovereignt_val, regex("Kosovo", ignore_case = TRUE))) {
    props$iso_a3 <- "XKX"
    if (!nzchar(admin_val)) props$admin <- "Kosovo"
    if (!nzchar(sovereignt_val)) props$sovereignt <- "Kosovo"
  }

  if (!is.null(props$iso_a3)) {
    feat$properties$iso_a3 <- stringr::str_trim(toupper(props$iso_a3))
  }
  if (!is.null(props$admin)) {
    feat$properties$admin <- props$admin
  }
  if (!is.null(props$sovereignt)) {
    feat$properties$sovereignt <- props$sovereignt
  }

  feat
})

feature_rows_after <- purrr::imap_dfr(world_geojson$features, function(feat, idx) {
  props <- feat$properties
  tibble::tibble(
    feature_index = idx,
    name = props$name %||% props$NAME %||% NA_character_,
    admin = props$admin %||% props$ADMIN %||% NA_character_,
    sovereignt = props$sovereignt %||% props$SOVEREIGNT %||% NA_character_,
    iso_a3 = props$iso_a3 %||% props$ISO_A3 %||% NA_character_
  )
})

cyprus_features_after <- feature_rows_after %>%
  filter(
    stringr::str_detect(name, regex("Cyprus", ignore_case = TRUE)) |
      stringr::str_detect(admin, regex("Cyprus", ignore_case = TRUE)) |
      stringr::str_detect(sovereignt, regex("Cyprus", ignore_case = TRUE))
  )

somalia_features_after <- feature_rows_after %>%
  filter(
    stringr::str_detect(name, regex("Somali", ignore_case = TRUE)) |
      stringr::str_detect(admin, regex("Somali", ignore_case = TRUE)) |
      stringr::str_detect(sovereignt, regex("Somali", ignore_case = TRUE))
  )

diagnostic_year <- 2023

diag_counts <- feature_rows_after %>%
  filter(iso_a3 %in% c("XKX", "CYP", "SOM", "-99")) %>%
  count(iso_a3, name = "n")

northern_cyprus_rows <- feature_rows_after %>%
  filter(
    stringr::str_detect(coalesce(admin, ""), regex("N\\.?\\s*Cyprus|Northern Cyprus", ignore_case = TRUE)) |
      stringr::str_detect(coalesce(name, ""), regex("N\\.?\\s*Cyprus|Northern Cyprus", ignore_case = TRUE)) |
      stringr::str_detect(coalesce(sovereignt, ""), regex("N\\.?\\s*Cyprus|Northern Cyprus", ignore_case = TRUE))
  )

somaliland_rows <- feature_rows_after %>%
  filter(
    stringr::str_detect(coalesce(name, ""), regex("Somaliland", ignore_case = TRUE)) |
      stringr::str_detect(coalesce(admin, ""), regex("Somaliland", ignore_case = TRUE)) |
      stringr::str_detect(coalesce(sovereignt, ""), regex("Somaliland", ignore_case = TRUE))
  )

diagnostic_map_locations <- world %>%
  sf::st_drop_geometry() %>%
  select(iso_a3, name) %>%
  arrange(iso_a3)

diagnostic_year_values <- df %>%
  filter(Year == diagnostic_year) %>%
  select(Code, life_expectancy)

diagnostic_year_df <- diagnostic_map_locations %>%
  left_join(diagnostic_year_values, by = c("iso_a3" = "Code")) %>%
  rename(Entity = name, Code = iso_a3) %>%
  mutate(Year = diagnostic_year)

kosovo_rows_2023 <- diagnostic_year_df %>%
  filter(!is.na(Entity) & Entity == "Kosovo") %>%
  distinct(Code, Entity, life_expectancy)

codes_missing_geo <- setdiff(
  unique(stats::na.omit(diagnostic_year_df$Code)),
  unique(stats::na.omit(feature_rows_after$iso_a3))
)

cat("GeoJSON feature counts (XKX/CYP/SOM/-99):\n")
print(diag_counts)

cat("\nNorthern Cyprus feature rows (after patch):\n")
print(northern_cyprus_rows)

cat("\nSomaliland feature rows (after patch):\n")
print(somaliland_rows)

cat("\nKosovo rows from get_year_data(2023)-equivalent: should be XKX only:\n")
print(kosovo_rows_2023)

cat("\nTop codes in year data not found in GeoJSON iso_a3 (up to 30):\n")
print(head(codes_missing_geo, 30))

# Helper summaries for report.txt expectations
cat("\nFeature counts before/after (XKX/CYP/SOM/-99):\n")
print(
  tibble::tibble(
    iso_a3 = c("XKX", "CYP", "SOM", "-99"),
    before = c(
      sum(feature_rows$iso_a3 == "XKX", na.rm = TRUE),
      sum(feature_rows$iso_a3 == "CYP", na.rm = TRUE),
      sum(feature_rows$iso_a3 == "SOM", na.rm = TRUE),
      sum(feature_rows$iso_a3 == "-99", na.rm = TRUE)
    ),
    after = c(
      sum(feature_rows_after$iso_a3 == "XKX", na.rm = TRUE),
      sum(feature_rows_after$iso_a3 == "CYP", na.rm = TRUE),
      sum(feature_rows_after$iso_a3 == "SOM", na.rm = TRUE),
      sum(feature_rows_after$iso_a3 == "-99", na.rm = TRUE)
    )
  )
)
