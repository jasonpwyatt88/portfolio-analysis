-- ============================================================================
-- analysis.sql
-- Analysis views built on top of schema.sql. Run this AFTER schema.sql and
-- after the notebook has loaded data.
--
-- These recreate the views your old script was dropping (vw_monthly_volatility,
-- vw_portfolio_overview, vw_monthly_summary) but that were never actually
-- defined anywhere in the file -- that logic likely got lost during one of the
-- error-driven rewrites. Rebuilt here from scratch, each with a stated purpose.
-- ============================================================================

DROP VIEW IF EXISTS vw_monthly_returns;
DROP VIEW IF EXISTS vw_monthly_volatility;
DROP VIEW IF EXISTS vw_portfolio_overview;

-- Compound monthly return per ticker: turns daily returns into a single
-- "how did this stock do in March 2024" number via log-return summation.
CREATE VIEW vw_monthly_returns AS
SELECT
    Ticker,
    Sector,
    strftime('%Y-%m', Date) AS year_month,
    EXP(SUM(LN(1 + Daily_return))) - 1 AS monthly_return
FROM stock_data
WHERE Daily_return IS NOT NULL
GROUP BY Ticker, strftime('%Y-%m', Date);

-- Monthly volatility (std dev of daily returns) per ticker -- the risk side
-- of the risk/return picture the dashboard should be pairing this with.
CREATE VIEW vw_monthly_volatility AS
SELECT
    Ticker,
    Sector,
    strftime('%Y-%m', Date) AS year_month,
    AVG(Daily_return) AS avg_daily_return,
    -- SQLite has no built-in STDEV, so it's computed manually:
    -- sqrt(avg(x^2) - avg(x)^2)
    SQRT(AVG(Daily_return * Daily_return) - AVG(Daily_return) * AVG(Daily_return)) AS daily_return_stdev,
    COUNT(*) AS trading_days
FROM stock_data
WHERE Daily_return IS NOT NULL
GROUP BY Ticker, strftime('%Y-%m', Date);

-- Equal-weighted portfolio overview: average return per sector per day,
-- for a simple "if I held all 10 names in this sector equally" view.
CREATE VIEW vw_portfolio_overview AS
SELECT
    Date,
    Sector,
    AVG(Daily_return) AS sector_avg_daily_return,
    COUNT(*) AS tickers_counted
FROM stock_data
WHERE Daily_return IS NOT NULL
GROUP BY Date, Sector;

-- Example queries -- uncomment/run individually to explore:

-- SELECT * FROM vw_monthly_returns WHERE Ticker = 'AAPL' ORDER BY year_month;
-- SELECT * FROM vw_monthly_volatility WHERE Ticker = 'NVDA' ORDER BY year_month;
-- SELECT * FROM vw_portfolio_overview WHERE Sector = 'Information Technology' ORDER BY Date;
