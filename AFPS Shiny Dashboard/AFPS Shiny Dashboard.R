# =============================================================================
# BC Seafood Processing Dashboard 2024
# Annual Fisheries Production Schedule (AFPS) Shiny App
#
# Purpose: Visualizes seafood processing wholesale values across BC 
#          administrative regions with interactive filtering by species 
#          and location.
# =============================================================================


# =============================================================================
# 1. LIBRARIES
# =============================================================================

library(dplyr)           
library(tidygeocoder)    
library(sf)              
library(writexl)         
library(readxl)          
library(stringr)         
library(shiny)           
library(ggplot2)         
library(leaflet)         
library(scales)       
library(plotly)          
library(DT)              
library(tidyr)           
library(rsconnect)       
library(bslib)           
library(shinyWidgets)    
library(waiter)         
library(leaflet.extras)  


# =============================================================================
# 2. DATA LOADING
# To load data, sync the folder on SharePoint (project 1.3a -> 2025 -> Analysis and Results -> Shiny App)
# To your OneDrive, and use this path to define the environment variable SHAREPOINT_PATH
# =============================================================================

#file.edit("~/.Renviron") to open environment variables. Add SHAREPOINT_PATH= with your OneDrive path.

sharepoint <- Sys.getenv("SHAREPOINT_PATH")

# Load AFPS data
AFPS_2024 <- read_excel(
  file.path(sharepoint, "AFPS_2024.xlsx")
)

# Load shapefile
shapefile_path <- file.path(
  sharepoint, "ABMS_LAA_polygon.shp"
)

# =============================================================================
# 3. SPATIAL DATA PREP
# Reads BC administrative region shapefile, transforms CRS, and spatially
# joins AFPS data points to their corresponding administrative regions.
# =============================================================================

bc_regions <- st_read(shapefile_path)
bc_regions <- st_transform(bc_regions, crs = 4326)   # Reproject to WGS84 (lat/lon)

# Remove records missing coordinates (non-BC locations)
AFPS_2024 <- AFPS_2024 %>%
  filter(!is.na(Longitude) & !is.na(Latitude))

# Convert AFPS data to spatial object and reproject to match shapefile CRS
df_sf <- st_as_sf(AFPS_2024, coords = c("Longitude", "Latitude"), crs = 4326)
df_sf <- st_transform(df_sf, st_crs(bc_regions))

# Fix any invalid geometries in the shapefile before joining
bc_regions <- st_make_valid(bc_regions)

# Spatial join: assign each AFPS point to its administrative region
df_with_regions <- st_join(df_sf, bc_regions)

# Some points may fall in multiple regions (e.g., city within a district).
# Resolve ambiguity by keeping the most specific match using a priority rule:
#   1 = City, 2 = District, 3 = Region, 4 = Other
df_clean <- df_with_regions %>%
  mutate(priority = case_when(
    str_detect(AA_NAME, regex("city",     ignore_case = TRUE)) ~ 1,
    str_detect(AA_NAME, regex("district", ignore_case = TRUE)) ~ 2,
    str_detect(AA_NAME, regex("region",   ignore_case = TRUE)) ~ 3,
    TRUE                                                       ~ 4
  )) %>%
  group_by(across(1:17)) %>%          # Group by original AFPS columns only
  slice_min(priority, with_ties = FALSE) %>%
  ungroup() %>%
  select(-priority)

# Keep only shapefile regions that appear in the cleaned data
bc_regions_clean <- bc_regions %>%
  filter(AA_NAME %in% df_clean$AA_NAME)


# =============================================================================
# 4. SUMMARY DATA PREP
# Pre-compute aggregations used by the dashboard (map, charts, sidebar stats).
# All calculations drop spatial geometry since we only need tabular summaries.
# =============================================================================

# Total wholesale value per region
region_totals <- df_clean %>%
  st_drop_geometry() %>%
  group_by(AA_NAME) %>%
  summarize(total_wholesale_value = sum(`Wholesale Value`, na.rm = TRUE), .groups = "drop")

# Total quantity (KG) per region
region_totals_quantity <- df_clean %>%
  st_drop_geometry() %>%
  group_by(AA_NAME) %>%
  summarize(total_quantity_kg = sum(`Quantity (KG)`, na.rm = TRUE), .groups = "drop")

# Wholesale value by region × species
region_species <- df_clean %>%
  st_drop_geometry() %>%
  group_by(AA_NAME, Species) %>%
  summarize(species_value = sum(`Wholesale Value`, na.rm = TRUE), .groups = "drop")

# Quantity (KG) by region × species
region_species_quantity <- df_clean %>%
  st_drop_geometry() %>%
  group_by(AA_NAME, Species) %>%
  summarize(species_quantity_kg = sum(`Quantity (KG)`, na.rm = TRUE), .groups = "drop")

# Top species per region (by wholesale value)
region_top_species <- region_species %>%
  group_by(AA_NAME) %>%
  slice_max(species_value, n = 1, with_ties = FALSE) %>%
  select(AA_NAME, top_species = Species, top_value = species_value)

# Master region summary table (value + top species + % contribution)
region_summary <- region_totals %>%
  left_join(region_top_species, by = "AA_NAME") %>%
  mutate(value_contribution = total_wholesale_value / sum(total_wholesale_value, na.rm = TRUE) * 100)

# Spatial layer for the map: regions with all summary fields joined
bc_regions_4326 <- bc_regions_clean %>%
  st_transform(crs = 4326) %>%
  left_join(region_summary,        by = "AA_NAME") %>%
  left_join(region_totals_quantity, by = "AA_NAME")

# Dropdown choices for UI filters
species_choices <- c("All Species", sort(unique(region_species$Species)))
region_choices  <- c("All Regions", sort(unique(bc_regions_4326$AA_NAME)))

# License counts — used in the sidebar summary cards
license_counts_total <- df_clean %>%
  st_drop_geometry() %>%
  select(Company, `License Type`) %>%
  distinct() %>%
  group_by(`License Type`) %>%
  summarize(count = n(), .groups = "drop")

license_counts_by_region <- df_clean %>%
  st_drop_geometry() %>%
  select(AA_NAME, Company, `License Type`) %>%
  distinct() %>%
  group_by(AA_NAME, `License Type`) %>%
  summarize(count = n(), .groups = "drop")

# =============================================================================
# 5. CUSTOM CSS
# Visual enhancements layered on top of the bslib/Bootswatch theme.
# =============================================================================

custom_css <- "
  /* Page background gradient */
  .content-wrapper, .content {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
  }

  .main-header .logo {
    font-weight: bold;
    font-size: 24px;
  }

  /* Map and chart containers */
  .leaflet-container {
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }

  .plotly {
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }

  /* Card hover effect */
  .card {
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    transition: transform 0.2s;
  }

  .card:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 12px rgba(0,0,0,0.15);
  }

  .selectize-input    { border-radius: 5px !important; }
  .btn-clear-filter   { margin-top: 5px; border-radius: 5px; }

  /* Sidebar summary stat cards */
  .stat-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 15px;
    border-radius: 10px;
    margin-bottom: 10px;
  }

  .stat-number { font-size: 28px; font-weight: bold; }
  .stat-label  { font-size: 14px; opacity: 0.9; }

  /* Fullscreen map toggle */
  .fullscreen-map {
    position: fixed !important;
    top: 0 !important; left: 0 !important;
    width: 100vw !important; height: 100vh !important;
    z-index: 9999 !important;
    background: white !important;
    padding: 20px !important;
    box-sizing: border-box !important;
  }

  .fullscreen-map .card-body {
    height: calc(100vh - 120px) !important;
    padding: 0 !important;
  }

  .fullscreen-map .leaflet-container {
    height: 100% !important;
    width: 100% !important;
  }

  /* Data table header styling */
  table.dataTable thead th {
    font-size: 14px;
    font-weight: 600;
  }
"


# =============================================================================
# 6. UI
# =============================================================================

ui <- page_navbar(
  title = div(
    icon("fish", lib = "font-awesome"),
    "BC Seafood Processing Dashboard 2024",
    style = "display: inline-flex; align-items: center; gap: 10px;"
  ),
  
  # --- Bootstrap/bslib theme ---
  theme = bs_theme(
    version    = 5,
    bootswatch = "cosmo",
    primary    = "#667eea",
    secondary  = "#764ba2",
    success    = "#48bb78",
    info       = "#4299e1",
    warning    = "#ed8936",
    danger     = "#f56565",
    base_font    = font_google("Inter"),
    heading_font = font_google("Poppins"),
    code_font    = font_google("JetBrains Mono")
  ),
  
  # ---- Dashboard tab -------------------------------------------------------
  nav_panel(
    title = "Dashboard",
    icon  = icon("chart-line"),
    
    tags$head(
      tags$style(HTML(custom_css)),
      tags$style(HTML("
        .waiter-overlay { background-color: rgba(102, 126, 234, 0.1) !important; }
      "))
    ),
    
    layout_sidebar(
      # --- Sidebar ----------------------------------------------------------
      sidebar = sidebar(
        width = 350,
        bg    = "#f8f9fa",
        
        # Filter card
        card(
          card_header(class = "bg-primary text-white", icon("filter"), "Filters & Search"),
          card_body(
            
            # Species filter
            pickerInput(
              inputId  = "speciesSelect",
              label    = div(icon("fish"), "Filter by Species:"),
              choices  = species_choices,
              selected = "All Species",
              options  = list(
                `live-search`             = TRUE,
                `live-search-placeholder` = "Type to search...",
                `actions-box`             = TRUE,
                size  = 10,
                style = "btn-outline-primary"
              ),
              width = "100%"
            ),
            actionButton("clearSpecies", "Clear Species Filter",
                         icon = icon("times"),
                         class = "btn-sm btn-outline-secondary btn-clear-filter",
                         width = "100%"),
            
            br(), br(),
            
            # Region filter
            pickerInput(
              inputId  = "regionSelect",
              label    = div(icon("map-marker-alt"), "Filter by Location:"),
              choices  = region_choices,
              selected = "All Regions",
              options  = list(
                `live-search`             = TRUE,
                `live-search-placeholder` = "Type to search...",
                `actions-box`             = TRUE,
                size  = 10,
                style = "btn-outline-primary"
              ),
              width = "100%"
            ),
            actionButton("clearRegion", "Clear Location Filter",
                         icon = icon("times"),
                         class = "btn-sm btn-outline-secondary btn-clear-filter",
                         width = "100%"),
            
            br(), br(),
            
            # Reset all filters button
            div(
              class = "d-grid gap-2",
              actionButton("resetAll", "Reset All Filters",
                           icon  = icon("refresh"),
                           class = "btn-warning",
                           width = "100%")
            )
          )
        ),
        
        # Summary statistics card (total value + license counts)
        card(
          card_header(class = "bg-info text-white", icon("chart-bar"), "Summary Statistics"),
          card_body(uiOutput("summaryStatsCards"))
        ),
        
        # Quantity table card (mirrors bar chart data)
        card(
          card_header(class = "bg-success text-white", icon("weight"), "Quantity (KG)"),
          card_body(DT::dataTableOutput("quantityTable"))
        )
      ),
      
      # --- Main panel -------------------------------------------------------
      layout_columns(
        col_widths = 12,
        
        # Map card
        card(
          card_header(
            class = "d-flex justify-content-between align-items-center",
            div(icon("map"), "Regional Distribution Map"),
            div(
              # Reset map view to BC extent
              actionButton("resetMapView", "",
                           icon  = icon("home"),
                           class = "btn-sm btn-outline-secondary",
                           title = "Reset Map View"),
              # Toggle fullscreen (pure JS, no server round-trip needed)
              actionButton(
                "toggleFullscreen", "",
                icon    = icon("expand"),
                class   = "btn-sm btn-outline-secondary",
                title   = "Toggle Fullscreen",
                onclick = "
                  var mapCard = this.closest('.card');
                  if (mapCard.classList.contains('fullscreen-map')) {
                    mapCard.classList.remove('fullscreen-map');
                    this.querySelector('i').className = 'fa fa-expand';
                    this.title = 'Toggle Fullscreen';
                  } else {
                    mapCard.classList.add('fullscreen-map');
                    this.querySelector('i').className = 'fa fa-compress';
                    this.title = 'Exit Fullscreen';
                  }
                  setTimeout(() => {
                    window.dispatchEvent(new Event('resize'));
                    if (window.map) window.map.invalidateSize();
                  }, 200);
                "
              )
            )
          ),
          card_body(
            waiter::withWaiter(
              leafletOutput("bcMap", height = 520),
              html  = waiter::spin_wave(),
              color = "#667eea"
            )
          )
        ),
        
        # Bar chart card
        card(
          card_header(icon("chart-column"), "Value Analysis"),
          card_body(
            waiter::withWaiter(
              plotlyOutput("valuePlot", height = 420),
              html  = waiter::spin_wave(),
              color = "#667eea"
            )
          )
        )
      )
    )
  ),
  
  # ---- About tab -----------------------------------------------------------
  nav_panel(
    title = "About",
    icon  = icon("info-circle"),
    card(
      card_header("About This Dashboard"),
      card_body(
        h4("Annual Fisheries Production Schedule 2024"),
        p("This dashboard visualizes seafood processing wholesale values across British Columbia administrative regions."),
        br(),
        h5("Features:"),
        tags$ul(
          tags$li("Interactive map showing regional distribution"),
          tags$li("Dynamic filtering by species and location"),
          tags$li("Real-time summary statistics"),
          tags$li("Quantity tracking in kilograms"),
          tags$li("License type analysis")
        ),
        h5(tags$b("Important Notes:")),
        p("Please do not share the login credentials for this app with members of the public. Please also double check with Jonathon (jonathon.vieira@gov.bc.ca) before providing figures sourced from this app to members of the public."),
        h5("Data Source:"),
        p("Data compiled from the 2024 Annual Fisheries Production Schedule (AFPS), https://www2.gov.bc.ca/gov/content/industry/agriculture-seafood/statistics/reporting-requirements")
      )
    )
  ),
  
  nav_spacer(),
  
  # Dark mode toggle
  nav_item(input_dark_mode(id = "dark_mode", mode = "light"))
)


# =============================================================================
# 7. SERVER
# =============================================================================

server <- function(input, output, session) {
  
  # Initialize waiter (loading overlay)
  w <- Waiter$new()
  
  # Authenticate user via shinymanager
  res_auth <- secure_server(check_credentials = check_credentials(credentials))
  
  # Helper: format a number as a dollar string with no decimals
  format_currency <- function(x) {
    paste0("$", formatC(x, format = "f", big.mark = ",", digits = 0))
  }
  
  # ---------------------------------------------------------------------------
  # Filter button observers
  # ---------------------------------------------------------------------------
  
  observeEvent(input$clearSpecies, {
    updatePickerInput(session, "speciesSelect", selected = "All Species")
  })
  
  observeEvent(input$clearRegion, {
    updatePickerInput(session, "regionSelect", selected = "All Regions")
  })
  
  observeEvent(input$resetAll, {
    updatePickerInput(session, "speciesSelect", selected = "All Species")
    updatePickerInput(session, "regionSelect",  selected = "All Regions")
  })
  
  # Reset map to full BC extent
  observeEvent(input$resetMapView, {
    leafletProxy("bcMap") %>%
      setView(lng = -125, lat = 54, zoom = 5)
  })
  
  # ---------------------------------------------------------------------------
  # Reactive: map data
  # Determines which polygons and fill values to display based on current filters.
  # Returns a list with: data (sf), mode ("species" or "totals"), label_species
  # ---------------------------------------------------------------------------
  
  map_data_reactive <- reactive({
    sel_species <- input$speciesSelect
    sel_region  <- input$regionSelect
    
    if (sel_species != "All Species") {
      # Species selected: colour by value for that species only
      tmp <- bc_regions_4326 %>%
        left_join(
          region_species %>%
            filter(Species == sel_species) %>%
            select(AA_NAME, species_value),
          by = "AA_NAME"
        )
      
      if (sel_region != "All Regions") tmp <- tmp %>% filter(AA_NAME == sel_region)
      
      tmp <- tmp %>%
        filter(!is.na(species_value) & species_value > 0) %>%
        mutate(area_num   = as.numeric(st_area(geometry)),
               fill_value = species_value) %>%
        arrange(desc(area_num))
      
      return(list(data = tmp, mode = "species", label_species = sel_species))
      
    } else {
      # No species filter: colour by total wholesale value
      tmp <- bc_regions_4326 %>%
        mutate(
          total_wholesale_value = replace_na(total_wholesale_value, 0),
          top_species           = replace_na(top_species, "No data")
        )
      
      if (sel_region != "All Regions") tmp <- tmp %>% filter(AA_NAME == sel_region)
      
      tmp <- tmp %>%
        mutate(area_num   = as.numeric(st_area(geometry)),
               fill_value = total_wholesale_value) %>%
        arrange(desc(area_num))
      
      return(list(data = tmp, mode = "totals", label_species = "Top Species"))
    }
  })
  
  # ---------------------------------------------------------------------------
  # Output: Leaflet map
  # Renders choropleth with large and small polygons in separate map panes so
  # smaller regions (e.g., cities) are always drawn on top of larger ones.
  # ---------------------------------------------------------------------------
  
  output$bcMap <- renderLeaflet({
    md         <- map_data_reactive()
    map_data   <- md$data
    mode       <- md$mode
    label_species <- md$label_species
    
    # If no data matches the current filters, show an empty map with a message
    if (nrow(map_data) == 0) {
      return(
        leaflet(bc_regions_4326) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          addControl(
            html     = HTML("<b>No regions have non-zero value for the selected filters.</b>"),
            position = "topright"
          ) %>%
          setView(lng = -125, lat = 54, zoom = 5)
      )
    }
    
    # Indigo colour ramp: light → dark with increasing value
    pal <- colorNumeric(
      palette  = c("#e0e7ff","#c7d2fe","#a5b4fc","#818cf8","#6366f1","#4f46e5","#4338ca","#3730a3"),
      domain   = map_data$fill_value,
      na.color = "transparent"
    )
    
    # Build hover labels (HTML) for each polygon
    if (mode == "species") {
      labels <- sprintf(
        "<div style='font-size:14px;'>
          <strong style='color:#4338ca;'>%s</strong><br/>
          <span style='color:#6b7280;'>Wholesale Value:</span> <strong>%s</strong><br/>
          <span style='color:#6b7280;'>Species:</span> %s
        </div>",
        map_data$AA_NAME, format_currency(map_data$fill_value), label_species
      ) %>% lapply(htmltools::HTML)
      
    } else {
      sel_region <- isolate(input$regionSelect)
      
      if (is.null(sel_region) || sel_region == "All Regions") {
        labels <- sprintf(
          "<div style='font-size:14px;'>
            <strong style='color:#4338ca;'>%s</strong><br/>
            <span style='color:#6b7280;'>Wholesale Value:</span> <strong>%s</strong><br/>
            <span style='color:#6b7280;'>Top Species:</span> %s
          </div>",
          map_data$AA_NAME, format_currency(map_data$fill_value), map_data$top_species
        ) %>% lapply(htmltools::HTML)
        
      } else {
        labels <- sprintf(
          "<div style='font-size:14px;'>
            <strong style='color:#4338ca;'>%s</strong><br/>
            <span style='color:#6b7280;'>Wholesale Value:</span> <strong>%s</strong>
          </div>",
          map_data$AA_NAME, format_currency(map_data$fill_value)
        ) %>% lapply(htmltools::HTML)
      }
    }
    
    # Split polygons into large/small by area (median threshold) so small
    # regions render on top and remain clickable/hoverable
    map_data   <- map_data %>% mutate(area_num = as.numeric(st_area(geometry)))
    area_med   <- median(map_data$area_num, na.rm = TRUE)
    large_polys <- map_data %>% filter(area_num >  area_med)
    small_polys <- map_data %>% filter(area_num <= area_med)
    labels_large <- labels[map_data$area_num >  area_med]
    labels_small <- labels[map_data$area_num <= area_med]
    
    # Shared polygon styling options
    poly_label_opts <- labelOptions(
      style = list(
        "font-weight"  = "normal",
        padding        = "8px",
        "border-radius"= "5px",
        "box-shadow"   = "3px 3px 10px rgba(0,0,0,0.2)"
      ),
      textsize  = "13px",
      direction = "auto"
    )
    
    m <- leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addMapPane("largePolys", zIndex = 400) %>%
      addMapPane("smallPolys", zIndex = 420)
    
    if (nrow(large_polys) > 0) {
      m <- m %>% addPolygons(
        data        = large_polys,
        fillColor   = ~pal(fill_value),
        color       = "white",
        weight      = 2,
        opacity     = 1,
        fillOpacity = 0.7,
        highlight   = highlightOptions(weight = 4, color = "#4338ca", fillOpacity = 0.9, bringToFront = TRUE),
        label       = labels_large,
        labelOptions = poly_label_opts,
        options     = pathOptions(pane = "largePolys"),
        group       = "large"
      )
    }
    
    if (nrow(small_polys) > 0) {
      m <- m %>% addPolygons(
        data        = small_polys,
        fillColor   = ~pal(fill_value),
        color       = "#ffffff",
        weight      = 2.5,
        opacity     = 1,
        fillOpacity = 0.85,
        highlight   = highlightOptions(weight = 5, color = "#4338ca", fillOpacity = 0.95, bringToFront = TRUE),
        label       = labels_small,
        labelOptions = poly_label_opts,
        options     = pathOptions(pane = "smallPolys"),
        group       = "small"
      )
    }
    
    m %>% setView(lng = -125, lat = 54, zoom = 5)
  })
  
  # Zoom map to selected region whenever the region filter changes
  observe({
    req(input$regionSelect)
    proxy <- leafletProxy("bcMap")
    
    if (input$regionSelect != "All Regions") {
      selected_region <- bc_regions_4326 %>% filter(AA_NAME == input$regionSelect)
      
      if (nrow(selected_region) > 0) {
        bbox       <- st_bbox(selected_region)
        xmin <- as.numeric(bbox[1]); ymin <- as.numeric(bbox[2])
        xmax <- as.numeric(bbox[3]); ymax <- as.numeric(bbox[4])
        lng_buffer <- (xmax - xmin) * 0.1
        lat_buffer <- (ymax - ymin) * 0.1
        proxy %>% fitBounds(xmin - lng_buffer, ymin - lat_buffer,
                            xmax + lng_buffer, ymax + lat_buffer)
      }
    } else {
      proxy %>% setView(lng = -125, lat = 54, zoom = 5)
    }
  })
  
  # Also maintain the region zoom when only the species filter changes
  observe({
    req(input$regionSelect, input$speciesSelect)
    
    if (input$regionSelect != "All Regions") {
      selected_region <- bc_regions_4326 %>% filter(AA_NAME == input$regionSelect)
      
      if (nrow(selected_region) > 0) {
        bbox       <- st_bbox(selected_region)
        xmin <- as.numeric(bbox[1]); ymin <- as.numeric(bbox[2])
        xmax <- as.numeric(bbox[3]); ymax <- as.numeric(bbox[4])
        lng_buffer <- (xmax - xmin) * 0.1
        lat_buffer <- (ymax - ymin) * 0.1
        leafletProxy("bcMap") %>%
          fitBounds(xmin - lng_buffer, ymin - lat_buffer,
                    xmax + lng_buffer, ymax + lat_buffer)
      }
    }
  })
  
  # ---------------------------------------------------------------------------
  # Output: Bar chart (Plotly)
  # Four scenarios based on which filters are active:
  #   1. Species only      → top 10 regions for that species
  #   2. Neither filter    → top 10 regions overall
  #   3. Region only       → top 10 species in that region
  #   4. Both filters      → selected species highlighted vs. top 4 others in region
  # ---------------------------------------------------------------------------
  
  output$valuePlot <- renderPlotly({
    sel_species <- input$speciesSelect
    sel_region  <- input$regionSelect
    
    # Shared ggplot2 theme for all chart variants
    plot_theme <- theme_minimal() +
      theme(
        axis.text.y  = element_text(size = 10, color = "#374151", margin = margin(r = 14)),
        axis.text.x  = element_text(size = 10, color = "#374151"),
        plot.title   = element_text(size = 11, face = "bold", color = "#1f2937"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        panel.grid.major.x = element_line(color = "#e5e7eb", size = 0.5)
      )
    
    # --- Scenario 1: Species selected, no region filter ---
    if (sel_species != "All Species" && sel_region == "All Regions") {
      
      plot_data <- region_species %>%
        filter(Species == sel_species, species_value > 0) %>%
        arrange(desc(species_value)) %>%
        head(10) %>%
        mutate(
          AA_NAME      = factor(AA_NAME, levels = AA_NAME[order(species_value)]),
          species_total = sum(species_value, na.rm = TRUE),
          tooltip_text  = paste0(
            "<b>", AA_NAME, "</b><br>",
            "Wholesale Value: ", format_currency(species_value), "<br>",
            "% of Total: ", round(species_value / species_total * 100, 1), "%"
          )
        )
      
      validate(need(nrow(plot_data) > 0, "No regions have non-zero value for the selected species."))
      
      p <- ggplot(plot_data, aes(x = species_value, y = AA_NAME, fill = species_value, text = tooltip_text)) +
        geom_col() +
        scale_fill_gradient(low = "#ddd6fe", high = "#6366f1", guide = "none") +
        scale_x_continuous(labels = scales::dollar_format(scale = 1e-6, suffix = "M"), expand = c(0,0)) +
        labs(x = "Wholesale Value (Millions $)", y = NULL, title = paste("Top Regions:", sel_species)) +
        plot_theme
      
      # --- Scenario 2: No filters active ---
    } else if (sel_species == "All Species" && sel_region == "All Regions") {
      
      plot_data <- region_summary %>%
        arrange(desc(total_wholesale_value)) %>%
        head(10) %>%
        mutate(
          AA_NAME      = factor(AA_NAME, levels = AA_NAME[order(total_wholesale_value)]),
          tooltip_text = paste0(
            "<b>", AA_NAME, "</b><br>",
            "Wholesale Value: ", format_currency(total_wholesale_value), "<br>",
            "% of Total: ", round(value_contribution, 1), "%"
          )
        )
      
      p <- ggplot(plot_data, aes(x = total_wholesale_value, y = AA_NAME, fill = total_wholesale_value, text = tooltip_text)) +
        geom_col() +
        scale_fill_gradient(low = "#ddd6fe", high = "#6366f1", guide = "none") +
        scale_x_continuous(labels = scales::dollar_format(scale = 1e-6, suffix = "M"), expand = c(0,0)) +
        labs(x = "Wholesale Value (Millions $)", y = NULL, title = "Top Regions by Wholesale Value") +
        plot_theme
      
      # --- Scenario 3: Region selected, no species filter ---
    } else if (sel_species == "All Species" && sel_region != "All Regions") {
      
      plot_data <- region_species %>%
        filter(AA_NAME == sel_region, species_value > 0) %>%
        arrange(desc(species_value)) %>%
        head(10) %>%
        mutate(
          Species      = factor(Species, levels = Species[order(species_value)]),
          tooltip_text = paste0(
            "<b>", Species, "</b><br>",
            "Wholesale Value: ", format_currency(species_value), "<br>",
            "% of Total: ", round(species_value / sum(species_value) * 100, 1), "%"
          )
        )
      
      validate(need(nrow(plot_data) > 0, "No species with non-zero value in the selected region."))
      
      p <- ggplot(plot_data, aes(x = species_value, y = Species, fill = species_value, text = tooltip_text)) +
        geom_col() +
        scale_fill_gradient(low = "#ddd6fe", high = "#6366f1", guide = "none") +
        scale_x_continuous(labels = scales::dollar_format(scale = 1e-6, suffix = "M"), expand = c(0,0)) +
        labs(x = "Wholesale Value (Millions $)", y = NULL, title = paste("Top Species:", sel_region)) +
        plot_theme
      
      # --- Scenario 4: Both species and region selected ---
    } else {
      
      val_row <- region_species %>% filter(AA_NAME == sel_region, Species == sel_species)
      validate(need(nrow(val_row) > 0 && val_row$species_value > 0,
                    "Selected region has zero value for the chosen species."))
      
      # Always include selected species; pad with top-4 others in the region
      region_total <- sum(
        region_species$species_value[region_species$AA_NAME == sel_region], na.rm = TRUE
      )
      
      plot_data <- bind_rows(
        region_species %>% filter(AA_NAME == sel_region, Species == sel_species),
        region_species %>% filter(AA_NAME == sel_region, species_value > 0) %>%
          arrange(desc(species_value)) %>% head(4)
      ) %>%
        distinct(Species, .keep_all = TRUE) %>%   # Remove duplicate if selected is already in top 4
        arrange(desc(species_value)) %>%
        head(5) %>%
        mutate(
          is_selected  = Species == sel_species,
          Species      = factor(Species, levels = Species[order(species_value)]),
          tooltip_text = paste0(
            "<b>", Species, "</b><br>",
            "Wholesale Value: ", format_currency(species_value), "<br>",
            "% of Region Total: ", round(species_value / region_total * 100, 1), "%",
            if_else(is_selected, "<br><i>(Selected Species)</i>", "")
          )
        )
      
      p <- ggplot(plot_data, aes(x = species_value, y = Species, fill = is_selected, text = tooltip_text)) +
        geom_col() +
        scale_fill_manual(
          values = c("FALSE" = "#e5e7eb", "TRUE" = "#6366f1"),
          guide  = "none"
        ) +
        scale_x_continuous(labels = scales::dollar_format(scale = 1e-6, suffix = "M"), expand = c(0,0)) +
        labs(
          x        = "Wholesale Value (Millions $)",
          y        = NULL,
          title    = paste("Species Comparison:", sel_region),
          subtitle = paste("Highlighted:", sel_species)
        ) +
        plot_theme +
        theme(plot.subtitle = element_text(size = 12, color = "#6b7280", face = "italic"))
    }
    
    ggplotly(p, tooltip = "text") %>%
      config(displayModeBar = FALSE) %>%
      layout(hoverlabel = list(bgcolor = "white", font = list(size = 13)))
  })
  
  # ---------------------------------------------------------------------------
  # Output: Summary stats cards (sidebar)
  # Shows total wholesale value + federal/provincial license counts,
  # filtered to match the current species/region selection.
  # ---------------------------------------------------------------------------
  
  output$summaryStatsCards <- renderUI({
    sel_species <- input$speciesSelect
    sel_region  <- input$regionSelect
    
    # Build filtered license data and total value depending on active filters
    if (sel_species != "All Species" && sel_region == "All Regions") {
      total_value  <- sum(region_species$species_value[region_species$Species == sel_species], na.rm = TRUE)
      license_data <- df_clean %>%
        st_drop_geometry() %>%
        filter(Species == sel_species) %>%
        select(Company, `License Type`) %>%
        distinct() %>%
        group_by(`License Type`) %>%
        summarize(count = n(), .groups = "drop")
      
    } else if (sel_species == "All Species" && sel_region != "All Regions") {
      total_value  <- sum(region_species$species_value[region_species$AA_NAME == sel_region], na.rm = TRUE)
      license_data <- df_clean %>%
        st_drop_geometry() %>%
        filter(AA_NAME == sel_region) %>%
        select(Company, `License Type`) %>%
        distinct() %>%
        group_by(`License Type`) %>%
        summarize(count = n(), .groups = "drop")
      
    } else if (sel_species == "All Species" && sel_region == "All Regions") {
      total_value  <- sum(region_summary$total_wholesale_value, na.rm = TRUE)
      license_data <- license_counts_total
      
    } else {
      val_row     <- region_species %>% filter(AA_NAME == sel_region, Species == sel_species)
      total_value <- if (nrow(val_row) > 0) val_row$species_value else 0
      license_data <- df_clean %>%
        st_drop_geometry() %>%
        filter(AA_NAME == sel_region, Species == sel_species) %>%
        select(Company, `License Type`) %>%
        distinct() %>%
        group_by(`License Type`) %>%
        summarize(count = n(), .groups = "drop")
    }
    
    # Tally federal vs. provincial licenses
    federal_count    <- sum(license_data$count[str_detect(license_data$`License Type`, regex("federal",    ignore_case = TRUE))], na.rm = TRUE)
    provincial_count <- sum(license_data$count[str_detect(license_data$`License Type`, regex("provincial", ignore_case = TRUE))], na.rm = TRUE)
    
    tagList(
      div(class = "stat-card",
          div(class = "stat-number", format_currency(total_value)),
          div(class = "stat-label",  "Total Value")),
      div(class = "stat-card",
          div(class = "stat-number", federal_count),
          div(class = "stat-label",  "Federal Licenses")),
      div(class = "stat-card",
          div(class = "stat-number", provincial_count),
          div(class = "stat-label",  "Provincial Licenses"))
    )
  })
  
  # ---------------------------------------------------------------------------
  # Output: Quantity table (sidebar)
  # Mirrors the bar chart — same rows, same order — but shows KG instead of $.
  # ---------------------------------------------------------------------------
  
  output$quantityTable <- DT::renderDataTable({
    sel_species <- input$speciesSelect
    sel_region  <- input$regionSelect
    
    if (sel_species != "All Species" && sel_region == "All Regions") {
      # Same top-10 regions as the bar chart
      plot_regions <- region_species %>%
        filter(Species == sel_species, species_value > 0) %>%
        arrange(desc(species_value)) %>%
        head(10) %>%
        pull(AA_NAME)
      
      table_data <- region_species_quantity %>%
        filter(Species == sel_species, AA_NAME %in% plot_regions) %>%
        mutate(AA_NAME = factor(AA_NAME, levels = plot_regions)) %>%
        arrange(AA_NAME) %>%
        mutate(species_quantity_kg = round(species_quantity_kg, 0)) %>%
        select(Region = AA_NAME, `Qty` = species_quantity_kg)
      
    } else if (sel_species == "All Species" && sel_region == "All Regions") {
      # Same top-10 regions as the bar chart
      plot_regions <- region_summary %>%
        arrange(desc(total_wholesale_value)) %>%
        head(10) %>%
        pull(AA_NAME)
      
      table_data <- region_totals_quantity %>%
        filter(AA_NAME %in% plot_regions) %>%
        mutate(AA_NAME = factor(AA_NAME, levels = plot_regions)) %>%
        arrange(AA_NAME) %>%
        mutate(total_quantity_kg = round(total_quantity_kg, 0)) %>%
        select(Region = AA_NAME, `Qty` = total_quantity_kg)
      
    } else if (sel_species == "All Species" && sel_region != "All Regions") {
      # Same top-10 species as the bar chart
      plot_species <- region_species %>%
        filter(AA_NAME == sel_region, species_value > 0) %>%
        arrange(desc(species_value)) %>%
        head(10) %>%
        pull(Species)
      
      table_data <- region_species_quantity %>%
        filter(AA_NAME == sel_region, Species %in% plot_species) %>%
        mutate(Species = factor(Species, levels = plot_species)) %>%
        arrange(Species) %>%
        mutate(species_quantity_kg = round(species_quantity_kg, 0)) %>%
        select(Species, `Qty` = species_quantity_kg)
      
    } else {
      # Single species, single region
      table_data <- region_species_quantity %>%
        filter(AA_NAME == sel_region, Species == sel_species) %>%
        mutate(species_quantity_kg = round(species_quantity_kg, 0)) %>%
        select(Species, Region = AA_NAME, `Qty` = species_quantity_kg)
    }
    
    DT::datatable(
      table_data,
      options  = list(
        pageLength    = 10,
        dom           = 't',
        ordering      = FALSE,   # Preserve bar chart order
        scrollY       = "250px",
        scrollCollapse = TRUE
      ),
      rownames = FALSE,
      class    = 'table-striped table-hover'
    ) %>%
      DT::formatCurrency(
        columns  = which(grepl("Qty", names(table_data))),
        currency = "",
        digits   = 0
      )
  })
}


# =============================================================================
# 8. LAUNCH APP
# =============================================================================

shinyApp(ui = ui, server = server)