MODEL (
  name s3depot.device_08.system_update_devices,
  grain uuid,
  kind FULL,
  description 'System Update Devices with exploded package details, CDC merge logic, and blocked device flagging',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    uuid STRING,
    org_id STRING,
    id STRING,
    _class STRING,
    device_id STRING,
    device_display_name STRING,
    device_serial_number STRING,
    device_product_name STRING,
    created_at TIMESTAMP,
    package_id STRING,
    installation_status STRING,
    last_modified_date TIMESTAMP,
    package_severity STRING,
    filtering_group_name STRING,
    is_blocked BOOLEAN
  ),
  column_descriptions (
    uuid = 'Unique device-package record identifier and model grain.',
    org_id = 'Organization identifier for the update deployment.',
    id = 'Source system update device record identifier.',
    _class = 'Document class from the source system.',
    device_id = 'Business device identifier receiving the update.',
    device_display_name = 'Display name of the target device.',
    device_serial_number = 'Serial number of the target device.',
    device_product_name = 'Product name of the target device.',
    created_at = 'Timestamp when the update device record was created.',
    package_id = 'Update package identifier deployed to the device.',
    installation_status = 'Current installation status on the device (DEPLOYED, FAILED, PENDING, etc.).',
    last_modified_date = 'Timestamp when the package installation status was last modified.',
    package_severity = 'Severity level of the update package (CRITICAL, RECOMMENDED, OPTIONAL).',
    filtering_group_name = 'Filtering group name applied to the package deployment.',
    is_blocked = 'Flag indicating whether the device has a blocked update in progress.'
  ),
  column_tags (
    uuid = ('identifier', 'primary_key', 'grain', 'system-update'),
    org_id = ('identifier', 'organization', 'system-update'),
    id = ('identifier', 'system-update', 'source-id'),
    _class = ('metadata', 'system-update', 'class'),
    device_id = ('identifier', 'device', 'system-update'),
    device_display_name = ('dimension', 'device', 'display-name'),
    device_serial_number = ('identifier', 'device', 'serial-number'),
    device_product_name = ('dimension', 'device', 'product-name'),
    created_at = ('timestamp', 'system-update', 'created_at'),
    package_id = ('identifier', 'system-update', 'package'),
    installation_status = ('status', 'system-update', 'deployment'),
    last_modified_date = ('timestamp', 'system-update', 'updated_at'),
    package_severity = ('classification', 'system-update', 'severity'),
    filtering_group_name = ('dimension', 'system-update', 'filtering-group'),
    is_blocked = ('indicator', 'system-update', 'blocked')
  ),
  column_terms (
    uuid = ('system_update_devices.record_id', 'identity.primary_key'),
    org_id = ('system_update_devices.organization_id', 'organization.identifier'),
    id = ('system_update_devices.id', 'system_update.source_id'),
    _class = ('system_update_devices._class', 'system_update.document_class'),
    device_id = ('system_update_devices.device_id', 'device.identifier'),
    device_display_name = ('system_update_devices.device_display_name', 'device.display_name'),
    device_serial_number = ('system_update_devices.device_serial_number', 'identity.serial_number'),
    device_product_name = ('system_update_devices.device_product_name', 'device.product_name'),
    created_at = ('system_update_devices.created_at', 'record.created_at'),
    package_id = ('system_update_devices.package_id', 'patch.package_id'),
    installation_status = ('system_update_devices.installation_status', 'patch.deployment_status'),
    last_modified_date = ('system_update_devices.last_modified_date', 'record.updated_at'),
    package_severity = ('system_update_devices.package_severity', 'patch.severity_level'),
    filtering_group_name = ('system_update_devices.filtering_group_name', 'patch.filtering_group'),
    is_blocked = ('system_update_devices.is_blocked', 'patch.blocked_flag')
  ),
  profiles (
    uuid,
    org_id,
    id,
    _class,
    device_id,
    device_display_name,
    device_serial_number,
    device_product_name,
    created_at,
    package_id,
    installation_status,
    last_modified_date,
    package_severity,
    filtering_group_name,
    is_blocked
  )
);

WITH cleaned_cdc_data AS (
  SELECT
    CAST(NULL AS STRING) AS _class,
    _id AS id,
    org_id,
    device_id,
    device_display_name,
    device_serial_number,
    device_product_name,
    to_timestamp(from_unixtime(CAST(created_at AS BIGINT) / 100000)) AS created_at,
    to_timestamp(from_unixtime(CAST(last_modified_date AS BIGINT) / 100000)) AS last_modified_date,
    TRANSFORM(
      from_json(
        package_details,
        'ARRAY<STRUCT<packageId: STRING, installationStatus: STRING, lastModifiedDate: STRING, packageSeverity: STRING, filteringGroupName: STRING>>'
      ),
      x -> named_struct(
        "package_id",           x.packageId,
        "installation_status",  x.installationStatus,
        "last_modified_date",   x.lastModifiedDate,
        "package_severity",     x.packageSeverity,
        "filtering_group_name", x.filteringGroupName
      )
    ) AS package_details
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY _id
        ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
      ) AS rn
    FROM s3depot.demolake04.system_update_devices
  )
  WHERE rn = 1
),

explode_package_details AS (
  SELECT
    org_id,
    id,
    _class,
    device_id,
    device_display_name,
    device_serial_number,
    device_product_name,
    created_at,
    explode(package_details) AS package_details_
  FROM cleaned_cdc_data
),

temp_final AS (
  SELECT
    org_id,
    id,
    _class,
    device_id,
    device_display_name,
    device_serial_number,
    device_product_name,
    CAST(created_at AS TIMESTAMP) AS created_at,
    package_details_.package_id,
    package_details_.installation_status,
    CAST(package_details_.last_modified_date AS TIMESTAMP) AS last_modified_date,
    package_details_.package_severity,
    package_details_.filtering_group_name
  FROM explode_package_details
),

unique_records AS (
  SELECT
    CONCAT(id, '_', package_id) AS uuid,
    *
  FROM temp_final
),

pre_final AS (
  SELECT
    uuid, org_id, id, _class, device_id, device_display_name, device_serial_number,
    device_product_name,
    CAST(created_at AS TIMESTAMP)      AS created_at,
    package_id,
    installation_status,
    CAST(last_modified_date AS TIMESTAMP) AS last_modified_date,
    package_severity,
    filtering_group_name
  FROM unique_records
),

devices_blocked AS (
  SELECT DISTINCT
    device_id
  FROM pre_final
  WHERE installation_status IN ('REBOOT_REQUIRED', 'INSTALLATION_DEFERRED', 'WAITING_ACKNOWLEDGMENT', 'PENDING', 'INSTALLING')
)

SELECT
  t.*,
  CASE
    WHEN r.device_id IS NULL THEN FALSE
    ELSE TRUE
  END AS is_blocked
FROM pre_final t
LEFT JOIN devices_blocked r
  ON t.device_id = r.device_id
