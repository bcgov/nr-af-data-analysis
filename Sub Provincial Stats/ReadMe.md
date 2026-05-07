
**BC Sub Provincial Stats**
by: Leila Bautista (leila.bautista@gov.bc.ca)

**What is it?**

The Sub Provincial Stats is a Sector Intelligence Project that estimates
and disseminates agrifood data at a more granular level than BC's
provincial total. There are 2 currently parts which we plan to merge
into 1 output: 1) Sub-Provincial FCR.pbix: combines census of
agricutlure data's regional farm operating revenue with annual farm cash
receipt to estimate annual regional FCR 2) Regional Profiles.pbix:
visualuzation of census of agriculture and census of population data by
Census Division

**Why do we do it?**

Support ministry and other BC Government colleagues for a sense of
regional impacts of agriculture in terms of farm revenue. Typicall users
include land use planners, regional agrologists and policy analysts.

**How do we do it?**

For each part, there is a working .pbix file with queries (in M) to load
and transform the data. The SSOT of those codes and queries are in this
repository folder

Sub-Provincial FCR.pbix includes 3 queries

-   CEAG2021_FlatFile - Revenue
-   Sub-provincial FCR
-   FCR_Annual_3210004501

Take each CCS' share of total operating revenue reported for the year
2020 according to the Census of Agriculture (i.e., Abbotsford is 22.6%
of BC total) and applied that to annual FCR estimates. The main
assumption and limitation is that share and prices are consistent
throughout the years and across CCS' so 2025 estimates are the least
reliable. The Census of Agriculture 2026 will provide an update with a
question on total operating revenue reported for the year 2025.

The following is visualization of the relationship between the 3 queries
where:

-   FCR annual's VALUE column is an input to Sub-provincial FCR query

-   CEAG2021_FlatFile - Revenue also serves as a reference tool for
    Sub-provincial FCR query for the column called CCS which stands for
    consolidated census subdivision

<img width="950" height="532" alt="image" src="https://github.com/user-attachments/assets/41763032-d3ac-4df4-aec2-68c62ef32752" />



Regional Profiles.pbix includes

-   16 Census of Ag 2021 queries:
    -   CEAG2021_GEO_REF CEAG2021_FlatFile - Total \# of farm
    -   CEAG2021_FlatFile - Total farm acres
    -   CEAG2021_FlatFile - Farms by revenue
    -   CEAG2021_FlatFile - Total operating revenues
    -   CEAG2021_FlatFile - Farm capital
    -   CEAG2021_FlatFile - Livestock CEAG2021_FlatFile - Crops
    -   CEAG2021_FlatFile - Succession Plan
    -   CEAG2021_FlatFile - Direct Sales of OpRev
    -   CEAG2021_FlatFile - Direct Sales Method
    -   CEAG2021_FlatFile - Technology
    -   CEAG2021_FlatFile - Irrigated Land
    -   CEAG2021_FlatFile - Tenure
    -   CEAG2021_FlatFile - Labour Employees
    -   CEAG2021_FlatFile - Labour Time
-   British Columbia Regional District and Municipal Population
    Estimates
-   3 Census of Population queries:
    -   CensusPop2021 - LF Characteristics
    -   CensusPop2021 - Med HH Income
    -   CensusPop2021 - Age Gender
-   The following reference tables as tools: Revenue Class REF
    Livestock_REF Crops_REF NAICS4_Sector_REF Technology_REF Rank_REF

Load and merge data with reference tables and create visualizations

Where are the files? The working files are in SI Projects Site \>
Project Files \> Sub Provincial Statistics The PowerBI Workspace is
called AF Sector Intelligence BC Gov (Internal) Dashboards
