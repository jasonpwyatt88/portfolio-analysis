-- ============================================================================
-- schema.sql
-- SQLite schema for the trading portfolio dataset.
--
-- Why SQLite (not SQL Server, which the project used originally):
--   - No server/instance to install, start, or troubleshoot connection strings for
--   - The .db file travels with the repo, so anyone can clone + run without setup
--   - Everything here (tables, views, window functions) has a direct SQL Server
--     equivalent if you later want to port it over (see notebooks/README notes).
--
-- Run via: sqlite3 data/stock_data.db < sql/schema.sql
-- (or executed automatically from the data_collection notebook)
-- ============================================================================

DROP TABLE IF EXISTS stock_data;
DROP TABLE IF EXISTS benchmark_data;
DROP TABLE IF EXISTS sector_dim;
DROP TABLE IF EXISTS cash_flows;
DROP VIEW  IF EXISTS vw_benchmark_returns;
DROP VIEW  IF EXISTS vw_daily_returns;

-- One row per ticker: static sector lookup (dimension table)
CREATE TABLE sector_dim (
    Date   TEXT,
    Ticker TEXT PRIMARY KEY,
    Sector TEXT
);

-- One row per (Date, Ticker): the core fact table
CREATE TABLE stock_data (
    Date         TEXT NOT NULL,
    Ticker       TEXT NOT NULL,
    Sector       TEXT,
    Adj_Close    REAL,
    Daily_return REAL,
    PRIMARY KEY (Date, Ticker)
);

-- Benchmark (SPY) prices, kept separate from the 110-ticker universe
CREATE TABLE benchmark_data (
    Date              TEXT NOT NULL,
    Ticker            TEXT NOT NULL,
    Sector            TEXT,
    Adj_Close         REAL,
    Benchmark_return  REAL,
    PRIMARY KEY (Date, Ticker)
);

-- Optional: track portfolio cash movements (deposits/withdrawals) if you
-- extend this into a real portfolio-performance (money-weighted return) project
CREATE TABLE cash_flows (
    Flow_ID  INTEGER PRIMARY KEY AUTOINCREMENT,
    Date     TEXT,
    CashFlow REAL
);

-- Recomputes benchmark return from price (kept as a view, not stored,
-- so it's always consistent with Adj_Close — same intent as the original script)
CREATE VIEW vw_benchmark_returns AS
SELECT
    Date,
    Ticker,
    Adj_Close,
    (Adj_Close - LAG(Adj_Close) OVER (ORDER BY Date))
        / NULLIF(LAG(Adj_Close) OVER (ORDER BY Date), 0) AS Benchmark_return
FROM benchmark_data;

-- Stock daily returns joined against the benchmark for the same date —
-- the main view Power BI / analysis queries should read from
CREATE VIEW vw_daily_returns AS
SELECT
    s.Date,
    s.Ticker,
    s.Sector,
    s.Adj_Close AS close_price,
    s.Daily_return,
    b.Benchmark_return
FROM stock_data AS s
LEFT JOIN vw_benchmark_returns AS b
    ON s.Date = b.Date;
