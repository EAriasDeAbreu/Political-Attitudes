# ******************************************************************************
# ******************************************************************************
# *Authors: 
# *Coder: Edmundo Arias De Abreu
# *Project: HEC Project
# *Data: Panel_v1.dta + shapefile
# *Stage: Descriptive Stats
# 
# *Last checked: 06.04.2024
# 
# /*
# ******************************************************************************
# *                                 Contents                                   *
# ******************************************************************************
#   
# This script aims to ....
#
#
#    
# 
#     Output:
#       - Figures
# 
# ******************************************************************************
# Clear the Environment
# ---------------------------------------------------------------------------- #

rm(list = ls())

# ---------------------------------------------------------------------------- #
# Load Necessary Libraries
# ---------------------------------------------------------------------------- #
library(tidyverse)  # Essentials
library(readxl)     # For reading Excel files
library(openxlsx)   # For exporting Excel files
library(haven)      # For Stata files
library(sf)         # For spatial data
library(scales)
# ---------------------------------------------------------------------------- #
# Data Import: Spatial Data
# ---------------------------------------------------------------------------- #
zip_file_path <- "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/1:_RawData/Shapefile/Municipios.zip"
extraction_directory <- "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/1:_RawData/Shapefile/Extracted"

# Corrected argument name
unzip(zip_file_path, exdir = extraction_directory)

# Adjust the path to where you've extracted the .shp file
shapefile_path <- paste0(extraction_directory, "/Servicios_P%C3%BAblicos_-_Municipios.shp")

# Read the shapefile
mun <- st_read(shapefile_path)

mun <- mun %>%
  mutate(
    # Ensure the department code is treated as a two-digit string
    DPTO_CCDGO = sprintf("%02d", as.numeric(DPTO_CCDGO)),
    # Ensure the municipality code is treated as a three-digit string
    MPIO_CCDGO = sprintf("%03d", as.numeric(MPIO_CCDGO)),
    # Concatenate the formatted strings to create the new ID
    id = paste0(DPTO_CCDGO, MPIO_CCDGO)
  )

# ---------------------------------------------------------------------------- #
# Data Import: Stata Data
# ---------------------------------------------------------------------------- #
df <- read_dta("/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/2:_ProcessedData/MergedData/Final/Panel_v3.dta")

df <- df %>%
  mutate(
    id = sprintf("%05d", as.numeric(id))
  )


# ---------------------------------------------------------------------------- #
# Data Map: Violence Across Municipalities
# ---------------------------------------------------------------------------- #

# group
df_summary <- df %>%
  group_by(id) %>%
  summarise(total_violence = sum(Violencia, na.rm = TRUE))

merged_data <- mun %>%
  left_join(df_summary, by = "id")

# Adding a small constant to total_violence to ensure no zero values for log transformation
merged_data$total_violence <- merged_data$total_violence + 1

# Define breaks and corresponding labels for the color scale
breaks <- c(min(merged_data$total_violence, na.rm = TRUE), max(merged_data$total_violence, na.rm = TRUE))
labels <- c("Bajo", "Alto")

# plot
violence_plot <- ggplot(data = merged_data) +
  geom_sf(aes(fill = total_violence), color = NA) +
  scale_fill_gradientn(colors = c("pink", "red4"),
                       breaks = breaks, labels = labels,
                       name = "Índice de Violencia",
                       limits = range(merged_data$total_violence),
                       na.value = "lightgrey",  # Correct placement of na.value
                       trans = "log") +  # Log transformation
  labs(subtitle = "Pooled (1972-2007)") +
  theme_minimal() +
  theme(legend.position = "right",
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

print(violence_plot)
ggsave("/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/4:_Output/Figures/Viol_Mun.pdf", plot = violence_plot, width = 10, height = 8, dpi = 300)

# ---------------------------------------------------------------------------- #
# Data Map: Votes & Parties Across Municipalities
# ---------------------------------------------------------------------------- #



# Data preparation with party leaning calculation
df_summary2 <- df %>%
  group_by(id) %>%
  summarise(
    diff_votes = sum(PARTIDOLIBERALCOLOMBIANO, na.rm = TRUE) - sum(PARTIDOCONSERVADORCOLOMBIANO, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(party_leaning = case_when(
    diff_votes > 0 ~ "Liberal",
    diff_votes < 0 ~ "Conservative",
    TRUE ~ "Balanced"  # Handles cases where diff_votes == 0
  ))

# Merging updated summary with spatial data
merged_data <- mun %>%
  left_join(df_summary2, by = "id")

# Plot using categorized data
political_leaning_plot <- ggplot(data = merged_data) +
  geom_sf(aes(fill = party_leaning), color = NA) +
  scale_fill_manual(values = c("Liberal" = "red", "Conservative" = "blue", "Balanced" = "lightgrey"),
                    name = "Partido Dominante") +
  labs(title = "Inclinación Política de los Municipios Colombianos",
       subtitle = "Categorización por partido dominante (1972-2007)",
       caption = "Categorías: Liberal, Conservador, Equilibrado") +
  theme_minimal() +
  theme(legend.position = "right",
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

print(political_leaning_plot)


#  save the plot
ggsave("/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/4:_Output/Figures/Inc_Pol.pdf", plot = political_leaning_plot, width = 10, height = 8, dpi = 300)

