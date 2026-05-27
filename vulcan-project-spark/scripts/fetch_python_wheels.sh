#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WHEEL_DIR="${ROOT_DIR}/dependencies/python"
PYTHON_BIN="${PYTHON_BIN:-python3}"
TARGET_PLATFORM="${TARGET_PLATFORM:-manylinux2014_x86_64}"
TARGET_PYTHON="${TARGET_PYTHON:-39}"
TARGET_ABI="${TARGET_ABI:-cp39}"
TARGET_IMPL="${TARGET_IMPL:-cp}"

mkdir -p "${WHEEL_DIR}"

"${PYTHON_BIN}" -m pip download \
  --only-binary=:all: \
  --platform "${TARGET_PLATFORM}" \
  --implementation "${TARGET_IMPL}" \
  --python-version "${TARGET_PYTHON}" \
  --abi "${TARGET_ABI}" \
  --dest "${WHEEL_DIR}" \
  "numpy==1.26.4" \
  "pandas==2.2.2" \
  "scipy==1.11.4" \
  "scikit-learn==1.5.2" \
  "joblib==1.4.2" \
  "threadpoolctl==3.5.0" \
  "python-dateutil==2.9.0.post0" \
  "pytz==2024.1" \
  "tzdata==2024.1" \
  "six==1.16.0"

echo "Wheels downloaded to: ${WHEEL_DIR}"