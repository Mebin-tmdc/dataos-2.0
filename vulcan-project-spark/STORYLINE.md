# Device Issue ML Storyline

## 1) User story

As a device operations lead, I want a daily risk score and risk segment for each device so that I can prioritize proactive maintenance, reduce repeat incidents, and focus engineers on the highest-risk fleet first.

## 2) Business storyline (plain language)

1. Device issues and device master records are combined into a single analytical view.
2. We compute behavior-based signals such as recent issue velocity, open issue pressure, and recency of last issue.
3. We transform those signals into ML-friendly features (scaled, polynomial, and encoded categorical features).
4. We create a normalized risk score (0 to 1) per device.
5. We run clustering on the risk-driving features to segment devices into risk clusters.
6. Ops and support teams use risk score + cluster to decide which devices should be inspected first.

## 3) Model-to-model flow

### Model 1: `s3depot.device_meb.device_issue_features`

Purpose: feature engineering model that builds reusable risk features from raw issue/device data.

Inputs:
- `s3depot.device_meb.issues`
- `s3depot.device_meb.devices`

Outputs:
- Windowed issue features (`issues_7d`, `issues_30d`, `issues_90d`)
- Operational stress features (`open_issues_30d`, `avg_cpu_usage_30d`)
- Recency feature (`days_since_last_issue`)
- ML transforms (z-score features, polynomial interaction features, encoded category features)
- `risk_score` (normalized 0-1)
- `model_version`

Notes:
- Uses `scikit-learn` transforms when available.
- Falls back to pandas/numpy logic so pipeline still runs even if sklearn wheel loading fails.

### Model 2: `s3depot.device_meb.device_issue_ml_workflow`

Purpose: ML workflow model that converts engineered features into actionable risk segments.

Input:
- `s3depot.device_meb.device_issue_features`

Outputs:
- `risk_score` (carried forward for ranking)
- `risk_cluster` (segment from clustering)
- `engine_used` (which ML engine executed)
- `spark_mllib_status` (whether JVM MLlib classes are available)
- `model_version`

Execution behavior:
- First tries Spark ML KMeans (`pyspark.ml`) when Spark session is available.
- If Spark path is unavailable/fails, falls back to sklearn KMeans.
- If sklearn is unavailable and data is very small, returns a deterministic single-cluster fallback.

## 4) Why both Python and Java dependencies are used

This project is Spark-first, but it intentionally supports resilient ML execution across runtime conditions:

- Python dependencies (`dependencies/python/*.whl`)
  - Needed for pandas/numpy/scikit-learn feature prep and fallback ML execution.
  - Downloaded as Linux-compatible wheels using:
    - `scripts/fetch_python_wheels.sh`
    - `scripts/fetch_test_dependencies.sh`
  - Important: wheels must target runtime Linux ABI (not local macOS wheels).

- Java dependencies (`dependencies/java/*.jar`)
  - Needed for Spark/JVM MLlib compatibility checks and classpath availability in cluster runtime.
  - `scripts/fetch_test_dependencies.sh` downloads `spark-mllib_2.12-<version>.jar`.
  - `deploy.yml` already includes classpath placeholders for these JARs:
    - `spark.driver.extraClassPath`
    - `spark.executor.extraClassPath`
  - Enable these when you need explicit JAR loading in your deployment environment.

## 5) Operational narrative you can present

"Every day, we transform raw device issue activity into standardized risk features. We score each device on near-term issue risk and then segment the fleet into clusters using ML. The workflow is resilient: it prefers distributed Spark ML for scale, but can safely fall back to sklearn if Spark MLlib is unavailable. Python wheels power feature engineering and fallback modeling, while Java JARs ensure Spark-side ML compatibility in production."

## 6) Suggested acceptance criteria

- Daily run publishes one row per `snapshot_date + device_id` in both models.
- `risk_score` is always present and bounded between 0 and 1.
- `risk_cluster` is present for all produced rows.
- `engine_used` and `spark_mllib_status` make runtime execution path observable.
- Pipeline still succeeds when either Spark ML path or sklearn path is unavailable (via designed fallbacks).
