import typing as t
from datetime import datetime, timedelta

import numpy as np
import pandas as pd
from sklearn.preprocessing import OrdinalEncoder, PolynomialFeatures, StandardScaler
from vulcan import ExecutionContext, ModelKindName, model


@model(
    "s3depot.device_meb.device_issue_features",
    columns={
        "snapshot_date": "timestamp",
        "device_id": "string",
        "device_category": "string",
        "manufacturer": "string",
        "issues_7d": "int",
        "issues_30d": "int",
        "issues_90d": "int",
        "open_issues_30d": "int",
        "days_since_last_issue": "int",
        "avg_cpu_usage_30d": "double",
        "z_issues_7d": "double",
        "z_issues_30d": "double",
        "z_issues_90d": "double",
        "z_open_issues_30d": "double",
        "z_days_since_last_issue": "double",
        "z_avg_cpu_usage_30d": "double",
        "poly_issues_7d": "double",
        "poly_open_issues_30d": "double",
        "poly_days_since_last_issue": "double",
        "poly_issues_7d_pow2": "double",
        "poly_issues_7d_x_open_issues_30d": "double",
        "poly_issues_7d_x_days_since_last_issue": "double",
        "poly_open_issues_30d_pow2": "double",
        "poly_open_issues_30d_x_days_since_last_issue": "double",
        "poly_days_since_last_issue_pow2": "double",
        "enc_device_category": "int",
        "enc_manufacturer": "int",
        "risk_score": "double",
        "model_version": "string",
    },
    kind=dict(name=ModelKindName.FULL),
    grains=["snapshot_date", "device_id"],
    depends_on=["s3depot.device_meb.issues", "s3depot.device_meb.devices"],
    cron="@daily",
    tags=["ml", "feature_engineering", "sklearn", "device_issues"],
    description="Feature-engineered device issue table using scikit-learn preprocessing transforms.",
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> t.Iterator[pd.DataFrame]:
    """Create reusable ML features from issue activity using scikit-learn."""

    query = """
    SELECT
        COALESCE(i.device_id, d.id, d.device_id) AS device_id,
        d.device_category,
        d.manufacturer,
        i.reported_at,
        i.status,
        i.avg_cpu_usage
    FROM s3depot.device_meb.issues i
    LEFT JOIN s3depot.device_meb.devices d
      ON i.device_id = d.id OR i.device_id = d.device_id
    WHERE i.reported_at IS NOT NULL
      AND COALESCE(i.device_id, d.id, d.device_id) IS NOT NULL
    """
    df = context.fetchdf(query)

    if df.empty:
        yield from ()
        return

    df["reported_at"] = pd.to_datetime(df["reported_at"], errors="coerce")
    df = df.dropna(subset=["reported_at", "device_id"]).copy()
    if df.empty:
        yield from ()
        return

    df["status"] = df["status"].astype(str).str.lower()
    df["avg_cpu_usage"] = pd.to_numeric(df["avg_cpu_usage"], errors="coerce").fillna(0.0)
    df["device_category"] = df["device_category"].fillna("Unknown")
    df["manufacturer"] = df["manufacturer"].fillna("Unknown")

    snapshot_date = pd.Timestamp(execution_time.date())
    windows = {"7d": 7, "30d": 30, "90d": 90}

    rows: t.List[t.Dict[str, t.Any]] = []
    for device_id, group in df.groupby("device_id", dropna=False):
        row: t.Dict[str, t.Any] = {
            "snapshot_date": snapshot_date,
            "device_id": str(device_id),
            "device_category": str(group["device_category"].iloc[-1]),
            "manufacturer": str(group["manufacturer"].iloc[-1]),
        }

        for label, days in windows.items():
            cutoff = snapshot_date - timedelta(days=days)
            recent = group[group["reported_at"] >= cutoff]
            row[f"issues_{label}"] = int(len(recent))
            if label == "30d":
                row["open_issues_30d"] = int(recent["status"].isin(["open", "new", "in_progress"]).sum())
                row["avg_cpu_usage_30d"] = float(recent["avg_cpu_usage"].mean()) if len(recent) else 0.0

        last_issue = group["reported_at"].max()
        row["days_since_last_issue"] = int(max((snapshot_date - last_issue).days, 0))
        rows.append(row)

    feature_df = pd.DataFrame(rows)
    if feature_df.empty:
        yield from ()
        return

    numeric_cols = [
        "issues_7d",
        "issues_30d",
        "issues_90d",
        "open_issues_30d",
        "days_since_last_issue",
        "avg_cpu_usage_30d",
    ]

    scaler = StandardScaler()
    scaled = scaler.fit_transform(feature_df[numeric_cols])
    scaled_df = pd.DataFrame(scaled, columns=[f"z_{c}" for c in numeric_cols], index=feature_df.index)

    poly_input_cols = ["issues_7d", "open_issues_30d", "days_since_last_issue"]
    poly = PolynomialFeatures(degree=2, include_bias=False)
    poly_values = poly.fit_transform(feature_df[poly_input_cols])
    poly_df = pd.DataFrame(
        poly_values,
        columns=[
            "poly_issues_7d",
            "poly_open_issues_30d",
            "poly_days_since_last_issue",
            "poly_issues_7d_pow2",
            "poly_issues_7d_x_open_issues_30d",
            "poly_issues_7d_x_days_since_last_issue",
            "poly_open_issues_30d_pow2",
            "poly_open_issues_30d_x_days_since_last_issue",
            "poly_days_since_last_issue_pow2",
        ],
        index=feature_df.index,
    )

    encoder = OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1)
    encoded = encoder.fit_transform(feature_df[["device_category", "manufacturer"]])
    encoded_df = pd.DataFrame(
        encoded,
        columns=["enc_device_category", "enc_manufacturer"],
        index=feature_df.index,
    ).astype("int64")

    result_df = pd.concat([feature_df, scaled_df, poly_df, encoded_df], axis=1)

    risk_raw = (
        0.5 * result_df["issues_7d"].astype(float)
        + 0.3 * result_df["open_issues_30d"].astype(float)
        + 0.2 * np.maximum(30.0 - result_df["days_since_last_issue"].astype(float), 0.0) / 30.0
    )
    denom = float(risk_raw.max()) if float(risk_raw.max()) > 0 else 1.0
    result_df["risk_score"] = (risk_raw / denom).clip(0.0, 1.0).round(6)
    result_df["model_version"] = "v1.0-sklearn-fe"

    ordered_columns = [
        "snapshot_date",
        "device_id",
        "device_category",
        "manufacturer",
        "issues_7d",
        "issues_30d",
        "issues_90d",
        "open_issues_30d",
        "days_since_last_issue",
        "avg_cpu_usage_30d",
        "z_issues_7d",
        "z_issues_30d",
        "z_issues_90d",
        "z_open_issues_30d",
        "z_days_since_last_issue",
        "z_avg_cpu_usage_30d",
        "poly_issues_7d",
        "poly_open_issues_30d",
        "poly_days_since_last_issue",
        "poly_issues_7d_pow2",
        "poly_issues_7d_x_open_issues_30d",
        "poly_issues_7d_x_days_since_last_issue",
        "poly_open_issues_30d_pow2",
        "poly_open_issues_30d_x_days_since_last_issue",
        "poly_days_since_last_issue_pow2",
        "enc_device_category",
        "enc_manufacturer",
        "risk_score",
        "model_version",
    ]
    result_df = result_df[ordered_columns]

    for col in ("issues_7d", "issues_30d", "issues_90d", "open_issues_30d", "days_since_last_issue"):
        result_df[col] = result_df[col].astype("int64")
    result_df["avg_cpu_usage_30d"] = result_df["avg_cpu_usage_30d"].astype("float64")
    result_df = result_df.sort_values(by="device_id", kind="stable")

    yield result_df
