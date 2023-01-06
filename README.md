# Open Data Stack

# Intro

This repository is made to deploy open source tools easily to have a modern serverless data stack. There is no Airflow and dbt is also in serverless mode being scheduled through Cloud Workflows.

It only supports GCP for now.

Planning to later add support for:

- **Airflow** for people who don't want to reduce costs and stay serverless.
- **Snowflake** because it's as popular as **BigQuery**, so why not.
- **AWS Cloud** because it's the most popular cloud provider.
- **Metabase** because it was (and is still) the go-to visualization tool to deploy in early stages projects
- **duckDB** because it's a trending database for analytics workloads

## Data Tools

- **GCP** IAM, APIs, etc...
- **Airbyte**: Extract and Load
- **dbt**: Transform
- **BigQuery**: Warehouse
- **Cloud Workflows** / **Cloud Scheduler**: Schedule
- **Lightdash**: Visualize
- **Streamlit**: Machine Learning UI

## Begin your journey

### Setup GCP Account and Billing

To use the Google Cloud Platform with this project, you will need to create a Google Cloud account and enable billing. In the billing page, you will find a billing ID in the format ######-######-######. Make sure to note this value, as it will be required in the next step.

### Setup Google Cloud CLI

To set up the Google Cloud SDK on your computer, follow the instructions provided for your specific operating system. Once you have installed the gcloud command-line interface (CLI), open a terminal window and run the following command. This will allow Terraform to use your default credentials for authentication.

```bash
gcloud auth application-default login
```

### Install Terraform

To use Terraform, you will first need to install the Terraform CLI on your local machine. Follow the instructions provided at the [following link](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli) to complete the installation.

### Fork this repository

You can just do it through the Github UI and then clone it to your local machine.

Or if you want to fork the repository with the following command:

```bash
gh repo fork REPOSITORY --org ORGANIZATION --clone=true
```

Then you will need to install Github CLI with the [following instructions](https://github.com/cli/cli#installation)

### Deploy the open data stack

To create the resources on Google Cloud, you will first have to fill your .env file. We provided a template, you can just copy it and rename it to .env.

Then you only need to fill what you want. BILLING_ID (which we already have thanks to step 1), PROJECT, REGION and ZONE should at least be set. You can keep default REGION and ZONE that we set in the template file. Make sure that your PROJECT variable is 6 to 30 characters in length and only contains lowercase letters, numbers, and hyphens.

Finally run the following command in a terminal window:

```bash
make all
```

This will create a google project, a gcs bucket for Terraform state infrastructure storage and deploy the IaC afterwards. That's it.

## The different tools deployed

### Airbyte

If you want to directly access your airbyte instance, we can tunnel the instance IP to our localhost with this command:

```bash
make airbyte-tunnel
```

You can now create connectors between your sources and destinations.

When you don't need to connect to the instance anymore just run:

```bash
make airbyte-fuser
```

### Lightdash

TODO
