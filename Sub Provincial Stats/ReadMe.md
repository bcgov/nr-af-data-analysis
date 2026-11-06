---
editor_options: 
  markdown: 
    wrap: 72
---

BC SUB PROVINCIAL STATS

by: Leila Bautista
([leila.bautista\@gov.bc.ca](mailto:leila.bautista@gov.bc.ca){.email})

**What is it?**

The Sub Provincial Stats is a Sector Intelligence Project that estimates
and disseminates agrifood data at a more granular level than BC's
provincial total. There are currently 2 dashboards which we plan to
merge into 1 output:

1.  [**Sub-Provincial
    FCR.pbix**](https://bcgov.sharepoint.com/:u:/r/sites/AF-SPID-SICI_Subsite3/Project%20Files/1.6d%20Sub-Provincial%20Statistics/02%20Analysis%20and%20Results/2026/1.6d%20Sub-Provincial%20FCR.pbix?d=we8a1c4c6a179410ab2db881e2e76379c&csf=1&web=1&e=UWHegZ)**:**
    combines census of agriculture data's regional farm operating
    revenue with annual farm cash receipt to estimate annual regional
    FCR

2.  [**Regional
    Profiles.pbix**](https://bcgov.sharepoint.com/:u:/r/sites/AF-SPID-SICI_Subsite3/Project%20Files/1.6d%20Sub-Provincial%20Statistics/02%20Analysis%20and%20Results/2026/1.6d%20Regional%20Stats.pbix?d=w47e4df64689842268da7d86978b7881d&csf=1&web=1&e=kpqfS0)**:**
    visualization of census of agriculture and census of population data
    by Census Division

**Why do we do it?**

Support ministry and other BC Government colleagues for a sense of
regional impacts of agriculture in terms of farm revenue. Typical users
include land use planners, regional agrologists and policy analysts.

**How do we do it?**

For each part, there is a working .pbix file with queries (in M and R)
to load and transform the data. The SSOT of those codes and queries are
in this repository folder.

[**Sub-Provincial
FCR.pbix**](https://bcgov.sharepoint.com/:u:/r/sites/AF-SPID-SICI_Subsite3/Project%20Files/1.6d%20Sub-Provincial%20Statistics/02%20Analysis%20and%20Results/2026/1.6d%20Sub-Provincial%20FCR.pbix?d=we8a1c4c6a179410ab2db881e2e76379c&csf=1&web=1&e=UWHegZ)
includes 3 queries:

- [CenusAg_OperatingRevenue](https://github.com/bcgov/nr-af-data-analysis/blob/main/Sub%20Provincial%20Stats/CenusAg_OperatingRevenue):
  loads data from Statistics Canada's Table: 32-10-0240-01 on CCS-level
  farm operating revenue reported for the year 2020 according to the
  Census of Agriculture in BC. Also loads data on total farms reporting
  operating revenue and total number of farms within each CCS. The query
  also loads data from the Census of Agriculture on BC's total farm
  operating revenue in 2021 to calculate each CCS' share of total (i.e.,
  Abbotsford is 22.6% of BC total).
- [FCR_Annual_3210004501](https://github.com/bcgov/nr-af-data-analysis/blob/main/Sub%20Provincial%20Stats/FCR_Annual_3210004501):
  loads data from Statistics Canada Table: 32-10-0045-01 which has BC
  total farm cash receipt (FCR) estimate annually since 2020.
- [Sub-provincial
  FCR](https://github.com/bcgov/nr-af-data-analysis/blob/main/Sub%20Provincial%20Stats/Sub-provincial%20FCR):
  merges the queries,
  [CenusAg_OperatingRevenue](https://github.com/bcgov/nr-af-data-analysis/blob/main/Sub%20Provincial%20Stats/CenusAg_OperatingRevenue)
  and
  [FCR_Annual_3210004501](https://github.com/bcgov/nr-af-data-analysis/blob/main/Sub%20Provincial%20Stats/FCR_Annual_3210004501),
  via a left-join into 1 query. The purpose is to multiply the CCS share
  of total operating revenue against annual FCR values to estimate the
  annual FCR for each CCS. This query is what is used to build all the
  visuals for the pbix.

The main assumption and limitation is that share and prices are
consistent throughout the years and across CCS' so 2025 estimates are
the least reliable. The Census of Agriculture 2026 will provide an
update with a question on total operating revenue reported for the year
2025.

The following is visualization of the relationship between the 3 queries
where:

- [FCR_Annual_3210004501](https://github.com/bcgov/nr-af-data-analysis/blob/main/Sub%20Provincial%20Stats/FCR_Annual_3210004501)
  VALUE column is an input to [Sub-provincial
  FCR](https://github.com/bcgov/nr-af-data-analysis/blob/main/Sub%20Provincial%20Stats/Sub-provincial%20FCR)
  query

- [CenusAg_OperatingRevenue](https://github.com/bcgov/nr-af-data-analysis/blob/main/Sub%20Provincial%20Stats/CenusAg_OperatingRevenue):
  also serves as a reference tool for Sub-provincial FCR query for the
  column called CCS which stands for consolidated census subdivision

![](images/clipboard-3331437902.png)

[Regional
Profiles.pbix](https://bcgov.sharepoint.com/:u:/r/sites/AF-SPID-SICI_Subsite3/Project%20Files/1.6d%20Sub-Provincial%20Statistics/02%20Analysis%20and%20Results/2026/1.6d%20Regional%20Stats.pbix?d=w47e4df64689842268da7d86978b7881d&csf=1&web=1&e=9Gerq3)
includes

- 16 Census of Ag 2021 queries:
  - CEAG2021_GEO_REF CEAG2021_FlatFile - Total \# of farm
  - CEAG2021_FlatFile - Total farm acres
  - CEAG2021_FlatFile - Farms by revenue
  - CEAG2021_FlatFile - Total operating revenues
  - CEAG2021_FlatFile - Farm capital
  - CEAG2021_FlatFile - Livestock CEAG2021_FlatFile - Crops
  - CEAG2021_FlatFile - Succession Plan
  - CEAG2021_FlatFile - Direct Sales of OpRev
  - CEAG2021_FlatFile - Direct Sales Method
  - CEAG2021_FlatFile - Technology
  - CEAG2021_FlatFile - Irrigated Land
  - CEAG2021_FlatFile - Tenure
  - CEAG2021_FlatFile - Labour Employees
  - CEAG2021_FlatFile - Labour Time
- British Columbia Regional District and Municipal Population Estimates
- 3 Census of Population queries:
  - CensusPop2021 - LF Characteristics
  - CensusPop2021 - Med HH Income
  - CensusPop2021 - Age Gender
- The following reference tables as tools: Revenue Class REF
  Livestock_REF Crops_REF NAICS4_Sector_REF Technology_REF Rank_REF

Load and merge data with reference tables and create visualizations

<img src="https://github.com/user-attachments/assets/f4fa4390-3efa-4ac9-8d9b-cee4d2e60e8b" alt="image" width="1103" height="692"/>

Where are the files? The working files are in SI Projects Site >
Project Files > Sub Provincial Statistics The PowerBI Workspace is
called AF Sector Intelligence BC Gov (Internal) Dashboards
