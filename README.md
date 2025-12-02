**BC AF TRADE TOOL**
by: Leila Bautista (leila.bautista@gov.bc.ca)

The BC AF Trade Tool is an agriculture and food-specific tool to view trade value (e.g., domestic export, imports and trade balance) for all Canadian provinces and territories by country and state destination and commodity type using various classification systems.

**STEPS TO BUILDING AN AF TRADE TOOL**
1. Run **_BC_AF_Trade_Tool_Build.Rmd_** which requires _HS8X_2022_AAFC_REF.csv_ to:

   a. Loop through 2003-2024 and load data from **_https://search.open.canada.ca/opendata/?sort=metadata_modified+desc&search_text=cimt&page=1_
**
   b. Filter export data for agrifood HS8 codes using **_HS8X_2022_AAFC_REF.csv_**

   c. Filter import data for agrifood HS10 codes using** _HS10M_2022_AAFC_REF.csv_**

   d. Bind all years of export together and create **_'Estimate'_** variable to identify exports

   e. Bind all years of import together, aggregate commodities up to HS8,  and create **_'Estimate'_** variable to identify imports

   f. Bind both export and import data together by unique date, province, country, state, estimate

   g. Unpivot and calculate trade balance

   h. Write and store **_TradeFULL.csv_** into a shared location
   
3. Load data into PowerBI (or any other data visualization software)
   
   a. Load **_TradeFULL.csv_** using the M query, **_TradeFULL.txt_**

   b. Load **_Commodity_Classification.csv_** using the M query, **_Commodity Classification.txt_**

   c. Load **_ODPF_6_CtyDesc.txt_** using the M query, **_TradeREF_Country.txt_**

   d. Load **_ODPF_7_StateDesc.txt_** using the M query, **_TradeREF_State.txt_**

   e. Load **_ODPF_8_ProvDesc.txt_** using the M query, **_TradeREF_Province.txt_**

   f. Load **_ODPF_9_UOMDesc.txt_**

   g. Create relationships between reference tables from stebs b to f and _TradeFULL.csv_

4. Run _**BC_AF_Trade_Tool_Update.Rmd**_ to

   a. Load **_[specify year]_** export and import value data

   b. Filter for agrifood HS8 and HS10 codes then aggregate to HS8 accordingly

   c. Bind export and import data to calculate trade balance

   d. Load **_TradeFULL.csv_** from shared location

   e. Bind updated data with **_TradeFULL.csv_**

   f. Write and store **_TradeFULL.csv_** into shared location

5. Refresh PowerBI dataset and publish

**FINAL THOUGHTS**
Please contact leila.bautista@gov.bc.ca for questions, comments or corrections. Thanks!
