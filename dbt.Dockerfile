FROM ghcr.io/dbt-labs/dbt-core:1.2.3

ARG DBT_PROJECT
USER root

COPY dbt_serverless/requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt

WORKDIR /dbt

COPY credentials/profiles.yml ./
COPY dbt_serverless/ ./
COPY ${DBT_PROJECT}/ ./


ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
