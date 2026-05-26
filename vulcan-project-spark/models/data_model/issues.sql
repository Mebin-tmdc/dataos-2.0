MODEL (
  name s3depot.device_meb.issues,
  grain issue_uuid,
  cron '*/5 * * * *',
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for devices',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    issue_uuid STRING,
    bucket_id STRING,
    category STRING,
    hardware_id STRING,
    reported_at TIMESTAMP,
    resolved_at TIMESTAMP,
    status STRING,
    timeline STRING,
    updated_at TIMESTAMP,
    value STRING,
    device_id STRING,
    insight_id STRING,
    generate_ticket BOOLEAN,
    has_ticket BOOLEAN,
    is_hidden BOOLEAN,
    insight_item_id STRING,
    _nilus_load_id TIMESTAMP,
    _nilus_id STRING,
    battery_id STRING,
    predicted_to_occur_on TIMESTAMP,
    code STRING,
    s_id STRING,
    details STRING,
    avg_cpu_usage DOUBLE PRECISION
  ),
  column_descriptions (
    issue_uuid = 'Unique issue record identifier and model grain.',
    bucket_id = 'Bucket identifier grouping related issues.',
    category = 'Issue category classification from the source system.',
    hardware_id = 'Hardware component identifier associated with the issue.',
    reported_at = 'Timestamp when the issue was first reported.',
    resolved_at = 'Timestamp when the issue was resolved, if applicable.',
    status = 'Current lifecycle status of the issue (open, resolved, etc.).',
    timeline = 'Serialized timeline of issue state transitions.',
    updated_at = 'Timestamp when the issue record was last updated.',
    value = 'Raw metric or diagnostic value associated with the issue.',
    device_id = 'Business device identifier associated with the issue.',
    insight_id = 'Insight rule identifier that generated the issue.',
    generate_ticket = 'Flag indicating whether a support ticket should be generated.',
    has_ticket = 'Flag indicating whether a support ticket exists for the issue.',
    is_hidden = 'Flag indicating whether the issue is hidden from default views.',
    insight_item_id = 'Identifier of the specific insight item within the rule.',
    _nilus_load_id = 'Ingestion load identifier assigned by Nilus.',
    _nilus_id = 'Ingestion record identifier assigned by Nilus.',
    battery_id = 'Battery identifier when the issue is battery-related.',
    predicted_to_occur_on = 'Timestamp when the issue is predicted to occur.',
    code = 'Issue diagnostic code from the source system.',
    s_id = 'Secondary source identifier for the issue.',
    details = 'Free-text details describing the issue.',
    avg_cpu_usage = 'Average CPU usage derived for app performance impact insights.'
  ),
  column_tags (
    issue_uuid = ('identifier', 'primary_key', 'grain', 'issues'),
    bucket_id = ('identifier', 'issues', 'bucket'),
    category = ('classification', 'issues', 'category'),
    hardware_id = ('identifier', 'issues', 'hardware'),
    reported_at = ('timestamp', 'issues', 'reported_at'),
    resolved_at = ('timestamp', 'issues', 'resolved_at'),
    status = ('status', 'issues', 'lifecycle'),
    timeline = ('dimension', 'issues', 'timeline'),
    updated_at = ('timestamp', 'issues', 'updated_at'),
    value = ('measure', 'issues', 'value'),
    device_id = ('identifier', 'device', 'issues'),
    insight_id = ('identifier', 'issues', 'insight'),
    generate_ticket = ('indicator', 'issues', 'ticket'),
    has_ticket = ('indicator', 'issues', 'ticket'),
    is_hidden = ('indicator', 'issues', 'visibility'),
    insight_item_id = ('identifier', 'issues', 'insight-item'),
    _nilus_load_id = ('metadata', 'ingestion', 'load_id'),
    _nilus_id = ('metadata', 'ingestion', 'record_id'),
    battery_id = ('identifier', 'battery', 'issues'),
    predicted_to_occur_on = ('timestamp', 'issues', 'prediction'),
    code = ('identifier', 'issues', 'code'),
    s_id = ('identifier', 'issues', 'source-id'),
    details = ('dimension', 'issues', 'details'),
    avg_cpu_usage = ('measure', 'issues', 'cpu-usage')
  ),
  column_terms (
    issue_uuid = ('issues.record_id', 'identity.primary_key'),
    bucket_id = ('issues.bucket_id', 'issue.bucket_id'),
    category = ('issues.category', 'issue.category'),
    hardware_id = ('issues.hardware_id', 'issue.hardware_id'),
    reported_at = ('issues.reported_at', 'issue.reported_at'),
    resolved_at = ('issues.resolved_at', 'issue.resolved_at'),
    status = ('issues.status', 'health.issue_state'),
    timeline = ('issues.timeline', 'issue.timeline'),
    updated_at = ('issues.updated_at', 'record.updated_at'),
    value = ('issues.value', 'issue.value'),
    device_id = ('issues.device_id', 'device.identifier'),
    insight_id = ('issues.insight_id', 'issue.insight_id'),
    generate_ticket = ('issues.generate_ticket', 'issue.generate_ticket'),
    has_ticket = ('issues.has_ticket', 'issue.has_ticket'),
    is_hidden = ('issues.is_hidden', 'issue.hidden'),
    insight_item_id = ('issues.insight_item_id', 'issue.insight_item_id'),
    _nilus_load_id = ('issues.load_id', 'ingestion.load_id'),
    _nilus_id = ('issues.nilus_id', 'ingestion.record_id'),
    battery_id = ('issues.battery_id', 'battery.identifier'),
    predicted_to_occur_on = ('issues.predicted_to_occur_on', 'issue.predicted_date'),
    code = ('issues.code', 'issue.code'),
    s_id = ('issues.s_id', 'issue.source_id'),
    details = ('issues.details', 'issue.details'),
    avg_cpu_usage = ('issues.avg_cpu_usage', 'issue.cpu_usage')
  )
);


-- CREATE OR REPLACE TEMP VIEW _temp_view_device_warranty_cdc
-- USING json
-- OPTIONS (
--   'path' 's3a://warehouse/lenovo/01-14-2026-14-32-42_files_list/device_warranty_cdc.json',
--   'multiline' 'true'
-- );


-- CREATE OR REPLACE TEMP VIEW _temp_view_device_warranty_full
-- USING json
-- OPTIONS (
--   'path' 's3a://warehouse/lenovo/01-14-2026-14-32-42_files_list/device_warranty_full.json',
--   'multiline' 'true'
-- );

SELECT
  uuid as issue_uuid,
  bucket_id,
  category,
  hardware_id,
  CAST(from_unixtime(CAST(reported_at AS BIGINT) / 1000000) AS TIMESTAMP) as reported_at,
  CAST(from_unixtime(CAST(resolved_at AS BIGINT) / 1000000) AS TIMESTAMP) as resolved_at,
  status,
  timeline,
  CAST(from_unixtime(CAST(updated_at AS BIGINT) / 1000000) AS TIMESTAMP) as updated_at,
  value,
  d_id as device_id,
  insight_id,
  generate_ticket,
  has_ticket,
  hidden as is_hidden,
  insight_item_id,
  to_timestamp(from_unixtime(CAST(_nilus_load_id AS DOUBLE))) AS _nilus_load_id,
  _nilus_id,
  b_id as battery_id,
  CAST(from_unixtime(CAST(predicted_to_occur_on AS BIGINT) / 1000000) AS TIMESTAMP) as predicted_to_occur_on,
  code,
  s_id,
  details,
  CASE WHEN insight_id = 'app_performance_impact' THEN CAST(NULLIF(value, '') AS DOUBLE PRECISION) ELSE NULL END as avg_cpu_usage
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY uuid
            ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
        ) AS rn
    FROM s3depot.demolake04.issues
)
WHERE rn = 1;
