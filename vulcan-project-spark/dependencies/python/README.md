# Python dependencies for Vulcan (Spark)

Vulcan runtime installs all `.whl` files from:

`dependencies/python/`

Important: download wheels for the Vulcan runtime platform (Linux), not your local macOS machine.

## Download compatible wheels

From project root:

```bash
./scripts/fetch_python_wheels.sh
```

Default target is Linux CPython 3.9 (`manylinux2014_x86_64`, `cp39`).

Override when needed:

```bash
TARGET_PLATFORM=manylinux2014_x86_64 TARGET_PYTHON=39 TARGET_ABI=cp39 ./scripts/fetch_python_wheels.sh
```

## What to avoid

- Do not commit `macosx_*` wheels for runtime use.
- If you see `not a supported wheel on this platform`, clear incompatible wheels and re-download with the script above.
