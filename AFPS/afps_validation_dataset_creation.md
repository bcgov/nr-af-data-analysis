# AFPS Validation Dataset Creation

This script performs price anomaly detection on the AFPS dataset and produces two outputs: an excel file of flagged anomalous records, and an excel file containing per-company plain-text data blocks formatted for mass email notification (using mail merge).

---

## Setup

```r
options(scipen = 999)  # suppress scientific notation

library(dplyr)
library(readxl)
library(writexl)
library(tidyverse)
```
#load AFPS dataset as 'AFPS', ensuring there is a 'price' column (value/quantity to determine $/kg) 
---

## Anomaly Detection

### Filter High-Value Products

Caviar and roe are excluded before anomaly detection, as their elevated prices would be flagged as outliers by default. A simple manual check that everything is in order for these rows should suffice.

```r
AFPS <- AFPS %>%
  filter(is.na(product) | !product %in% c("Caviar", "Roe", "roe"))
```

### Flag Price Anomalies

Anomalies are identified per species using a **Median Absolute Deviation (MAD)** approach, which is robust to outliers. A record is flagged if its price deviates from the species median by more than `threshold × MAD`, or if the price is implausibly low (≤ $0.30/kg).

```r
threshold <- 2.5

anomalies <- AFPS %>%
  group_by(species) %>%
  mutate(
    Median_Price = median(price, na.rm = TRUE),
    MAD_Price    = mad(price, na.rm = TRUE),
    Is_Anomaly   = abs(price - Median_Price) > (threshold * MAD_Price) | price <= 0.3
  ) %>%
  ungroup()
```

### Extract and Clean Anomalous Records

```r
pull_anomalies <- anomalies %>%
  filter(Is_Anomaly == TRUE)

# Ensure numeric types
pull_anomalies$value    <- as.numeric(pull_anomalies$value)
pull_anomalies$quantity <- as.numeric(pull_anomalies$quantity)
pull_anomalies$price    <- as.numeric(pull_anomalies$price)

# Round all numeric columns to 2 decimal places
pull_anomalies <- pull_anomalies %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))
```

### Export Anomaly Dataset

```r
write_xlsx(pull_anomalies, file = "AFPS_Anomalies.csv", row.names = FALSE)
```

---

## Build Per-Company Email Data Blocks

Anomalous records are formatted into fixed-width plain-text tables, one per company, suitable for pasting directly into notification emails.

### Format Columns

Dollar signs are prepended to value and price fields; quantity is cast to character for uniform string handling.

```r
df_clean <- pull_anomalies %>%
  mutate(
    quantity = as.character(quantity),
    value    = ifelse(is.na(value), NA_character_, paste0("$", value)),
    price    = ifelse(is.na(price), NA_character_, paste0("$", price))
  )
```

### Compute Column Widths

Column widths are set dynamically to fit the widest value in each column (including the header label), ensuring the table aligns correctly regardless of content length.

```r
species_width  <- max(nchar("species"),      nchar(df_clean$species),  na.rm = TRUE)
quantity_width <- max(nchar("Quantity (kg)"), nchar(df_clean$quantity), na.rm = TRUE)
value_width    <- max(nchar("value"),         nchar(df_clean$value),    na.rm = TRUE)
price_width    <- max(nchar("Price ($/kg)"), nchar(df_clean$price),    na.rm = TRUE)
```

### Build Row Strings

Each record is formatted as a padded, pipe-delimited string.

```r
df_clean <- df_clean %>%
  mutate(
    Row_Info = paste0(
      str_pad(species,  species_width,  side = "right"), " | ",
      str_pad(quantity, quantity_width, side = "right"), " | ",
      str_pad(value,    value_width,    side = "right"), " | ",
      str_pad(price,    price_width,    side = "right")
    )
  )
```

### Build Header and Divider

```r
header <- paste0(
  str_pad("species",      species_width,  side = "right"), " | ",
  str_pad("Quantity (kg)", quantity_width, side = "right"), " | ",
  str_pad("value",        value_width,    side = "right"), " | ",
  str_pad("Price ($/kg)", price_width,    side = "right")
)

divider <- paste(rep("-", nchar(header)), collapse = "")
```

### Group into Per-Company Blocks

Each company's rows are collapsed into a single multi-line string, prepended with the shared header and divider.

```r
company_summary <- df_clean %>%
  group_by(company) %>%
  summarise(
    Data_Block = paste(c(header, divider, Row_Info), collapse = "\n"),
    .groups = "drop"
  )
```

### Join Company Emails

A distinct email lookup is built from the anomaly records and joined onto the summary, giving one row per company with its contact email and formatted data block.

```r
email_lookup <- df_clean %>%
  dplyr::select(company, email) %>%
  distinct()

company_summary_final <- company_summary %>%
  left_join(email_lookup, by = "company")
```

---

## Export

```r
write_xlsx(company_summary_final, "company_summary.xlsx")
```
