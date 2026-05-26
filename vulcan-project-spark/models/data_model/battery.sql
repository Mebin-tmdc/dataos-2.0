MODEL (
  name s3depot.device_pari.battery,
  grain battery_id,
  cron '*/5 * * * *',
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for battery',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    battery_id STRING,
    device_id STRING,
    battery_condition STRING,
    battery_cycle_count STRING,
    battery_design_capacity STRING,
    battery_firstused_date STRING,
    battery_fullcharge_capacity STRING,
    battery_manufacture_date STRING,
    battery_manufacture_name STRING,
    battery_remaining_capacity STRING,
    battery_serial_number STRING,
    battery_warranty_date STRING,
    battery_warranty_status STRING,
    _nilus_load_id TIMESTAMP,
    _nilus_id STRING
  ),
  column_descriptions (
    battery_id = 'Unique battery record identifier and model grain.',
    device_id = 'Business device identifier associated with the battery.',
    battery_condition = 'Condition of the battery.',
    battery_cycle_count = 'Cycle count of the battery.',
    battery_design_capacity = 'Design capacity of the battery.',
    battery_firstused_date = 'First used date of the battery.',
    battery_fullcharge_capacity = 'Full charge capacity of the battery.',
    battery_manufacture_date = 'Manufacture date of the battery.',
    battery_manufacture_name = 'Manufacture name of the battery.',
    battery_remaining_capacity = 'Remaining capacity of the battery.',
    battery_serial_number = 'Serial number of the battery.',
    battery_warranty_date = 'Warranty date of the battery.',
    battery_warranty_status = 'Warranty status of the battery.',
    _nilus_load_id = 'Ingestion load identifier assigned by Nilus.',
    _nilus_id = 'Ingestion record identifier assigned by Nilus.'
  ),
  column_tags (
    battery_id = ['dimension', 'battery'],
    device_id = ['dimension', 'device'],
    battery_condition = ['dimension', 'battery'],
    battery_cycle_count = ['dimension', 'battery'],
    battery_design_capacity = ['dimension', 'battery'],
    battery_firstused_date = ['dimension', 'battery'],
    battery_fullcharge_capacity = ['dimension', 'battery'],
    battery_manufacture_date = ['dimension', 'battery'],
    battery_manufacture_name = ['dimension', 'battery'],
    battery_remaining_capacity = ['dimension', 'battery'],
    battery_serial_number = ['dimension', 'battery'],
    battery_warranty_date = ['dimension', 'battery'],
    battery_warranty_status = ['dimension', 'battery'],
    _nilus_load_id = ['metadata', 'ingestion', 'load_id'],
    _nilus_id = ['metadata', 'ingestion', 'record_id']
  ),
);

SELECT
  *
FROM s3depot.device_pari.battery