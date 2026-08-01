# Power BI -> Tableau Public migration notes

Power BI Desktop is Windows-only; this project now targets **Tableau Public** on Mac.
`trading_performance.pbix` is kept in this folder as a reference for the measure logic
below (open it on a Windows machine, or just read this file) but is no longer the live
dashboard.

## Data source

Connect Tableau Public directly to `data/stock_data.csv` (all 110 tickers, long format)
and `data/benchmark_data.csv` (SPY). No database driver needed — Tableau reads CSV natively.

## Measures, ported from the original DAX

| Metric | Original DAX (Power BI) | Tableau calculated field |
|---|---|---|
| Total Return | `PRODUCTX(ADDCOLUMNS(...), 1+Daily_return) - 1` | `EXP(SUM(LN(1 + [Daily_return]))) - 1` |
| Years (selected) | `DATEDIFF(MIN(date), MAX(date), DAY) / 365.25` | `DATEDIFF('day', MIN([Date]), MAX([Date])) / 365.25` |
| CAGR | `(1 + TotalReturn) ^ (1/Years) - 1` | `POWER(1 + [Total Return], 1 / [Years (selected)]) - 1` |
| Sharpe Ratio | `AVERAGE(Daily_return) / STDEV.P(Daily_return) * SQRT(252)` | `AVG([Daily_return]) / STDEVP([Daily_return]) * SQRT(252)` |

Build them in this order in Tableau (Analysis > Create Calculated Field), since CAGR
references Total Return and Years:

1. `Total Return` = `EXP(SUM(LN(1 + [Daily_return]))) - 1`
2. `Years (selected)` = `DATEDIFF('day', MIN([Date]), MAX([Date])) / 365.25`
3. `CAGR` = `IIF([Years (selected)] > 0, POWER(1 + [Total Return], 1 / [Years (selected)]) - 1, NULL)`
4. `Sharpe Ratio` = `AVG([Daily_return]) / STDEVP([Daily_return]) * SQRT(252)`

Note: `STDEVP` = population standard deviation, matching Power BI's `STDEV.P` (not the
sample stdev `STDEV`/`STDEV.S` — using the wrong one will give a slightly different Sharpe).

## Known caveat carried over from the original (worth understanding, not necessarily fixing)

`Total Return` (and therefore `CAGR`) is a straight product of `(1 + Daily_return)` across
every row currently in view. Filtered to **one ticker**, that correctly gives that ticker's
compounded return. Filtered to **multiple tickers at once with no per-ticker breakdown**,
it multiplies each ticker's own total return together — mathematically equivalent to "what
if you experienced every stock's entire holding period back to back," not a real weighted
portfolio return. Fine for "pick a ticker, see its stats" cards; not fine for "what did my
whole 110-stock portfolio return" without also grouping by Ticker (e.g. a table broken out
by Ticker, or averaging per-ticker Total Return across tickers instead).

## Layout to rebuild (matches the original 3-page structure)

- Page 1: KPI cards (Total Return, CAGR, Sharpe Ratio) + line chart of cumulative return
  over time + Ticker and Sector filters (slicers)
- Page 2: supporting table/detail view
- Page 3: single additional card/view
