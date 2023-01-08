import json
import logging
from os import environ

from google.cloud import storage

logger = logging.getLogger(__name__)
DBT_PROJECT = environ.get("DBT_PROJECT", ".")
search_str = 'o=[i("manifest","manifest.json"+t),i("catalog","catalog.json"+t)]'

gcs = storage.Client()


def merge_dbt_docs():
    """Merge three dbt docs files in one single html final file."""
    with open(f"{DBT_PROJECT}/target/index.html", "r") as f:
        content_index = f.read()

    with open(f"{DBT_PROJECT}/target/manifest.json", "r") as f:
        json_manifest = json.loads(f.read())

    with open(f"{DBT_PROJECT}/target/catalog.json", "r") as f:
        json_catalog = json.loads(f.read())

    with open(f"{DBT_PROJECT}/target/index_merged.html", "w") as f:
        new_str = (
            "o=[{label: 'manifest', data: "
            + json.dumps(json_manifest)
            + "},{label: 'catalog', data: "
            + json.dumps(json_catalog)
            + "}]"
        )
        new_content = content_index.replace(search_str, new_str)
        f.write(new_content)


def upload_blob(bucket_name, source_file_name, destination_blob_name):
    """Uploads a file to the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_name)


def main():
    logger.info("Merging dbt docs in one single file")
    merge_dbt_docs()
    bucket = gcs.get_bucket("dbt-static-docs-bucket")
    logger.info("Uploading the file to GCS for static website serving")
    upload_blob(bucket, f"{DBT_PROJECT}/target/index_merged.html", "index_merged.html")


if __name__ == "__main__":
    main()
