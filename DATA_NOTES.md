# Data Notes

Two discrepancies found while organizing this repository, recorded here so
the numbers in `README.md` can be traced back to their source.

## 1. The "Dataset Description" markdown cell doesn't match the actual data

Both notebooks open with the same boilerplate description:

> "This dataset contains marketing campaign data collected from **11,162**
> individuals... including... **yearly balance**..."

Neither claim matches the dataset actually loaded and analyzed in the same
notebooks:

- The real shape, printed in `notebooks/Bank_Marketing_EDA_02_after_cleaning.ipynb`
  cell 8, is **42,188 rows × 21 columns**, not 11,162 rows.
- There is no `balance` column anywhere in the dataset — the actual columns
  are `age, job, marital, education, default, housing, loan, contact, month,
  day_of_week, duration, campaign, pdays, previous, poutcome, emp.var.rate,
  cons.price.idx, cons.conf.idx, euribor3m, nr.employed, y`.

This description text appears to be copy-pasted from a different, smaller
"Bank Marketing" dataset variant (the well-known 11,162-row Kaggle version,
which does have a `balance` column) rather than describing the
42,188-row/21-column `bank-additional`-style dataset this project actually
uses. `README.md` in this repo describes the dataset actually loaded, not
the boilerplate text.

## 2. The committed CSV predates the notebook's outlier-capping step

`notebooks/Bank_Marketing_EDA_02_after_cleaning.ipynb` caps the `campaign`
column at 10 (cell "Outlier Treatment (Campaign Column)"):

```python
df_eda['campaign'] = df_eda['campaign'].clip(upper=10)
```

But `data/BankMarket_cleaned_for_orange.csv` — the file the Orange workflow
in `orange/Bank_Marketing_Orange_Workflow.ows` actually reads — still has
`campaign` values up to **56**. The notebook contains no `to_csv()` call, so
this file was exported manually at some point before the capping step was
added (or from an earlier notebook revision) and never re-exported
afterward. The Orange workflow's results should be read with this in mind:
its `campaign` feature includes the same unrealistic outliers (max 56) that
the notebook itself identifies and treats as a likely CRM data-entry error.

## What's unaffected

The 16-table SQL schema (`sql/01_create_schema.sql`), the seed data
(`sql/02_seed_data.sql`), and the 10 analytical queries/views
(`sql/03_analysis_queries.sql`) are a self-contained relational-database
exercise unrelated to the Bank Marketing dataset above, and are unaffected
by either discrepancy.
