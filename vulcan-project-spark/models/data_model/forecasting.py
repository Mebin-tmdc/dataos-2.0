import typing as t
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from vulcan import ExecutionContext, model
from vulcan import ModelKindName

@model(
    "s3depot.device_pari.device_issue_forecast",
    columns={
        "forecast_date": "timestamp",
        "device_id": "string",
        "device_category": "string",
        "model_type": "string",
        "manufacturer": "string",
        "category": "string",
        "predicted_issues": "double",
        "confidence_lower": "double",
        "confidence_upper": "double",
        "trend_direction": "string",
        "days_ahead": "int",
        "model_version": "string",
    },
    kind=dict(
        name=ModelKindName.FULL,
    ),
    grains=["forecast_date", "device_id", "category"],
    depends_on=["s3depot.device_pari.issues", "s3depot.device_pari.devices"],
    cron='@daily',
    tags=["ml", "forecasting", "device_issues", "predictive"],
    terms=["device.forecast", "ml.issue_prediction"],
    description="ML forecasting model that analyzes devices with issues and predicts future issue occurrences using time-series analysis.",
    column_descriptions={
        "forecast_date": "Date for which issues are predicted",
        "device_id": "Unique identifier of the device",
        "device_category": "Category of the device (PC, Mobile, etc.)",
        "model_type": "Device model type",
        "manufacturer": "Device manufacturer",
        "category": "Issue category being predicted",
        "predicted_issues": "Forecasted number of issues (0-1 probability scale)",
        "confidence_lower": "Lower bound of confidence interval",
        "confidence_upper": "Upper bound of confidence interval",
        "trend_direction": "Trend direction: increasing, decreasing, or stable",
        "days_ahead": "Number of days ahead this prediction is for",
        "model_version": "Version identifier for the forecasting model",
    },
    column_tags={
        "forecast_date": ["dimension", "grain", "date"],
        "device_id": ["dimension", "grain", "identifier"],
        "device_category": ["dimension", "device"],
        "model_type": ["dimension", "device"],
        "manufacturer": ["dimension", "device"],
        "category": ["dimension", "issues"],
        "predicted_issues": ["measure", "ml_prediction"],
        "confidence_lower": ["measure", "ml_prediction"],
        "confidence_upper": ["measure", "ml_prediction"],
        "trend_direction": ["dimension", "ml_feature"],
        "days_ahead": ["dimension", "forecast"],
        "model_version": ["metadata", "ml", "version"],
    },
    column_terms={
        "forecast_date": ["device_issue_forecast.forecast_date", "forecast.date"],
        "device_id": ["device_issue_forecast.device_id", "device.identifier"],
        "device_category": ["device_issue_forecast.device_category", "device.category"],
        "model_type": ["device_issue_forecast.model_type", "device.model_type"],
        "manufacturer": ["device_issue_forecast.manufacturer", "device.manufacturer"],
        "category": ["device_issue_forecast.category", "issue.category"],
        "predicted_issues": ["device_issue_forecast.predicted_issues", "ml.issue_probability"],
        "confidence_lower": ["device_issue_forecast.confidence_lower", "ml.confidence_lower"],
        "confidence_upper": ["device_issue_forecast.confidence_upper", "ml.confidence_upper"],
        "trend_direction": ["device_issue_forecast.trend_direction", "ml.trend_direction"],
        "days_ahead": ["device_issue_forecast.days_ahead", "forecast.horizon_days"],
        "model_version": ["device_issue_forecast.model_version", "ml.model_version"],
    },
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> t.Iterator[pd.DataFrame]:
    """ML Forecasting model - predicts device issues using time-series analysis"""

    # Fetch historical device issues data
    issues_query = """
    SELECT
        i.device_id,
        i.category,
        i.reported_at,
        i.status,
        i.insight_id,
        i.details,
        d.device_category,
        d.model_type,
        d.manufacturer,
        d.is_active,
        d.platform
    FROM s3depot.device_pari.issues i
    LEFT JOIN s3depot.device_pari.devices d
        ON (i.device_id = d.id OR i.device_id = d.device_id)
    """

    df = context.fetchdf(issues_query)

    if df.empty or len(df) == 0:
        # SQLMesh/Vulcan expects no yield for empty result sets.
        yield from ()
        return

    # Ensure datetime columns are properly parsed
    df['reported_at'] = pd.to_datetime(df['reported_at'])

    # Aggregate issues by device, category, and date
    df['issue_date'] = df['reported_at'].dt.date
    daily_issues = df.groupby([
        'device_id', 'category', 'device_category', 'model_type',
        'manufacturer', 'issue_date'
    ]).size().reset_index(name='issue_count')

    # Generate forecasts
    forecast_days = 7  # Predict next 7 days
    forecast_horizons = [1, 3, 7]  # Predict 1, 3, and 7 days ahead

    forecasts = []

    for (device_id, category, device_cat, model_type, manufacturer), group in daily_issues.groupby([
        'device_id', 'category', 'device_category', 'model_type', 'manufacturer'
    ]):
        group = group.sort_values('issue_date')

        if len(group) < 3:
            # Sparse history fallback: emit stable forecasts from observed mean.
            baseline = float(group['issue_count'].mean())
            predicted_issues = float(np.clip(baseline, 0.0, 1.0))
            confidence_lower = float(max(0.0, predicted_issues - 0.1))
            confidence_upper = float(min(1.0, predicted_issues + 0.1))
            trend = "stable"

            for days_ahead in forecast_horizons:
                forecast_date = execution_time.date() + timedelta(days=days_ahead)
                forecasts.append({
                    'forecast_date': pd.Timestamp(forecast_date),
                    'device_id': device_id,
                    'device_category': device_cat if pd.notna(device_cat) else 'Unknown',
                    'model_type': model_type if pd.notna(model_type) else 'Unknown',
                    'manufacturer': manufacturer if pd.notna(manufacturer) else 'Unknown',
                    'category': category if pd.notna(category) else 'Unknown',
                    'predicted_issues': float(round(predicted_issues, 4)),
                    'confidence_lower': float(round(confidence_lower, 4)),
                    'confidence_upper': float(round(confidence_upper, 4)),
                    'trend_direction': trend,
                    'days_ahead': int(days_ahead),
                    'model_version': 'v1.0-linear-reg'
                })
            continue

        # Prepare time series data
        group['days_since_first'] = (pd.to_datetime(group['issue_date']) - pd.to_datetime(group['issue_date'].min())).dt.days

        for days_ahead in forecast_horizons:
            forecast_date = execution_time.date() + timedelta(days=days_ahead)

            # Simple linear regression for trend
            x = group['days_since_first'].values.reshape(-1, 1)
            y = group['issue_count'].values

            # Calculate trend using numpy polyfit
            if len(x) >= 2:
                coeffs = np.polyfit(x.flatten(), y, 1)
                slope = coeffs[0]
                intercept = coeffs[1]

                # Predict for future date
                last_day = group['days_since_first'].max()
                future_day = last_day + days_ahead
                predicted_value = slope * future_day + intercept

                # Clamp to valid range
                predicted_issues = float(np.clip(predicted_value, 0.0, 1.0))

                # Calculate confidence intervals based on historical variance
                residuals = y - (slope * x.flatten() + intercept)
                std_error = np.std(residuals) if len(residuals) > 1 else 0.1

                confidence_lower = float(max(0.0, predicted_issues - 1.96 * std_error))
                confidence_upper = float(min(1.0, predicted_issues + 1.96 * std_error))

                # Determine trend direction
                if slope > 0.01:
                    trend = "increasing"
                elif slope < -0.01:
                    trend = "decreasing"
                else:
                    trend = "stable"
            else:
                predicted_issues = float(group['issue_count'].mean())
                confidence_lower = float(max(0.0, predicted_issues - 0.1))
                confidence_upper = float(min(1.0, predicted_issues + 0.1))
                trend = "stable"

            forecasts.append({
                'forecast_date': pd.Timestamp(forecast_date),
                'device_id': device_id,
                'device_category': device_cat if pd.notna(device_cat) else 'Unknown',
                'model_type': model_type if pd.notna(model_type) else 'Unknown',
                'manufacturer': manufacturer if pd.notna(manufacturer) else 'Unknown',
                'category': category if pd.notna(category) else 'Unknown',
                'predicted_issues': float(round(predicted_issues, 4)),
                'confidence_lower': float(round(confidence_lower, 4)),
                'confidence_upper': float(round(confidence_upper, 4)),
                'trend_direction': trend,
                'days_ahead': int(days_ahead),
                'model_version': 'v1.0-linear-reg'
            })

    # Convert forecasts to DataFrame
    if not forecasts:
        # Skip write when there is nothing to forecast.
        yield from ()
        return

    result_df = pd.DataFrame(forecasts)
    for col in ("predicted_issues", "confidence_lower", "confidence_upper"):
        result_df[col] = result_df[col].astype("float64")
    result_df["days_ahead"] = result_df["days_ahead"].astype("int64")
    result_df = result_df.sort_values(by="device_id", kind="stable")

    # Add aggregate category forecasts for devices with high issue rates
    high_risk_devices = daily_issues.groupby('device_id')['issue_count'].sum().reset_index()
    high_risk_devices = high_risk_devices[high_risk_devices['issue_count'] >= 5]

    yield result_df