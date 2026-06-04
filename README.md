# Cloud Kitchen Market Intelligence — College Road, Nashik
> Data sourced from Swiggy / Zomato · June 2026

---

## Project Objective

Analyse the existing restaurant landscape on College Road, Nashik to identify market gaps, pricing patterns, and cuisine saturation — and use those findings to recommend a viable cloud kitchen launch strategy within a ₹5 lakh budget.

---

## Tech Stack

| Tool | Purpose |
|---|---|
| Chrome DevTools (Network tab) | API interception and JSON payload capture |
| Microsoft Excel / CSV | Raw data entry and structured storage |
| Python (pandas) | Data cleaning, normalization, NULL handling |
| MySQL 8.0 | Relational schema design and analytical queries |
| openpyxl / xlsxwriter | Multi-sheet Excel report generation |

---

## Folder Structure

```
Cloud_Kitchen_Market_Intelligence/
│
├── 01_raw_dataset.csv               # Original uncleaned restaurant data (35 records)
├── 02_cleaned_dataset.csv           # Cleaned, normalized, analysis-ready dataset
├── 03_menu_dataset.csv              # Menu intelligence for 5 selected restaurants
├── 04_sql_schema_queries.sql        # Full schema (6 tables) + analytical queries Q1–Q6
├── 05_methodology_report.pdf        # End-to-end data workflow and business analysis report
│
├── screenshots/
│   ├── ss01_network_tab.png         # Chrome DevTools Network tab — XHR/Fetch filter active
│   ├── ss02_api_request.png         # Selected API call — request headers and URL
│   └── ss03_json_response.png       # JSON response payload from Swiggy menu API
│
└── README.md
```

---

## Dataset Description

### Restaurant Dataset (`01_raw_dataset.csv` → `02_cleaned_dataset.csv`)

- **Records:** 35 restaurants, College Road locality only
- **Source:** Swiggy / Zomato (manual extraction via XHR API inspection)
- **Fields collected:**

| Field | Type | Notes |
|---|---|---|
| Restaurant Name | Text | Primary identifier |
| Rating | Float | 0.0 – 5.0 scale |
| Number of Reviews | Integer | Commas stripped |
| Cost for Two | Integer | ₹ symbol removed |
| Cuisines | Text | Comma-separated tags, normalized |
| Locality | Text | All records: College Road |
| Restaurant Type | Text | Cloud Kitchen / Dine-In / Unknown |
| Delivery Time | Text | String range e.g. "30–35 min" |

**Missing values in raw data:**
- Reviews: 6 records — estimated from platform context during cleaning
- Cost for Two: 6 records — estimated from platform context during cleaning
- Delivery Time: 21 records — platform did not expose estimates for all outlets

### Menu Dataset (`03_menu_dataset.csv`)

- **Restaurants:** KFC · McDonald's · Pizza Hut · Oven Story Pizza · Theobroma
- **Per restaurant:** 10 menu items with categories, prices, and bestseller identification
- **Pricing source:** Platform-listed delivery prices

---

## Key Insights

### Cuisine Saturation
Three categories dominate College Road and represent high-competition segments:

| Cuisine | Count | Status |
|---|---|---|
| Fast Food | 7 | Saturated |
| North Indian | 6 | Saturated |
| Continental | 6 | Saturated |
| Italian | 5 | Moderate |
| South Indian | 4 | Moderate |
| **Biryani** | **1** | **Gap — opportunity** |
| **Maharashtrian** | **1** | **Gap — opportunity** |

### Market Gap — Cloud Kitchen Recommendation
- **Recommended cuisine:** Biryani (1 existing outlet, rating 3.4, only 36 reviews — zero quality benchmark to beat)
- **Target audience:** Students and working professionals
- **Price range:** ₹149 – ₹349 per item
- **Advantage:** Cloud kitchen model eliminates rent costs, enabling competitive pricing against dine-in incumbents

### Operational Efficiency Benchmark
**Al Arabian Express** — the highest-volume, consistently rated outlet in the dataset:
- Rating: 4.6
- Reviews: 16,000+ (highest in dataset by a significant margin)
- Delivery time: 30–35 min
- Pricing: mid-premium (₹500 for two)

---

## SQL Highlights (`04_sql_schema_queries.sql`)

The schema solves two structural problems in the raw data:

1. **Multi-cuisine strings** — normalized into a proper many-to-many relationship (`restaurants` → `restaurant_cuisines` → `cuisines`)
2. **Delivery time ranges** — split from a string field into `delivery_time_min` and `delivery_time_max` integer columns

### Schema — 6 Normalized Tables

```
localities → restaurants → restaurant_cuisines ↔ cuisines
                        → menu_items ↔ menu_categories
```

### Queries Included

| Query | Description |
|---|---|
| Q1 | Top 5 highest-rated restaurants (rating + review tie-break) |
| Q2 | Average cost-for-two grouped by cuisine |
| Q3 | Restaurants serving more than one cuisine |
| Q4 | Highest-priced menu item (global maximum, handles ties) |
| Q5 | Bestseller item per restaurant |
| Q6 | Cloud Kitchen vs Dine-In performance comparison |

---

## Network Investigation

Restaurant data on Swiggy is loaded dynamically via JavaScript — static HTML parsing does not work. Data was extracted by:

1. Opening the College Road, Nashik feed on Swiggy
2. Opening Chrome DevTools → Network tab → filtering to Fetch/XHR
3. Identifying the API call returning the restaurant/menu JSON payload
4. Capturing the JSON response structure and manually recording fields

**API evidence from screenshots:**

| Endpoint Pattern | Method | Response Type | Information Returned |
|---|---|---|---|
| `dapi/menu/pl?page-type=REGULAR_MENU&complete-menu=true&lat=...&lng=...&restaurantId=236456` | GET | `application/json; charset=utf-8` | Restaurant name, rating, delivery time, menu categories, items, prices, bestseller flags |

Screenshots in `screenshots/` document the DevTools session. The screenshots show the Pizza Hut College Road outlet (restaurantId=236456) as the captured example, with status code 200 OK and gzip-encoded JSON response.

---

## How to View This Project

**Datasets:** Open any CSV in Excel, Google Sheets, or a text editor.

**SQL schema + queries:**
```sql
-- Run in MySQL Workbench or any MySQL 8.0+ client
-- Step 1: Execute the CREATE TABLE statements (top of file)
-- Step 2: Load your data into the tables
-- Step 3: Run Q1–Q6 queries individually
```

**Methodology report:** Open `05_methodology_report.pdf` — covers data collection, cleaning decisions, assumptions, challenges, and business recommendations.

---

## Cleaning Decisions

| Field | Decision | Reason |
|---|---|---|
| Rating (0 missing) | No action required | No missing values in raw data |
| Reviews (6 missing) | Estimated from platform context | Retained as best-effort approximation; flagged in report |
| Cost for Two (6 missing) | Estimated from platform context | Retained as best-effort approximation; flagged in report |
| Delivery time (21 missing) | Kept as "N/A" / estimated | Platform did not expose for all outlets |
| Cuisine variants | Regex normalization | "north-indian", "north indian food" → "North Indian" |
| Restaurant type | 3 values only | Cloud Kitchen / Dine-In / Unknown |
| Pizza Hut type | Reclassified to Cloud Kitchen | Listed as "Cloud + Dine-in"; delivery-primary outlet |

---

## Project Limitations

- Dataset covers 35 restaurants (one locality, one point in time) — conclusions are directional, not statistically definitive
- Menu prices for 5 restaurants are based on platform-listed delivery prices
- Cloud kitchen type classification for ~4–5 records involved manual judgment due to inconsistent platform signals
- Missing-value records (reviews, cost, delivery time) were filled with estimated values during cleaning, not imputed algorithmically

---

*Submitted as part of data analytics internship assessment · College Road, Nashik · June 2026*
