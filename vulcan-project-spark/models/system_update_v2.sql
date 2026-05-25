MODEL (
  name s3depot.device_08.system_update_v2,
  grain _id,
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for system update report',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    _id STRING,
    org_id STRING,
    package_id STRING,
    coreq_package_id STRING,
    package_name STRING,
    package_description STRING,
    package_version STRING,
    current_installed_version STRING,
    package_release_date TIMESTAMP,
    package_vendor STRING,
    package_type STRING,
    package_severity STRING,
    package_reboot_type STRING,
    package_size STRING,
    disk_space_required STRING,
    package_tips STRING,
    readme_url STRING,
    license_url STRING,
    created_at TIMESTAMP,
    last_modified_date TIMESTAMP,
    test_state STRING,
    test_state_last_changed_by_user_at TIMESTAMP,
    category STRING,
    groups STRING
  ),
  column_descriptions (
    _id = 'Unique system update catalog record identifier and model grain.',
    org_id = 'Organization identifier for the update catalog entry.',
    package_id = 'Update package identifier in the catalog.',
    coreq_package_id = 'Co-requisite package identifier required with this update.',
    package_name = 'Display name of the update package.',
    package_description = 'Description of the update package.',
    package_version = 'Version of the update package.',
    current_installed_version = 'Version currently installed when reported.',
    package_release_date = 'Timestamp when the package was released.',
    package_vendor = 'Vendor that published the update package.',
    package_type = 'Type of update package (Driver, Firmware, Application, etc.).',
    package_severity = 'Severity level of the update (CRITICAL, RECOMMENDED, OPTIONAL).',
    package_reboot_type = 'Reboot behavior required (NoRebootRequired, RequiresReboot, etc.).',
    package_size = 'Reported size of the update package.',
    disk_space_required = 'Disk space required to install the package.',
    package_tips = 'Installation tips provided for the package.',
    readme_url = 'URL to the package readme documentation.',
    license_url = 'URL to the package license documentation.',
    created_at = 'Timestamp when the catalog record was created.',
    last_modified_date = 'Timestamp when the catalog record was last modified.',
    test_state = 'Current testing state for the package in the organization.',
    test_state_last_changed_by_user_at = 'Timestamp when a user last changed the test state.',
    category = 'Update category classification from the source system.',
    groups = 'Deployment groups associated with the update package.'
  ),
  column_tags (
    _id = ('identifier', 'primary_key', 'grain', 'system-update'),
    org_id = ('identifier', 'organization', 'system-update'),
    package_id = ('identifier', 'system-update', 'package'),
    coreq_package_id = ('identifier', 'system-update', 'corequisite'),
    package_name = ('dimension', 'system-update', 'package-name'),
    package_description = ('dimension', 'system-update', 'description'),
    package_version = ('dimension', 'system-update', 'version'),
    current_installed_version = ('dimension', 'system-update', 'installed-version'),
    package_release_date = ('timestamp', 'system-update', 'release-date'),
    package_vendor = ('dimension', 'system-update', 'vendor'),
    package_type = ('classification', 'system-update', 'type'),
    package_severity = ('classification', 'system-update', 'severity'),
    package_reboot_type = ('classification', 'system-update', 'reboot'),
    package_size = ('measure', 'system-update', 'size'),
    disk_space_required = ('measure', 'system-update', 'disk-space'),
    package_tips = ('dimension', 'system-update', 'tips'),
    readme_url = ('identifier', 'system-update', 'readme'),
    license_url = ('identifier', 'system-update', 'license'),
    created_at = ('timestamp', 'system-update', 'created_at'),
    last_modified_date = ('timestamp', 'system-update', 'updated_at'),
    test_state = ('status', 'system-update', 'testing'),
    test_state_last_changed_by_user_at = ('timestamp', 'system-update', 'test-changed'),
    category = ('classification', 'system-update', 'category'),
    groups = ('dimension', 'system-update', 'groups')
  ),
  column_terms (
    _id = ('system_update_v2.record_id', 'identity.primary_key'),
    org_id = ('system_update_v2.organization_id', 'organization.identifier'),
    package_id = ('system_update_v2.package_id', 'patch.package_id'),
    coreq_package_id = ('system_update_v2.coreq_package_id', 'patch.corequisite_id'),
    package_name = ('system_update_v2.package_name', 'patch.package_name'),
    package_description = ('system_update_v2.package_description', 'patch.description'),
    package_version = ('system_update_v2.package_version', 'patch.version'),
    current_installed_version = ('system_update_v2.current_installed_version', 'patch.installed_version'),
    package_release_date = ('system_update_v2.package_release_date', 'patch.release_date'),
    package_vendor = ('system_update_v2.package_vendor', 'patch.vendor'),
    package_type = ('system_update_v2.package_type', 'patch.update_type'),
    package_severity = ('system_update_v2.package_severity', 'patch.severity_level'),
    package_reboot_type = ('system_update_v2.package_reboot_type', 'patch.reboot_requirement'),
    package_size = ('system_update_v2.package_size', 'patch.size'),
    disk_space_required = ('system_update_v2.disk_space_required', 'patch.disk_space'),
    package_tips = ('system_update_v2.package_tips', 'patch.tips'),
    readme_url = ('system_update_v2.readme_url', 'patch.readme_url'),
    license_url = ('system_update_v2.license_url', 'patch.license_url'),
    created_at = ('system_update_v2.created_at', 'record.created_at'),
    last_modified_date = ('system_update_v2.last_modified_date', 'record.updated_at'),
    test_state = ('system_update_v2.test_state', 'patch.testing_status'),
    test_state_last_changed_by_user_at = ('system_update_v2.test_state_last_changed_by_user_at', 'patch.test_state_changed'),
    category = ('system_update_v2.category', 'patch.category'),
    groups = ('system_update_v2.groups', 'patch.groups')
  ),
  profiles (
    _id,
    org_id,
    package_id,
    coreq_package_id,
    package_name,
    package_description,
    package_version,
    current_installed_version,
    package_release_date,
    package_vendor,
    package_type,
    package_severity,
    package_reboot_type,
    package_size,
    disk_space_required,
    package_tips,
    readme_url,
    license_url,
    created_at,
    last_modified_date,
    test_state,
    test_state_last_changed_by_user_at,
    category,
    groups
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
  org_id,
  package_id,
  coreq_package_id,
  package_name,
  package_description,
  package_version,
  current_installed_version,
  cast(package_release_date as timestamp) as package_release_date,
  package_vendor,
  package_type,
  package_severity,
  package_reboot_type,
  package_size,
  disk_space_required,
  package_tips,
  readme_url,
  license_url,
  cast(created_at as timestamp) as created_at,
  cast(last_modified_date as timestamp) as last_modified_date,
  test_state,
  cast(test_state_last_changed_by_user_at as timestamp) as test_state_last_changed_by_user_at,
  category,
  groups
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY _id
            ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
        ) AS rn 
    FROM s3depot.demolake04.system_update_v2
)
WHERE rn = 1
