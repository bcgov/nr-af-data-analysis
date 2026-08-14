# Sub-Provincial Farm and Business Count

**Power BI report:** `1.6d Sub-Provincial Farm and Business Count.pbix`  
**Documentation version:** August 14, 2026
By Million Tadesse (million.tadesse@gov.bc.ca)

## What is it?

The Sub-Provincial Farm and Business Count report provides:

- estimated annual farm counts for British Columbia;
- modelled farm counts by region and farm type;
- observed agriculture and food-business counts; and
- observed food and beverage processor counts.

The report has five pages: Home and read me, Annual overview, Regional farm counts, Observed food businesses, and Regional farm and processor counts.

## Why do we do it?

The report gives ministry and other BC Government users a consistent view of farm and food-business activity across British Columbia. It supports regional analysis, planning, policy work, and annual reporting.

## How do we do it?

Power BI connects to approved online Statistics Canada and BC Stats sources. Power Query imports, cleans, classifies, and validates the data. Model relationships and a small set of DAX measures support the report visuals.

```text
Online sources -> Power Query -> Data model -> DAX measures -> Report pages
```

The production report follows the analytical method reviewed in July 2026. The July results were used for validation only and are not production refresh sources.

## Data sources

| Source | Use |
|---|---|
| [Statistics Canada table 32-10-0231-01](https://www150.statcan.gc.ca/n1/tbl/csv/32100231-eng.zip) | Observed 2021 Census farm counts by geography and farm type |
| [Statistics Canada table 32-10-0136-01](https://www150.statcan.gc.ca/n1/tbl/csv/32100136-eng.zip) | Annual BC farm counts and farm-type movement indicators |
| BC Stats agriculture and food business workbook | Observed regional business and processor counts; accessed through the approved SharePoint site |

The internal SharePoint address and credentials are intentionally excluded from this repository document.

## Important interpretation

### Farm counts are modelled

The observed 2021 Census count of **15,841 farms** is the provincial benchmark. Other annual and regional farm results are estimates based on annual BC farm-count movements and the 2021 regional distribution.

In simplified form:

```text
Annual BC estimate = annual ATDP count x 2021 Census-to-ATDP ratio

Regional estimate = 2021 regional Census count
                    x annual BC farm-type movement since 2021
```

Regional estimates are adjusted to the approved annual controls and rounded to whole farms.

### Business and processor counts are observed

Business and processor results come directly from the BC Stats source after standardization and classification. They are **not** adjusted using the farm methodology.

### Do not add overlapping totals

The business data includes provincial and regional rows as well as employee-size detail and `Total` rows. Report measures must select the intended geography and employee level to avoid double counting.

## Main production outputs

| Power BI table | Purpose |
|---|---|
| `fact_Farm_BC_Annual` | Annual BC farm estimates |
| `fact_Regional_FarmCounts` | Regional farm estimates by year and farm type |
| `fact_Business_Broad` | Observed broad business counts |
| `fact_Processor_Counts` | Observed processor counts |
| `fact_FarmFoodBusiness_ByYearRegionType` | Combined regional farm and processor reporting |

Power Query staging, helper, audit, and validation queries should remain load-disabled. They should not appear as report-facing tables.

## Refreshing the report

The report is designed to accept new years from the online sources without editing a fixed end year.

1. Refresh the semantic model in the shared Power BI workspace.
2. Check the refresh history for errors.
3. Confirm that the latest available year appears for each source.
4. Confirm that the 2021 BC farm benchmark remains 15,841.
5. Confirm that regional farm totals reconcile to the approved annual BC total.
6. Confirm that new BC Stats results use December records.
7. Review the main cards, trends, regional totals, blanks, and zeros.
8. Have a second team member review the new-year results.
9. Record the refresh date, source years, reviewer, and any approved exception.

Statistics Canada web sources use Anonymous access. The BC Stats SharePoint source uses an organizational account. Credentials belong in Power BI Service data-source settings, not in this repository.

## Known limitation and accepted precision note

Annual regional farm counts are modelled estimates, not direct regional ATDP observations. The method assumes that BC-level annual farm-type movements are suitable indicators for updating the 2021 regional distribution.

Compared with the earlier Stata implementation, 31 regional-district farm rows differ by exactly one farm because of precision and rounding. The net Power BI-minus-Stata difference is -9 across 2017-2024. All reporting keys and processor values match. This difference was accepted by the reviewer on August 11, 2026. Do not add row-specific corrections.

## Reporting standards

- Clearly label farm results as **modelled** and business or processor results as **observed**.
- Use the reporting names `Metro Vancouver`, `qathet`, and `North Coast`.
- Do not display a combined grand total that adds `All farm types` to its component farm types.
- Do not change farm-type mappings, classifications, benchmark logic, rounding stages, regional names, or zero-completion rules without review and validation.
- Keep the production PBIX in the approved shared location with at least one backup owner.
- Do not store passwords, tokens, private SharePoint addresses, or personal information in GitHub.

## Files and detailed documentation

| File | Purpose |
|---|---|
| `1.6d Sub-Provincial Farm and Business Count.pbix` | Production Power BI report |
| `04_PowerBI_Online_Reporting_Manual.md` | Detailed production methodology, report design, refresh, and publication guidance |
| `03_PowerBI_Build_Manual.md` | Full development and validation record |
| `02_July_to_PowerBI_Mapping.md` | Mapping from the approved July workflow to Power BI |

Use this README for project orientation and routine maintenance. Refer to the detailed manuals when changing the method, repairing a source, rebuilding a query, or repeating validation.

## Where are the files?

The working PBIX and controlled copies are stored in the organization's approved SharePoint location. The shareable documentation and approved source code belong in the organization-managed GitHub repository.
