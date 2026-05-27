#!/usr/bin/env bash
# Downloads project-local JARs and Python wheels for vulcan-project-spark.
# Run from project root: ./scripts/fetch_test_dependencies.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAVA_DIR="${ROOT}/dependencies/java"
PY_DIR="${ROOT}/dependencies/python"
PYTHON_BIN="${PYTHON_BIN:-python3}"
TARGET_PLATFORM="${TARGET_PLATFORM:-manylinux2014_x86_64}"
TARGET_PYTHON="${TARGET_PYTHON:-39}"
TARGET_ABI="${TARGET_ABI:-cp39}"
TARGET_IMPL="${TARGET_IMPL:-cp}"

mkdir -p "${JAVA_DIR}" "${PY_DIR}"

SPARK_MLLIB_VERSION="${SPARK_MLLIB_VERSION:-3.5.1}"
MLLIB_JAR="spark-mllib_2.12-${SPARK_MLLIB_VERSION}.jar"
MLLIB_JAR_PATH="${JAVA_DIR}/${MLLIB_JAR}"
MLLIB_JAR_TMP="${MLLIB_JAR_PATH}.tmp"

echo "Fetching ${MLLIB_JAR} -> ${JAVA_DIR}/"
curl -fsSL -o "${MLLIB_JAR_TMP}" \
  "https://repo.maven.apache.org/maven2/org/apache/spark/spark-mllib_2.12/${SPARK_MLLIB_VERSION}/${MLLIB_JAR}"
rm -f "${JAVA_DIR}"/spark-mllib_2.12-*.jar 2>/dev/null || true
mv "${MLLIB_JAR_TMP}" "${MLLIB_JAR_PATH}"

echo "Cleaning old local-platform binary wheels -> ${PY_DIR}/"
rm -f "${PY_DIR}"/numpy-*.whl 2>/dev/null || true
rm -f "${PY_DIR}"/scipy-*.whl 2>/dev/null || true
rm -f "${PY_DIR}"/scikit_learn-*.whl 2>/dev/null || true

echo "Fetching Linux cp${TARGET_PYTHON} wheels for scikit-learn stack -> ${PY_DIR}/"
"${PYTHON_BIN}" -m pip download \
  --only-binary=:all: \
  --platform "${TARGET_PLATFORM}" \
  --implementation "${TARGET_IMPL}" \
  --python-version "${TARGET_PYTHON}" \
  --abi "${TARGET_ABI}" \
  -d "${PY_DIR}" \
  "numpy==1.26.4" \
  "scipy==1.11.4" \
  "scikit-learn==1.5.2" \
  "joblib==1.4.2" \
  "threadpoolctl==3.5.0"

echo "Done."
