**BC AF TRADE TOOL**
by: Leila Bautista (leila.bautista@gov.bc.ca)

The BC AF Trade Tool is an agriculture and food-specific tool to view trade data for all Canadian provinces and territories by country and state destination and commodity type using various classification systems.

There are 2 .rmd files that can be run. They are reliant on reference tables and saving files in the team's Data Library SharePoint for unpublished data: https://bcgov.sharepoint.com/sites/AF-SICI/Raw%20Data/Forms/AllItems.aspx

1. **BC_AF_Trade_Tool_Build.Rmd** which will build **Trade_DomExport.csv** and **Trade_Import.csv** for the years specified in the loop and save into the Unpublished Data Library on SharePoint.
2. BC_AF_Trade_Tool_Update.Rmd which will read the existing T**rade_DomExport.csv** and **Trade_Import.csv** in the Unpublished Data Library on SharePoint and reads a specified year (usually most recent like 2026) and appends that into the timeseries data and write over the corresponding files.

To visualize and apply plain language to the data, reference tables (e.g., **Commodity_Classification.csv**) and relationships to the T**rade_DomExport.csv** and **Trade_Import.csv** files are built using PowerBI which is found in the projects folder:
https://bcgov.sharepoint.com/sites/AF-SPID-SICI_Subsite3/Project%20Files/Forms/AllItems.aspx

When the PowerBI is updated with the latest data, the project lead needs to publish the dashboard on the SICI Internal Dashboards workspace and ensure that the interal BC Gov app is also updated. 
