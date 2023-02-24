-- Select input scoring data and assign aliases.
WITH InputData AS
(
    SELECT
        [instant],
        [season],
        [yr],
        [mnth],
        [weekday],
        [weathersit],
        [incentive_level],
        [incentive_duration_remaining],
        [power_grid_premium],
        [power_grid_risk],
        [_automl_target_col_WASNULL],
        [instant_WASNULL],
        [season_WASNULL],
        [yr_WASNULL],
        [mnth_WASNULL],
        [weekday_WASNULL],
        [weathersit_WASNULL],
        [incentive_level_WASNULL],
        [incentive_duration_remaining_WASNULL],
        [power_grid_premium_WASNULL],
        [power_grid_risk_WASNULL],
        [_automl_year],
        [_automl_year_iso],
        [_automl_half],
        [_automl_quarter],
        [_automl_month],
        [_automl_day],
        [_automl_wday],
        [_automl_qday],
        [_automl_week]
    FROM [dbo].[DemandForecast]
)
-- Using T-SQL Predict command to score machine learning models. 
SELECT *
FROM PREDICT (MODEL = (SELECT [model] FROM dbo.Models WHERE [ID] = 'demand_forecast_model:3'),
              DATA = InputData,
              RUNTIME = ONNX) WITH ([variable1] [bigint])
GO