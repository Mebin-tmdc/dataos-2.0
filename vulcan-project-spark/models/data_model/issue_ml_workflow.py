import typing as t
from datetime import datetime

import pandas as pd
from vulcan import ExecutionContext, ModelKindName, model


@model(
    "s3depot.device_meb.device_issue_ml_workflow1",
    columns={
        "snapshot_date": "timestamp",
        "device_id": "string",
        "risk_score": "double",
        "risk_cluster": "int",
        "engine_used": "string",
        "spark_mllib_status": "string",
        "model_version": "string",
    },
    kind=dict(name=ModelKindName.FULL),
    grains=["snapshot_date", "device_id"],
    depends_on=["s3depot.device_meb.device_issue_features1"],
    cron="@daily",
    tags=["ml", "workflow", "spark-ml", "sklearn-fallback"],
    description="Simple ML workflow over engineered issue features using Spark ML KMeans with sklearn fallback.",
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> t.Iterator[pd.DataFrame]:
    query = """
    SELECT
      snapshot_date,
      device_id,
      CAST(issues_7d AS DOUBLE) AS issues_7d,
      CAST(open_issues_30d AS DOUBLE) AS open_issues_30d,
      CAST(days_since_last_issue AS DOUBLE) AS days_since_last_issue,
      CAST(risk_score AS DOUBLE) AS risk_score
    FROM s3depot.device_meb.device_issue_features
    """
    base_df = context.fetchdf(query)

    if base_df.empty:
        yield from ()
        return

    base_df["snapshot_date"] = pd.to_datetime(base_df["snapshot_date"], errors="coerce")
    base_df = base_df.dropna(subset=["snapshot_date", "device_id"]).copy()
    if base_df.empty:
        yield from ()
        return

    feature_cols = ["issues_7d", "open_issues_30d", "days_since_last_issue"]
    base_df[feature_cols] = base_df[feature_cols].fillna(0.0)
    base_df["risk_score"] = base_df["risk_score"].fillna(0.0)

    result = _run_spark_kmeans_if_available(context, base_df, feature_cols)
    if result is None:
        result = _run_sklearn_kmeans(base_df, feature_cols)

    result["model_version"] = "v1.0-issue-ml-workflow"
    result["risk_cluster"] = result["risk_cluster"].astype("int64")
    result["risk_score"] = result["risk_score"].astype("float64")
    result = result.sort_values(by="device_id", kind="stable")

    yield result[
        [
            "snapshot_date",
            "device_id",
            "risk_score",
            "risk_cluster",
            "engine_used",
            "spark_mllib_status",
            "model_version",
        ]
    ]


def _run_spark_kmeans_if_available(
    context: ExecutionContext,
    base_df: pd.DataFrame,
    feature_cols: t.List[str],
) -> t.Optional[pd.DataFrame]:
    spark = getattr(context, "spark", None)
    if spark is None:
        return None

    try:
        from pyspark.ml.clustering import KMeans as SparkKMeans
        from pyspark.ml.feature import VectorAssembler
    except Exception:
        return None

    try:
        spark_df = spark.createDataFrame(base_df[["snapshot_date", "device_id", "risk_score"] + feature_cols])
        assembler = VectorAssembler(inputCols=feature_cols, outputCol="features")
        train_df = assembler.transform(spark_df).select("snapshot_date", "device_id", "risk_score", "features")

        row_count = train_df.count()
        if row_count == 0:
            return None
        k = int(min(3, row_count))
        if k < 1:
            return None

        kmeans = SparkKMeans(k=k, seed=42, featuresCol="features", predictionCol="risk_cluster")
        fitted = kmeans.fit(train_df)
        pred_df = fitted.transform(train_df).select(
            "snapshot_date",
            "device_id",
            "risk_score",
            "risk_cluster",
        )
        out = pred_df.toPandas()
        out["risk_cluster"] = out["risk_cluster"].astype("int64")
        out["engine_used"] = "spark_ml_kmeans"
        out["spark_mllib_status"] = _spark_mllib_status(spark)
        return out
    except Exception:
        return None


def _spark_mllib_status(spark: t.Any) -> str:
    try:
        _ = spark.sparkContext._jvm.org.apache.spark.mllib.linalg.Vectors.dense([1.0, 2.0, 3.0])
        return "mllib_class_available"
    except Exception:
        return "mllib_class_not_available"


def _run_sklearn_kmeans(base_df: pd.DataFrame, feature_cols: t.List[str]) -> pd.DataFrame:
    row_count = len(base_df)
    if row_count < 2:
        fallback = base_df[["snapshot_date", "device_id", "risk_score"]].copy()
        fallback["risk_cluster"] = 0
        fallback["engine_used"] = "sklearn_fallback_single_cluster"
        fallback["spark_mllib_status"] = "spark_not_used"
        return fallback

    try:
        from sklearn.cluster import KMeans as SklearnKMeans
    except Exception:
        fallback = base_df[["snapshot_date", "device_id", "risk_score"]].copy()
        fallback["risk_cluster"] = 0
        fallback["engine_used"] = "basic_fallback_no_sklearn"
        fallback["spark_mllib_status"] = "spark_not_used"
        return fallback

    k = int(min(3, row_count))
    model = SklearnKMeans(n_clusters=k, random_state=42, n_init=10)
    labels = model.fit_predict(base_df[feature_cols].to_numpy())

    out = base_df[["snapshot_date", "device_id", "risk_score"]].copy()
    out["risk_cluster"] = labels.astype("int64")
    out["engine_used"] = "sklearn_kmeans"
    out["spark_mllib_status"] = "spark_not_used"
    return out
