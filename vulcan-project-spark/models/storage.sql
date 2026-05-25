MODEL (
  name s3depot.device_08.storage,
  grain storage_id,
  cron '*/5 * * * *',
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for storage',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    storage_id STRING,
    device_id STRING,
    storage_condition STRING,
    storage_firmware_revision STRING,
    storage_free_space STRING,
    storage_interface_type STRING,
    storage_model STRING,
    storage_size STRING,
    storage_type STRING,
    storage_used_percentage STRING,
    storage_created_at TIMESTAMP,
    storage_disk_spec STRING,
    storage_health_status STRING,
    _nilus_load_id TIMESTAMP,
    _nilus_id STRING,
    storage_space_status STRING
  ),
  column_descriptions (
    storage_id = 'Unique storage record identifier and model grain.',
    device_id = 'Business device identifier associated with the storage device.',
    storage_condition = 'Health condition of the storage device (good, degraded, failing, etc.).',
    storage_firmware_revision = 'Firmware revision of the storage device.',
    storage_free_space = 'Reported free space on the storage device.',
    storage_interface_type = 'Interface type of the storage device (SATA, NVMe, etc.).',
    storage_model = 'Model name of the storage device.',
    storage_size = 'Total reported size of the storage device.',
    storage_type = 'Storage type classification (SSD, HDD, etc.).',
    storage_used_percentage = 'Percentage of storage capacity currently in use.',
    storage_created_at = 'Timestamp when the storage record was created.',
    storage_disk_spec = 'Disk specification details from the source system.',
    storage_health_status = 'Health status reported for the storage device.',
    _nilus_load_id = 'Ingestion load identifier assigned by Nilus.',
    _nilus_id = 'Ingestion record identifier assigned by Nilus.',
    storage_space_status = 'Derived space status bucket (Normal, Low Space, Almost Full).'
  ),
  column_tags (
    storage_id = ('identifier', 'primary_key', 'grain', 'storage'),
    device_id = ('identifier', 'device', 'storage'),
    storage_condition = ('status', 'storage', 'health'),
    storage_firmware_revision = ('dimension', 'storage', 'firmware'),
    storage_free_space = ('measure', 'storage', 'free-space'),
    storage_interface_type = ('classification', 'storage', 'interface'),
    storage_model = ('dimension', 'storage', 'model'),
    storage_size = ('measure', 'storage', 'size'),
    storage_type = ('classification', 'storage', 'type'),
    storage_used_percentage = ('measure', 'storage', 'used-percentage'),
    storage_created_at = ('timestamp', 'storage', 'created_at'),
    storage_disk_spec = ('dimension', 'storage', 'disk-spec'),
    storage_health_status = ('status', 'storage', 'health-status'),
    _nilus_load_id = ('metadata', 'ingestion', 'load_id'),
    _nilus_id = ('metadata', 'ingestion', 'record_id'),
    storage_space_status = ('classification', 'storage', 'space-status')
  ),
  column_terms (
    storage_id = ('storage.record_id', 'identity.primary_key'),
    device_id = ('storage.device_id', 'device.identifier'),
    storage_condition = ('storage.storage_condition', 'device_health.storage_state'),
    storage_firmware_revision = ('storage.storage_firmware_revision', 'storage.firmware'),
    storage_free_space = ('storage.storage_free_space', 'storage.free_space'),
    storage_interface_type = ('storage.storage_interface_type', 'storage.interface_type'),
    storage_model = ('storage.storage_model', 'storage.model'),
    storage_size = ('storage.storage_size', 'storage.size'),
    storage_type = ('storage.storage_type', 'storage.type'),
    storage_used_percentage = ('storage.storage_used_percentage', 'storage.used_percentage'),
    storage_created_at = ('storage.storage_created_at', 'record.created_at'),
    storage_disk_spec = ('storage.storage_disk_spec', 'storage.disk_spec'),
    storage_health_status = ('storage.storage_health_status', 'storage.health_status'),
    _nilus_load_id = ('storage.load_id', 'ingestion.load_id'),
    _nilus_id = ('storage.nilus_id', 'ingestion.record_id'),
    storage_space_status = ('storage.storage_space_status', 'storage.space_status')
  ),
  profiles (
    storage_id,
    device_id,
    storage_condition,
    storage_firmware_revision,
    storage_free_space,
    storage_interface_type,
    storage_model,
    storage_size,
    storage_type,
    storage_used_percentage,
    storage_created_at,
    storage_disk_spec,
    storage_health_status,
    _nilus_load_id,
    _nilus_id,
    storage_space_status
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
    storage_id,
    device_id,
    storage_condition,
    storage_firmware_revision,
    storage_free_space,
    storage_interface_type,
    storage_model,
    storage_size,
    storage_type,
    storage_used_percentage,
    to_timestamp(from_unixtime(cast(storage_created_at AS bigint) / 100000)) as storage_created_at,
    storage_disk_spec,
    storage_health_status,
    to_timestamp(from_unixtime(CAST(_nilus_load_id AS DOUBLE))) AS _nilus_load_id,
    _nilus_id,
    CASE 
        WHEN storage_used_percentage > 90 THEN 'Almost Full'
        WHEN storage_used_percentage > 80 THEN 'Low Space'
        ELSE 'Normal'
    END as storage_space_status
    
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY storage_id
            ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
        ) AS rn
    FROM s3depot.demolake04.storage
)
WHERE rn = 1;

