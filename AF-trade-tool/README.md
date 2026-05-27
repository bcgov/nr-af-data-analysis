**BC AF TRADE TOOL**
by: Leila Bautista (leila.bautista@gov.bc.ca)

What is it?
The BC AF Trade Tool is an agriculture and food-specific tool to view trade data for all Canadian provinces and territories by country and state destination and commodity type using various classification systems.

There are 2 .rmd files that can be run. They are reliant on reference tables and saving files in the team's Data Library SharePoint for unpublished data: https://bcgov.sharepoint.com/sites/AF-SICI/Raw%20Data/Forms/AllItems.aspx

1. **BC_AF_Trade_Tool_Build.Rmd** which will build **Trade_DomExport.csv** and **Trade_Import.csv** for the years specified in the loop and save into the Unpublished Data Library on SharePoint.
2. BC_AF_Trade_Tool_Update.Rmd which will read the existing T**rade_DomExport.csv** and **Trade_Import.csv** in the Unpublished Data Library on SharePoint and reads a specified year (usually most recent like 2026) and appends that into the timeseries data and write over the corresponding files.

To visualize and apply plain language to the data, reference tables (e.g., **Commodity_Classification.csv**) and relationships to the **Trade_DomExport.csv** and **Trade_Import.csv** files are built using PowerBI which is found in the projects folder:
https://bcgov.sharepoint.com/sites/AF-SPID-SICI_Subsite3/Project%20Files/Forms/AllItems.aspx

When the PowerBI is updated with the latest data, the project lead needs to publish the dashboard on the SICI Internal Dashboards workspace and ensure that the interal BC Gov app is also updated. 

Within the Sector Trade Tool.pbix file, there are 8 queries (M) and the code in this repository are the SSOT:
1) Trade_Import
2) Trade_Import_Commodity_Classification
3) Trade_DomExport
4) Trade_DomExport_Commodity_Classification
5) REF_Year
6) TradeREF_Country
7) TradeREF_Province
8) TradeREF_State

Query relationships:

Trade_Import and Trade_DomExport have a **many-to-one relationship** with the Commodity_Classification queries by the corresponding HS10 and HS8 columns

The remaining queries are tools and also have a many-to-one relationship with the Trade_Import and Trade_DomExport source datasets through:

REF_Year's Year column to Trade_Import & Trade_DomExport's Year column

TradeREF_Country's Country_Code column to Trade_Import & Trade_DomExport's Country column

TradeREF_Province's Province_Code column to Trade_Import & Trade_DomExport's Province column

TradeREF_State's State_Code column to Trade_Import & Trade_DomExport's State column

<img width="1761" height="650" alt="image" src="https://github.com/user-attachments/assets/c2784706-81c6-46ab-bb23-42cea0775df3" />

