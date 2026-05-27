# Java dependencies for Vulcan (Spark)

Put Spark/JVM JAR dependencies in this folder.

For this project, `deploy.yml` points both classpaths to:

`/etc/dataos/work/dataos-2.0/vulcan-project-spark/dependencies/java/*`

To fetch baseline ML dependencies, run:

```bash
./scripts/fetch_test_dependencies.sh
```

This downloads `spark-mllib_2.12-<version>.jar` here.

Without using the shell script, download directly with:

```bash
SPARK_MLLIB_VERSION=3.5.1
curl -fsSL -o "dependencies/java/spark-mllib_2.12-${SPARK_MLLIB_VERSION}.jar" \
  "https://repo.maven.apache.org/maven2/org/apache/spark/spark-mllib_2.12/${SPARK_MLLIB_VERSION}/spark-mllib_2.12-${SPARK_MLLIB_VERSION}.jar"
```

Maven URL pattern:

```text
https://repo.maven.apache.org/maven2/org/apache/spark/spark-mllib_2.12/${SPARK_MLLIB_VERSION}/spark-mllib_2.12-${SPARK_MLLIB_VERSION}.jar
```
