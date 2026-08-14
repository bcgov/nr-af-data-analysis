# Stata program

`FarmFood_counts.do` is the GitHub-ready copy of the validated July 2026 Stata program. The validated original remains unchanged in the controlled project files.

`FarmFood_counts_stata_code.txt` is an identical plain-text copy for readers who do not have Stata. It can be opened in Notepad or another text editor and copied into Stata's Do-file Editor. The `.do` file remains the authoritative source-code version; update the text copy whenever the `.do` file changes.

## Requirements

- Stata 17 or later
- internet access to download the two public Statistics Canada ZIP files
- the approved `Ag_and_Food_Business_Counts.xlsx` workbook in the project root
- a worksheet named `DATA` in that workbook

Do not upload the BC Stats workbook, downloaded data, generated outputs, credentials, or private SharePoint locations to GitHub unless organizational policy explicitly permits it.

## Run the program

Start Stata in the project root and run:

```stata
do "Stata/FarmFood_counts.do"
```

Alternatively, provide an approved project location as the first argument:

```stata
do "Stata/FarmFood_counts.do" "C:/approved/project/location"
```

The program creates its output folders under `outputs/`. It downloads and caches the public Statistics Canada files in the configured project root when they are not already present.

## Public Statistics Canada sources

- Table 32-10-0231-01: 2021 Census farm counts by geography and farm type
- Table 32-10-0136-01: annual BC farm counts and farm-type movement indicators

The program uses the official ZIP download URLs recorded in its source comments.
