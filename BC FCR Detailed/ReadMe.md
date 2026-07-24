# BC FCR Detailed

By: Leila Bautista, Sector Intelligence ([leila.bautista\@gov.bc.ca](mailto:leila.bautista@gov.bc.ca)) \

**WHAT is it?**

The BC Farm Cash Receipt (FCR) Detailed imputes FCR values for detailed commodities using annual survey estimates and combining it with aggregated estimates as published by Statistics Canada (STC) in [Table: 32-10-0045-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3210004501). The annual surveys used to impute detailed commodity FCR include:

- [Table 32-10-0364-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3210036401) Area, production and farm gate value of marketed fruits

- [Table 32-10-0365-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3210036501) Area, production and farm gate value of marketed vegetables

- [Table 32-10-0456-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3210045601) Production and value of greenhouse fruits and vegetables

- [Table 32-10-0246-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3210024601) Production and sale of greenhouse flowers and plants

- [Table 32-10-0452-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3210045201) Estimates of field-grown cut flowers area, production and sales

**WHY do we do it?**

The resulting data set from this work is used as input for various dashboards and reports that the ministry publishes and uses to better understand what makes up the total cash receipts from agricultural production in BC. The base data source aggregates certain commodity groups (e.g., fresh vegetables - field, fresh vegetables - greenhouse) despite detailed FCR estimates being available through other data sources. The resulting hierarchical data set is published as part of an interactive dashboard report found in the [minsitry's public website](https://www2.gov.bc.ca/gov/content/industry/agriculture-seafood/statistics/agriculture-and-seafood-statistics-publications) through the following URL:

<https://app.powerbi.com/view?r=eyJrIjoiMTA0MDg1MzEtNzM5Zi00MzJkLWI5ODAtNTY1ZTBiNDZjNzVkIiwidCI6IjZmZGI1MjAwLTNkMGQtNGE4YS1iMDM2LWQzNjg1ZTM1OWFkYyJ9>

**HOW do we do it?**

The following is an overview of the steps undertaken to build a detailed FCR data set which is saved on the team's data library on SharePoint which is queried by PowerBI to populate dashboards and other reports:

1.  Load the FCR estimate from the base data source for commodities without further detailed breakdowns.

2.  For commodity groups that have more detailed FCR breakdown estimates from other sources, the detailed data set is appended to the aggregated estimate and residual is calculated. For example, [Table: 32-10-0045-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3210004501) reports "Total fresh fruit" value and [Table 32-10-0364-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3210036401) reports detailed values for 18 types of fruits where Total fresh fruit =i=1∑18​Xi​+R

3.  Additional calculations are undertaken for certain aggregated commodity groups or years based on data availability and suppression:

    i.  GH Nursery = GH Floriculture & Nursery – GH Floriculture\
        = GH Floriculture & Nursery – (Total Floriculture – Field-Grown Floriculture)

    ii. For suppressed years (e.g., sod and nursery in 2018), a linear interpolation from t-1 and t+1 is applied

4.  After appending detailed FCR tables with the base FCR table, a crosswalk reference table with sector and sub-sector are left-joined with the resulting table to facilitate hierarchical aggregation
