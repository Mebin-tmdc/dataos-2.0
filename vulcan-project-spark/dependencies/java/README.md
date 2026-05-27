# Java dependencies for Vulcan (Spark)

Put Spark/JVM JAR dependencies in this folder.

For this project, `deploy.yml` points both classpaths to:

`/etc/dataos/work/dataos-2.0/vulcan-project-spark/dependencies/java/*`

To fetch baseline ML dependencies, run:

```bash
./scripts/fetch_test_dependencies.sh
```

This downloads `spark-mllib_2.12-<version>.jar` here.
