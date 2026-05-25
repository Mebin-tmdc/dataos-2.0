MODEL (
  name s3depot.device_08.system_update_testing, 
  grain _id,
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for system update testing',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    _id STRING,
    end_date TIMESTAMP,
    org_id STRING,
    device_ids STRING,
    package_description STRING,
    package_id STRING,
    package_name STRING,
    package_reboot_type STRING,
    package_release_date TIMESTAMP,    
    package_severity STRING,
    package_type STRING,
    readme_url STRING,   
    start_date TIMESTAMP,
    tested_version STRING,
    testing_group_name STRING,
    test_state STRING,
    test_state_last_updated_at TIMESTAMP
  ),
  column_descriptions (
    _id = 'Unique system update testing record identifier and model grain.',
    end_date = 'Timestamp when the testing window ends.',
    org_id = 'Organization identifier for the testing configuration.',
    device_ids = 'Array of device identifiers included in the test group.',
    package_description = 'Description of the update package under test.',
    package_id = 'Update package identifier under test.',
    package_name = 'Display name of the update package under test.',
    package_reboot_type = 'Reboot behavior required for the package (NoRebootRequired, RequiresReboot, etc.).',
    package_release_date = 'Timestamp when the package was released.',
    package_severity = 'Severity level of the update package (CRITICAL, RECOMMENDED, OPTIONAL).',
    package_type = 'Type of update package (Driver, Firmware, Application, etc.).',
    readme_url = 'URL to the package readme documentation.',
    start_date = 'Timestamp when the testing window starts.',
    tested_version = 'Version of the package being tested.',
    testing_group_name = 'Name of the testing group.',
    test_state = 'Current state of the testing process for this update package.',
    test_state_last_updated_at = 'Timestamp when the test state was last updated.'
  ),
  column_tags (
    _id = ('identifier', 'primary_key', 'grain', 'system-update'),
    end_date = ('timestamp', 'system-update', 'end'),
    org_id = ('identifier', 'organization', 'system-update'),
    device_ids = ('identifier', 'device', 'test-group'),
    package_description = ('dimension', 'system-update', 'description'),
    package_id = ('identifier', 'system-update', 'package'),
    package_name = ('dimension', 'system-update', 'package-name'),
    package_reboot_type = ('classification', 'system-update', 'reboot'),
    package_release_date = ('timestamp', 'system-update', 'release-date'),
    package_severity = ('classification', 'system-update', 'severity'),
    package_type = ('classification', 'system-update', 'type'),
    readme_url = ('identifier', 'system-update', 'readme'),
    start_date = ('timestamp', 'system-update', 'start'),
    tested_version = ('dimension', 'system-update', 'version'),
    testing_group_name = ('dimension', 'system-update', 'test-group'),
    test_state = ('status', 'system-update', 'testing'),
    test_state_last_updated_at = ('timestamp', 'system-update', 'test-updated')
  ),
  column_terms (
    _id = ('system_update_testing.record_id', 'identity.primary_key'),
    end_date = ('system_update_testing.end_date', 'patch.test_end'),
    org_id = ('system_update_testing.organization_id', 'organization.identifier'),
    device_ids = ('system_update_testing.device_ids', 'patch.test_devices'),
    package_description = ('system_update_testing.package_description', 'patch.description'),
    package_id = ('system_update_testing.package_id', 'patch.package_id'),
    package_name = ('system_update_testing.package_name', 'patch.package_name'),
    package_reboot_type = ('system_update_testing.package_reboot_type', 'patch.reboot_requirement'),
    package_release_date = ('system_update_testing.package_release_date', 'patch.release_date'),
    package_severity = ('system_update_testing.package_severity', 'patch.severity_level'),
    package_type = ('system_update_testing.package_type', 'patch.update_type'),
    readme_url = ('system_update_testing.readme_url', 'patch.readme_url'),
    start_date = ('system_update_testing.start_date', 'patch.test_start'),
    tested_version = ('system_update_testing.tested_version', 'patch.tested_version'),
    testing_group_name = ('system_update_testing.testing_group_name', 'patch.testing_group'),
    test_state = ('system_update_testing.test_state', 'patch.testing_status'),
    test_state_last_updated_at = ('system_update_testing.test_state_last_updated_at', 'patch.test_state_updated')
  ),
  profiles (
    _id,
    end_date,
    org_id,
    device_ids,
    package_description,
    package_id,
    package_name,
    package_reboot_type,
    package_release_date,
    package_severity,
    package_type,
    readme_url,
    start_date,
    tested_version,
    testing_group_name,
    test_state,
    test_state_last_updated_at
  )
);


-- CREATE OR REPLACE TEMP VIEW _temp_view_consumed_licenses_cdc
-- USING json
-- OPTIONS (
--   'path' 's3a://warehouse/lenovo/01-14-2026-14-32-42_files_list/consumed_licenses_cdc.json',
--   'multiline' 'true'
-- );


-- CREATE OR REPLACE TEMP VIEW _temp_view_consumed_licenses_full
-- USING json
-- OPTIONS (
--   'path' 's3a://warehouse/lenovo/01-14-2026-14-32-42_files_list/consumed_licenses_full.json',
--   'multiline' 'true'
-- );

SELECT
    _id,
    split(
        regexp_replace(device_ids, '\\[|\\]|"', ''),
        ',\\s*'
    ) AS device_ids,
    cast(end_date as timestamp) as end_date,
    org_id,
    package_description,
    package_id,
    package_name,
    package_reboot_type,
    cast(package_release_date as timestamp) as package_release_date,
    package_severity,
    package_type,
    readme_url,
    cast(start_date as timestamp) as start_date,
    tested_version,
    testing_group_name,
    test_state,
    cast(test_state_last_updated_at as timestamp) as test_state_last_updated_at
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY _id
            ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
        ) AS rn
    FROM s3depot.demolake04.system_update_testing
)
WHERE rn = 1
