# Python dependencies for Vulcan (Spark)

Vulcan runtime installs all `.whl` files from:

`dependencies/python/`

Important: download wheels for the Vulcan runtime platform (Linux), not your local macOS machine.

## Download compatible wheels

From project root:

```bash
./scripts/fetch_python_wheels.sh
```

Without using the shell script, run:

```bash
python3 -m pip download \
  --only-binary=:all: \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 39 \
  --abi cp39 \
  -d dependencies/python \
  numpy==1.26.4 scipy==1.11.4 scikit-learn==1.5.2 joblib==1.4.2 threadpoolctl==3.5.0
```

If you want to build wheels instead of downloading prebuilt ones:

```bash
python3 -m pip wheel -w dependencies/python \
  numpy==1.26.4 scipy==1.11.4 scikit-learn==1.5.2 joblib==1.4.2 threadpoolctl==3.5.0
```

## Related Spark JAR

Spark MLLib JAR (3.5.1):

https://repo.maven.apache.org/maven2/org/apache/spark/spark-mllib_2.12/3.5.1/spark-mllib_2.12-3.5.1.jar

Default target is Linux CPython 3.9 (`manylinux2014_x86_64`, `cp39`).

Override when needed:

```bash
TARGET_PLATFORM=manylinux2014_x86_64 TARGET_PYTHON=39 TARGET_ABI=cp39 ./scripts/fetch_python_wheels.sh
```

## What to avoid

- Do not commit `macosx_*` wheels for runtime use.
- If you see `not a supported wheel on this platform`, clear incompatible wheels and re-download with the script above.
