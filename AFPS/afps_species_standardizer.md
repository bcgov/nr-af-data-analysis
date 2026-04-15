# AFPS Species Name Standardizer

Using the CHEFS API to extract AFPS data yields messy species names. Likewise, species naming conventions differ between the CHEFS and Excel versions of the AFPS. This script cleans and standardizes species names into a canonical set and assigns each to a species category.

---

## Setup

```python
import numpy as np
import pandas as pd
import os
import re

os.chdir()  # change working directory to where the AFPS dataset (CHEFS-Excel merged) is

df = pd.read_excel("AFPS.xlsx")  # Load dataset
```

---

## Species Mapping

```python
print(df['species'].unique())
```

### Raw Input

All raw species name variants observed across the CHEFS API and Excel versions of the AFPS:

```python
RAW_SPECIES = [
    'FLOATING KELP', 'SEAWEED', 'OTHER AQUATIC PLANT', 'pink', 'redChinook',
    'coho', 'sockeye', 'atlantic', 'darkChum', 'pinkChinook', 'semiBriteChum',
    'steelhead', 'whiteChinook', 'oil', 'silverBriteChum', 'ARTIC CHAR', 'LINGCOD',
    'TUNA', 'YELLOWEYE ROCKFISH / RED SNAPPER',
    'PACIFIC ROCKFISH / PACIFIC OCEAN PERCH', 'POLLOCK',
    'SABLEFISH / BLACK COD', 'GREY (PACIFIC) COD', 'HALIBUT', 'REX SOLE',
    'HERRING', 'OTHER ROCKFISH', 'PETRALE SOLE', 'ROCK SOLE', 'HAKE', 'OTHER FISH',
    'RAINBOW TROUT', 'OTHER GROUNDFISH', 'SKATES', 'ENGLISH (LEMON) SOLE',
    'DOVER SOLE', 'OTHER FRESHWATER FINSFISH', 'TILAPIA', 'OIL', 'FLOUNDERS',
    'ARROWTOOTH FLOUNDER / TURBOT', 'PALCHARD / SARDINES', 'STURGEON',
    'BARRAMUNDI', 'MACKEREL', 'OYSTERS', 'SEA CUCUMBER', 'PRAWNS', 'CRAB',
    'OCTOPUS', 'SHRIMP', 'OTHER CRUSTACEANS', 'MUSSELS', 'RED SEA URCHIN',
    'GREEN SEA URCHIN', 'SCALLOPS', 'CLAMS - OTHER', 'SQUID',
    'MANILA AND LITTLENECK CLAMS', 'OTHER MARINE ANIMAL', 'BUTTER CLAMS',
    'GEODUCK CLAMS', 'OTHER CRUSTEANS', 'HORSE CLAMS', 'Pollock', 'Sockeye',
    'Other Salmon', 'Coho', 'Pink', 'Halibut', 'Sablefish (Groundfish)', 'Shrimp',
    'Other Rockfish', 'Hake', 'Arrowtooth Flounder', 'Other Groundfish',
    'Manila & Littleneck Clams', 'Other Shellfish', 'Oysters', 'Other Clams',
    'Red Chinook', 'Prawns', 'Octopus', 'Pacific Ocean Perch', 'Tuna',
    'Red Sea Urchins', 'Atlantic', 'White Chinook', 'Lingcod', 'Grey Cod',
    'Red Snapper', 'Skate', 'Silver Brite Chum', 'Semi Brite Chum', 'Dogfish',
    'Herring', 'Sea Cucumbers', 'Butter Clams', 'Rainbow Trout', 'Dark Chum',
    'Pink Chinook',
]
```

### Canonical Name Mapping

Maps raw input strings (lowercased/stripped) to canonical species names. Handles camelCase, ALLCAPS, typos, synonyms, and slash-separated aliases.

```python
CANONICAL_MAP = {
    # ── Plants & seaweed ──────────────────────────────────────────────────
    "floating kelp":                    "Floating Kelp",
    "seaweed":                          "Seaweed",
    "other aquatic plant":              "Other Aquatic Plant",

    # ── Non-species entries ───────────────────────────────────────────────
    "oil":                              "Oil",

    # ── Salmon species ────────────────────────────────────────────────────
    "pink":                             "Pink",
    "redchinook":                       "Red Chinook",
    "red chinook":                      "Red Chinook",
    "coho":                             "Coho",
    "sockeye":                          "Sockeye",
    "atlantic":                         "Atlantic Salmon",
    "darkchum":                         "Dark Chum",
    "dark chum":                        "Dark Chum",
    "pinkchinook":                      "Pink Chinook",
    "pink chinook":                     "Pink Chinook",
    "semibritechum":                    "Semi Brite Chum",
    "semi brite chum":                  "Semi Brite Chum",
    "steelhead":                        "Steelhead",
    "whitechinook":                     "White Chinook",
    "white chinook":                    "White Chinook",
    "silverbritechum":                  "Silver Brite Chum",
    "silver brite chum":                "Silver Brite Chum",
    "other salmon":                     "Other Salmon",

    # ── Char / Trout ──────────────────────────────────────────────────────
    "artic char":                       "Arctic Char",   # typo fix
    "arctic char":                      "Arctic Char",
    "rainbow trout":                    "Rainbow Trout",

    # ── Groundfish ────────────────────────────────────────────────────────
    "lingcod":                          "Lingcod",
    "tuna":                             "Tuna",
    "yelloweye rockfish / red snapper": "Yelloweye Rockfish / Red Snapper",
    "red snapper":                      "Yelloweye Rockfish / Red Snapper",
    "pacific rockfish / pacific ocean perch": "Pacific Rockfish / Pacific Ocean Perch",
    "pacific ocean perch":              "Pacific Rockfish / Pacific Ocean Perch",
    "pollock":                          "Pollock",
    "sablefish / black cod":            "Sablefish / Black Cod",
    "sablefish (groundfish)":           "Sablefish / Black Cod",
    "sablefish":                        "Sablefish / Black Cod",
    "grey (pacific) cod":               "Grey Cod",
    "grey cod":                         "Grey Cod",
    "halibut":                          "Halibut",
    "rex sole":                         "Rex Sole",
    "herring":                          "Herring",
    "other rockfish":                   "Other Rockfish",
    "petrale sole":                     "Petrale Sole",
    "rock sole":                        "Rock Sole",
    "hake":                             "Hake",
    "other fish":                       "Other Fish",
    "other groundfish":                 "Other Groundfish",
    "skates":                           "Skate",
    "skate":                            "Skate",
    "english (lemon) sole":             "English (Lemon) Sole",
    "dover sole":                       "Dover Sole",
    "other freshwater finsfish":        "Other Freshwater Finfish",  # typo fix
    "tilapia":                          "Tilapia",
    "flounders":                        "Flounder",
    "arrowtooth flounder / turbot":     "Arrowtooth Flounder / Turbot",
    "arrowtooth flounder":              "Arrowtooth Flounder / Turbot",
    "palchard / sardines":              "Pilchard / Sardines",        # typo fix
    "sturgeon":                         "Sturgeon",
    "barramundi":                       "Barramundi",
    "mackerel":                         "Mackerel",
    "dogfish":                          "Dogfish",

    # ── Shellfish – molluscs ──────────────────────────────────────────────
    "oysters":                          "Oysters",
    "mussels":                          "Mussels",
    "scallops":                         "Scallops",
    "squid":                            "Squid",
    "octopus":                          "Octopus",
    "clams - other":                    "Other Clams",
    "other clams":                      "Other Clams",
    "manila and littleneck clams":      "Manila & Littleneck Clams",
    "manila & littleneck clams":        "Manila & Littleneck Clams",
    "butter clams":                     "Butter Clams",
    "geoduck clams":                    "Geoduck Clams",
    "horse clams":                      "Horse Clams",

    # ── Shellfish – crustaceans ───────────────────────────────────────────
    "prawns":                           "Prawns",
    "crab":                             "Crab",
    "shrimp":                           "Shrimp",
    "other crustaceans":                "Other Crustaceans",
    "other crusteans":                  "Other Crustaceans",          # typo fix

    # ── Echinoderms ───────────────────────────────────────────────────────
    "red sea urchin":                   "Red Sea Urchin",
    "red sea urchins":                  "Red Sea Urchin",
    "green sea urchin":                 "Green Sea Urchin",
    "sea cucumber":                     "Sea Cucumber",
    "sea cucumbers":                    "Sea Cucumber",

    # ── Catch-all ─────────────────────────────────────────────────────────
    "other marine animal":              "Other Marine Animal",
    "other shellfish":                  "Other Shellfish",
}
```

### Helper: camelCase Splitter

```python
def decamel(s: str) -> str:
    """Split camelCase or PascalCase into space-separated words."""
    return re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', s)
```

---

## Category Mapping

Maps each canonical species name to one of 14 approved categories.

```python
CATEGORY_MAP = {
    # ── Salmon ───────────────────────────────────────────────────────────
    "Pink":                                     "Salmon",
    "Red Chinook":                              "Salmon",
    "Coho":                                     "Salmon",
    "Sockeye":                                  "Salmon",
    "Atlantic Salmon":                          "Salmon",
    "Dark Chum":                                "Salmon",
    "Pink Chinook":                             "Salmon",
    "Semi Brite Chum":                          "Salmon",
    "Silver Brite Chum":                        "Salmon",
    "White Chinook":                            "Salmon",
    "Other Salmon":                             "Salmon",
    "Steelhead":                                "Salmon",

    # ── Rockfish ─────────────────────────────────────────────────────────
    "Yelloweye Rockfish / Red Snapper":         "Rockfish",
    "Pacific Rockfish / Pacific Ocean Perch":   "Rockfish",
    "Other Rockfish":                           "Rockfish",

    # ── Sole ─────────────────────────────────────────────────────────────
    "Rex Sole":                                 "Sole",
    "Petrale Sole":                             "Sole",
    "Rock Sole":                                "Sole",
    "English (Lemon) Sole":                     "Sole",
    "Dover Sole":                               "Sole",

    # ── Groundfish ───────────────────────────────────────────────────────
    "Lingcod":                                  "Groundfish",
    "Pollock":                                  "Groundfish",
    "Sablefish / Black Cod":                    "Groundfish",
    "Grey Cod":                                 "Groundfish",
    "Halibut":                                  "Groundfish",
    "Hake":                                     "Groundfish",
    "Other Groundfish":                         "Groundfish",
    "Skate":                                    "Groundfish",
    "Dogfish":                                  "Groundfish",
    "Flounder":                                 "Groundfish",
    "Arrowtooth Flounder / Turbot":             "Groundfish",

    # ── Herring / Other Fish ─────────────────────────────────────────────
    "Herring":                                  "Herring / Other Fish",
    "Tuna":                                     "Herring / Other Fish",
    "Mackerel":                                 "Herring / Other Fish",
    "Pilchard / Sardines":                      "Herring / Other Fish",
    "Barramundi":                               "Herring / Other Fish",
    "Other Fish":                               "Herring / Other Fish",

    # ── Freshwater Finfish ───────────────────────────────────────────────
    "Rainbow Trout":                            "Freshwater Finfish",
    "Arctic Char":                              "Freshwater Finfish",
    "Tilapia":                                  "Freshwater Finfish",
    "Other Freshwater Finfish":                 "Freshwater Finfish",
    "Sturgeon":                                 "Freshwater Finfish",

    # ── Crustaceans ──────────────────────────────────────────────────────
    "Prawns":                                   "Crustaceans",
    "Crab":                                     "Crustaceans",
    "Shrimp":                                   "Crustaceans",
    "Other Crustaceans":                        "Crustaceans",

    # ── Bivalves ─────────────────────────────────────────────────────────
    "Oysters":                                  "Bivalves",
    "Mussels":                                  "Bivalves",
    "Scallops":                                 "Bivalves",
    "Manila & Littleneck Clams":                "Bivalves",
    "Butter Clams":                             "Bivalves",
    "Geoduck Clams":                            "Bivalves",
    "Horse Clams":                              "Bivalves",
    "Other Clams":                              "Bivalves",

    # ── Other Shellfish ──────────────────────────────────────────────────
    "Other Shellfish":                          "Other Shellfish",

    # ── Other Invertebrates ──────────────────────────────────────────────
    "Octopus":                                  "Other Invertebrates",
    "Squid":                                    "Other Invertebrates",
    "Red Sea Urchin":                           "Other Invertebrates",
    "Green Sea Urchin":                         "Other Invertebrates",
    "Sea Cucumber":                             "Other Invertebrates",
    "Other Marine Animal":                      "Other Invertebrates",

    # ── Aquatic Plants ───────────────────────────────────────────────────
    "Floating Kelp":                            "Aquatic Plants",
    "Seaweed":                                  "Aquatic Plants",
    "Other Aquatic Plant":                      "Aquatic Plants",

    # ── Fish Oil ─────────────────────────────────────────────────────────
    "Oil":                                      "Fish Oil",
}

def categorize(canonical: str) -> str:
    """Return the category for a canonical species name."""
    return CATEGORY_MAP.get(canonical, f"UNCATEGORIZED: {canonical}")

def standardize(raw: str) -> str:
    """Return the canonical species name for a raw input string."""
    cleaned = decamel(raw).strip().lower()
    return CANONICAL_MAP.get(cleaned, f"UNKNOWN: {raw}")
```

---

## Run Transformations

Prints a full mapping table with warnings for any unmatched or uncategorized entries, followed by a category breakdown.

```python
if __name__ == "__main__":
    results = [(raw, standardize(raw), categorize(standardize(raw))) for raw in RAW_SPECIES]

    # Print mapping table
    print(f"{'RAW INPUT':<45}  {'STANDARDIZED':<45}  {'CATEGORY'}")
    print("-" * 110)
    for raw, std, cat in results:
        warn = "  ⚠" if std.startswith("UNKNOWN") or cat.startswith("UNCAT") else ""
        print(f"{raw:<45}  {std:<45}  {cat}{warn}")

    # Summary
    unique_canonical = sorted(set(std for _, std, _ in results))
    unknowns   = [r for r, s, _ in results if s.startswith("UNKNOWN")]
    uncatd     = [s for _, s, c in results if c.startswith("UNCAT")]

    print(f"\n{'─'*110}")
    print(f"  Input entries      : {len(RAW_SPECIES)}")
    print(f"  Unique canonical   : {len(unique_canonical)}")
    print(f"  Unmatched species  : {len(unknowns)}")
    print(f"  Uncategorized      : {len(uncatd)}")
    if unknowns:  print(f"  ⚠ Unmatched : {unknowns}")
    if uncatd:    print(f"  ⚠ Uncatd    : {uncatd}")

    # Category breakdown
    from collections import Counter
    counts = Counter(cat for _, _, cat in results)
    print(f"\n{'─'*110}")
    print("CATEGORY BREAKDOWN (unique canonical names per category):")
    canonical_by_cat = {}
    for _, std, cat in results:
        canonical_by_cat.setdefault(cat, set()).add(std)
    for cat in sorted(canonical_by_cat):
        names = sorted(canonical_by_cat[cat])
        print(f"\n  [{cat}]")
        for n in names:
            print(f"    • {n}")
```

---

## Apply to Dataset

```python
df["species_clean"]    = df["species"].map(standardize)
df["species_category"] = df["species_clean"].map(categorize)
```

---

## Export

```python
df.to_excel("AFPS cleanest.xlsx")
```
