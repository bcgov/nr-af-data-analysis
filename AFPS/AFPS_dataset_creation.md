# 1. CHEFS Dataset Creation

This section pulls submissions from the CHEFS API, strips metadata and draft entries, and flattens the nested JSON grid columns (one per seafood category) into a single tidy dataset.

### Load All Libraries

```python
import requests
import pandas as pd
import numpy as np
import re
import os
```

### Connect to API

```python
# API configuration -- store these securely (e.g. environment variables) rather than hardcoding
FORM_ID = "<your-form-id>"
API_KEY = "<your-api-key>"
VERSION_ID = "<your-version-id>"

url = f"https://submit.digital.gov.bc.ca/app/api/v1/forms/{FORM_ID}/versions/{VERSION_ID}/submissions"
response = requests.get(url, auth=(FORM_ID, API_KEY), timeout=60)

submissions = response.json()

# Flatten the nested JSON response into a wide DataFrame (one row per submission)
submitted = pd.json_normalize(submissions)
```

### Remove Draft Entries

```python
# Exclude incomplete drafts and soft-deleted submissions -- keep only final, active entries
submitted = submitted.loc[(submitted['draft'] == False) & (submitted['deleted'] == False)]
```

### Keep Only Relevant Columns

Run `submitted.columns` first to inspect the full list of flattened column names returned by the API, then select only the fields needed for analysis.

```python
submitted.columns
```

```python
# Columns grouped by type:
#   - Company/contact info: companyName through licenceOtherIdNumber
#   - Plant location:       plantAddress1 fields
#   - Product grids:        dataGrid* columns (one per seafood category, each holds a list of dicts)
cols = [
    'submission.data.companyName',
    'submission.data.contactName',
    'submission.data.simpleemail',
    'submission.data.contactPosition',
    'submission.data.simpletextfield',
    'submission.data.simplephonenumber',
    'submission.data.licenceOtherIdNumber',
    'submission.data.plantAddress1.properties.fullAddress',
    'submission.data.plantAddress1.geometry.coordinates',
    'submission.data.dataGridPlants',
    'submission.data.dataGridSalmon',
    'submission.data.dataGridFish',
    'submission.data.dataGridShellfish',
    'submission.data.dataGridShellfishLive',
]
```

```python
new = submitted[cols]
```

### Cleaning JSON Grid Columns

Each `dataGrid*` column stores a list of dicts -- one dict per product row entered by the submitter. To work with this data in a flat tabular format, the grids need to be melted, exploded, and normalized. Because different seafood categories use different column names for the same concepts (e.g. `wholesaleValueFish` vs `wholesaleValueSalmon`), Species, Value, and Quantity are coalesced into unified columns at the end.

```python
# 1. Identify all dataGrid columns -- these are the nested product entry grids
grid_cols = new.columns[new.columns.str.contains('dataGrid', case=False, na=False)]

# 2. Melt to long format so each grid column becomes a row, paired with its submission's metadata
long = new.melt(
    id_vars=[col for col in new.columns if col not in grid_cols],  # all non-grid columns become id_vars
    value_vars=grid_cols,
    var_name="grid_name",   # which seafood category this row came from
    value_name="grid_data"  # the list of product dicts for that category
)

# 3. Explode: each list of product dicts becomes individual rows (one row per product entry)
long = long.explode("grid_data").reset_index(drop=True)

# 4. Normalize the dict in each grid_data cell into flat columns
grid_df = pd.json_normalize(long["grid_data"])

# 5. Separate the submission metadata from the grid columns for recombining
metadata_cols = [col for col in long.columns if col not in ['grid_name', 'grid_data']]
meta_df = long[metadata_cols].reset_index(drop=True)

# 6. Combine submission metadata with the normalized product grid data side-by-side
new_df = pd.concat([meta_df, grid_df.reset_index(drop=True)], axis=1)

# 7. Coalesce species: different grids use different column names for the species field
new_df['Species'] = new_df[['speciesType.label', 'salmon_species']].bfill(axis=1).iloc[:, 0]

# 8. Coalesce wholesale value: each grid category has its own value column name
new_df['Value'] = new_df[['wholesaleValueShellfish', 'wholesaleValueFish', 'wholesaleValueSalmon', 'wholesaleValuePlants']].bfill(axis=1).iloc[:, 0]

# 9. Coalesce quantity: same pattern as value -- pick whichever category column is populated
new_df['Quantity'] = new_df[['QuantityShellfish', 'QuantityFish', 'QuantitySalmon', 'QuantityPlants']].bfill(axis=1).iloc[:, 0]
```

### Drop NAs

```python
# Rows where both Value and Quantity are null are empty product grid rows (no data entered by submitter)
new_df = new_df[
    (new_df['Value'].notna()) | (new_df['Quantity'].notna())
].reset_index(drop=True)
```

At this point, the CHEFS dataset is as clean as it can get in Python. The remaining steps are best handled in Excel after export:
1. Delete the original `dataGrid*` columns and any other pre-transformation columns, keeping the new unified `Species`, `Value`, and `Quantity` columns
2. Rename the verbose CHEFS metadata column names (e.g. `submission.data.companyName`) to clean, readable headers

### Export Dataset to Excel

```python
new_df.to_excel('AFPS 2025 CHEFS.xlsx', index = False)
```

---

# 2. Clean and Scrape Excel Submissions

Most companies submit their AFPS via CHEFS. However, some are unable to -- either because they don't collect unprocessed input weights (which CHEFS requires), or due to technical barriers. These companies receive the legacy Excel-based AFPS template instead, which collects data by processed product type rather than raw species weight. This section automates scraping those Excel submissions into a single structured dataset that can later be merged with the CHEFS data.

### Load Data

Sync the SharePoint folder `Project 1.3a > 2026 > Communication > Excel Submissions` to your OneDrive, then point the path below to that local folder.

```python
sharepoint_path = os.path.expanduser("~\\Government of BC")
afps_folder = os.path.join(sharepoint_path, "Sector Intelligence Projects Subsite - Excel Submissions")

# Collect all .xlsx files in the submissions folder
excel_files = [f for f in os.listdir(afps_folder) if f.endswith(".xlsx")]

print(f"Found {len(excel_files)} Excel file(s): {excel_files}")
```

### Helper Function: Extract Company Info from Each Workbook

```python
def get_company_info(xls):
    """
    Reads fixed cells from the 'Co. Info' sheet to pull company name,
    mailing address, plant name, and plant address.

    Cell positions are 0-based: row 13 = Excel row 14, col 2 = column C.
    These positions assume the standard AFPS Excel template layout -- update
    the iloc indices if the template changes.
    """
    df_info = xls.parse("Co. Info", header=None, dtype=str)
    return {
        "Company Name":    df_info.iloc[13, 2],
        "Mailing Address": df_info.iloc[14, 2],
        "Plant Name":      df_info.iloc[15, 2],
        "Plant Address":   df_info.iloc[16, 2]
    }
```

### Define Sheet Configurations

The AFPS Excel template has four seafood category sheets, each with a different column layout. Salmon sheets (`Wild Salmon` and `CulturedSalmon&Fish`) use a staggered two-row structure where the product code appears on one row and its quantity/value appear on the row below. Shellfish and Fish sheets use a simpler single-row structure where code, quantity, and value are all on the same row.

```python
# Configuration for each sheet in the Excel template:
#   product_cols -- Excel column letters containing product codes
#   value_cols   -- Excel column letters containing dollar values (Salmon sheets only)
#   start_row    -- first data row index (1 = skip the single header row)

seafood_sheets = {
    "Wild Salmon": {
        "product_cols": ["D", "F", "H", "J"],  # each column pair represents one salmon species group
        "value_cols":   ["E", "G", "I", "K"],
        "start_row": 1
    },
    "Wild Fish & Shellfish": {
        "product_cols": ["D", "J"],             # two product blocks side-by-side on the sheet
        "start_row": 1
    },
    "CulturedSalmon&Fish": {
        "product_cols": ["C", "E", "G", "I", "K"],
        "value_cols":   ["D", "F", "H", "J", "L"],
        "start_row": 1
    },
    "Cultured Shellfish": {
        "product_cols": ["D", "J"],             # two product blocks side-by-side on the sheet
        "start_row": 1
    }
}
```

### Main Loop: Parse Every File and Sheet

```python
data_list = []

for file_name in excel_files:
    file_path = os.path.join(afps_folder, file_name)
    xls = pd.ExcelFile(file_path)

    # Extract company metadata from the Co. Info tab -- appended to every product row below
    company_info = get_company_info(xls)

    for sheet, config in seafood_sheets.items():
        df = xls.parse(sheet, header=None, dtype=str)

        # Convert Excel column letters (e.g. "D") to 0-based integer indices for iloc
        product_cols = [ord(c) - ord("A") for c in config["product_cols"]]
        start_row    = config["start_row"]

        # -- Salmon sheets: staggered layout -- product code on row i, qty/value on row i+1 --
        if sheet in ["Wild Salmon", "CulturedSalmon&Fish"]:
            value_cols = [ord(c) - ord("A") for c in config["value_cols"]]

            for prod_col, val_col in zip(product_cols, value_cols):
                codes, quantities, values_list = [], [], []

                for i in range(start_row - 1, len(df) - 1):
                    code = df.iloc[i,     prod_col]
                    qty  = df.iloc[i + 1, prod_col] if i + 1 < len(df) else ""  # quantity sits one row below the code
                    val  = df.iloc[i + 1, val_col]  if i + 1 < len(df) else ""  # value sits one row below the code

                    # Normalize to clean strings, treating nulls as empty
                    code = str(code).strip() if pd.notnull(code) else ""
                    qty  = str(qty).strip()  if pd.notnull(qty)  else ""
                    val  = str(val).strip()  if pd.notnull(val)  else ""

                    # Only keep rows where the code is a whole number and qty/value are valid numerics
                    if code.isdigit():
                        # Standardize all product codes to 5-digit zero-padded strings for consistent merging later
                        code = format(int(code), '05d') if sheet == "Wild Salmon" else code.zfill(5)
                        if qty.replace('.', '', 1).isdigit() and val.replace('.', '', 1).isdigit():
                            codes.append(code)
                            quantities.append(qty)
                            values_list.append(val)

                temp_df = pd.DataFrame({
                    "Product Code": codes,
                    "Quantity":     quantities,
                    "Value":        values_list
                })
                # Attach company metadata and sheet source to every product row
                for key, value in company_info.items():
                    temp_df[key] = value
                temp_df["Source Sheet"] = sheet
                data_list.append(temp_df)

        # -- Shellfish / Fish sheets: flat layout -- code, qty, value all on the same row --
        else:
            for col in product_cols:
                # Quantity is always one column right of the product code; value is two columns right
                product_codes = df.iloc[start_row:, col].astype(str).str.strip().fillna("")
                quantities    = df.iloc[start_row:, col + 1].astype(str).str.strip().fillna("")
                values        = df.iloc[start_row:, col + 2].astype(str).str.strip().fillna("")

                # Filter to rows where all three fields are valid numbers (drops headers, blanks, and notes)
                mask = (
                    product_codes.str.match(r"^\d+$") &
                    quantities.str.match(r"^\d+(\.\d+)?$") &
                    values.str.match(r"^\d+(\.\d+)?$")
                )

                filtered_df = pd.DataFrame({
                    "Product Code": product_codes[mask].apply(lambda x: x.zfill(5)),  # zero-pad to 5 digits
                    "Quantity":     quantities[mask],
                    "Value":        values[mask]
                }).reset_index(drop=True)

                # Attach company metadata and sheet source to every product row
                for key, value in company_info.items():
                    filtered_df[key] = value
                filtered_df["Source Sheet"] = sheet
                data_list.append(filtered_df)
```

### Combine Results

```python
# Stack all per-sheet, per-file DataFrames into one combined dataset
excel_df = pd.concat(data_list, ignore_index=True)
```

### Change Numeric Data Types for Merging in Step 3

```python
# Use Int64 (nullable integer) rather than int64 to safely handle any NaN product codes
excel_df['Product Code'] = excel_df['Product Code'].astype('Int64')
excel_df[['Quantity', 'Value']] = excel_df[['Quantity', 'Value']].astype("float")
```

---

# 3. Map Anprod Product Codes to Excel Dataset

The Excel AFPS template collects data by processed product type (e.g. "Frozen Fillets"), identified by Anprod product codes. The Anprod reference table maps each code to its species, category, and a conversion rate used to back-calculate unprocessed input weight from the processed product weight reported. This is necessary to make the Excel submissions comparable to the CHEFS submissions, which collect unprocessed input weights directly.

### Load Anprod Data

Sync the SharePoint folder `Sector Intelligence Data Library > Unpublished Data` to your OneDrive, then point the path below to that local folder.

```python
anprod_product_path = os.path.join(sharepoint_path, "Sector Intelligence Data Library Subsite - Unpublished Data")
anprod = pd.read_excel(f"{anprod_product_path}/Anprod products.xlsx")
```

### Merge the Excel Dataset with Anprod Codes

```python
# Left join preserves all rows from excel_df; unrecognized product codes will have NaN species info
merged = excel_df.merge(anprod, how='left', on='Product Code')
```

### Apply the Quantity Multiplier

Each Anprod code includes a `Conversion Rate` that converts a processed product weight into the equivalent unprocessed species weight. A rate of 0 indicates the product weight should be used as-is (no conversion needed).

```python
def quantity_multiplier(df):
    df['Quantity2'] = np.where(
        df['Conversion Rate'] == 0,
        df['Quantity'],                          # rate of 0 means no conversion -- use weight as reported
        df['Quantity'] * df['Conversion Rate']   # otherwise scale up to unprocessed input weight
    )
    return df

merged = quantity_multiplier(merged)
```

### Convert Pounds to Kilograms

The Excel AFPS collects weights in pounds. The CHEFS AFPS collects weights in kilograms. Converting here ensures both datasets use the same unit before being combined.

```python
merged['Quantity2'] = merged['Quantity2'] * 0.45359237  # exact lbs-to-kg conversion factor
```

### Export Dataset to Excel

```python
merged.to_excel('AFPS 2025 Excel.xlsx', index = False)
```

With both datasets exported to Excel, the final steps can be completed manually:
1. Delete unneeded columns (original `dataGrid*` columns, raw pre-conversion quantities, API metadata, etc.)
2. Rename columns to clean, consistent headers across both files
3. Copy the Excel AFPS rows and paste them into the CHEFS dataset to produce the unified master AFPS dataset
