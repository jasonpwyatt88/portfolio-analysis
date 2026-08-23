# Trading Portfolio Analysis

A data pipeline analyzing daily price performance across a
110-stock universe (11 GICS-style sectors, 10 tickers each) from 2020-01-02 onward,
benchmarked against the S&P 500 (SPY).


## Opening Summary


Seven sectors beat the benchmark SPY on total return, but only two beat it on
Sharpe ratio. Equal-weighting all 110 tickers beat SPY on both, which is why I
used EW110 as a second benchmark: SPY is cap-weighted across 500 tickers, while
the sectors here are equal-weighted baskets of 10.

Picking sectors on past performance did not hold up. The best combination from
2020 to 2023 — Information Technology plus Health Care — finished 1,190th of
2,047 on 2024 to 2026. Technology, the best sector in sample, finished 1,924th,
in the bottom 6% out of sample.

The aim was to determine which sectors are outperforming the benchmark SPY. The
Sharpe ratio is used to determine whether the cost of a sector's outperformance
is higher volatility, i.e. risk. The portfolio was rebalanced to equal weight to
keep the analysis fair. I ran a series of combinations of sectors to see which
combination had the best return. To test whether those combinations held up, a
sample of returns from 2020 to 2023 was used to select the highest performers,
and I then tested whether those performers held to the same standard from 2024
to 2026.

Two limitations. The first is the anomalous activity from 2020 to 2022 due to
the pandemic market pullback — however, markets will always have some type of
unusual activity over any time period chosen. The second is selection bias in
the universe: the 10 tickers in each sector were chosen partly because of
popularity, so one could say they are close to the top performers in each of
those given sectors. The selection bias on the tickers I believe skewed the 
results higher than a random sample of tickers.

## What's in this repo

| Path | What it is |
|---|---|
| `notebooks/data_collection.ipynb` | Pulls prices from Yahoo Finance, reshapes to long format, computes returns, loads SQLite |
| `sql/schema.sql` | Table definitions (SQLite) — run before/via the notebook's load step |
| `sql/analysis.sql` | Analysis views: monthly returns, monthly volatility, sector portfolio overview |
| `data/stock_data.csv` | Long-format price + daily return data, all 110 tickers |
| `data/benchmark_data.csv` | SPY price + daily return, same shape |
| `data/stock_data.db` | SQLite database — the tables/views from `sql/` populated with the CSV data |

## Ticker universe

110 tickers, 10 per sector, across: Communication Services, Consumer Discretionary,
Consumer Staples, Energy, Financials, Health Care, Industrials, Information Technology,
Materials, Real Estate, Utilities. The full ticker-to-sector mapping lives in
`notebooks/data_collection.ipynb` (`TICKER_SECTORS` dict) — that's the single source
of truth for the universe, rather than being hardcoded separately in SQL 

## How to reproduce this from scratch

1. `pip install yfinance pandas jupyter`
2. Open and run `notebooks/data_collection.ipynb` top to bottom. It will:
   - download prices for all 110 tickers + SPY from Yahoo Finance
   - write `data/raw/stock_data_raw.csv` (wide format, as downloaded)
   - write `data/stock_data.csv` and `data/benchmark_data.csv` (long format, with returns)
   - build `data/stock_data.db` from `sql/schema.sql` and load it
   - run sanity checks (ticker count, row count, null spot-check)
3. Optionally run `sqlite3 data/stock_data.db < sql/analysis.sql` to (re)build the
   monthly-return / volatility / portfolio-overview views used by the dashboard.
4. Open `dashboard/trading_performance.pbix` in Power BI Desktop and point its data
   source at `data/stock_data.db` if the path has changed.

## Database schema

```
sector_dim(Date, Ticker PK, Sector)
stock_data(Date, Ticker, Sector, Adj_Close, Daily_return)   PK (Date, Ticker)
benchmark_data(Date, Ticker, Sector, Adj_Close, Benchmark_return)  PK (Date, Ticker)
cash_flows(Flow_ID PK, Date, CashFlow)   -- reserved for a future money-weighted-return extension

views:
  vw_benchmark_returns   -- recomputes Benchmark_return from Adj_Close
  vw_daily_returns       -- stock_data joined to the benchmark by date
  vw_monthly_returns     -- compounded monthly return per ticker
  vw_monthly_volatility  -- std dev of daily returns per ticker per month
  vw_portfolio_overview  -- equal-weighted average daily return per sector
```

## Project history / notes

This project started as a 12-ticker pull and was expanded to the current 110-ticker
universe partway through, which is why earlier commits/files may reference a smaller
ticker list. The pipeline was originally built against a local SQL Server instance;
it now targets SQLite for portability (no server setup required to reproduce), with
SQL Server as an optional stretch target — the schema in `sql/schema.sql` is a direct
port and uses only syntax with a straightforward SQL Server equivalent.


