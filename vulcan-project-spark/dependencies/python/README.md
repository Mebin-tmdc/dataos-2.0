# Python dependencies for Vulcan (Spark)

Vulcan resolves Python wheels relative to the repo `baseDir`.
For this project, that path is:

`/etc/dataos/work/dataos-2.0/vulcan-project-spark`

At runtime, Vulcan automatically discovers and installs every `.whl` under:

`dependencies/python/`

and all nested folders inside it.

## Add scikit-learn as wheel(s)

From the project root (`dataos-2.0/vulcan-project-spark`), run:

```bash
python3 -m pip download --only-binary=:all: --dest dependencies/python scikit-learn
```

This command downloads `scikit-learn` plus required dependency wheels into
`dependencies/python`, so Vulcan can install them during run startup.

## Optional: add internal wheels

Copy your own package wheels into the same folder, for example:

```text
dependencies/python/
├── scikit_learn-<version>-<platform>.whl
├── numpy-<version>-<platform>.whl
└── internal/
    └── your_team_utils-0.1.0-py3-none-any.whl
```

## Validation

The model `models/data_model/issue_feature_engineering.py` imports:

- `sklearn.preprocessing.StandardScaler`
- `sklearn.preprocessing.PolynomialFeatures`
- `sklearn.preprocessing.OrdinalEncoder`

If wheels are present in `dependencies/python`, these imports resolve in Vulcan runtime.
