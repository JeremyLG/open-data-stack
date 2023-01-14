# Open Data Stack

- [Open Data Stack](#open-data-stack)
- [Intro](#intro)
  - [Data Tools](#data-tools)
  - [Begin your journey](#begin-your-journey)
    - [Setup GCP Account and Billing](#setup-gcp-account-and-billing)
    - [Setup Google Cloud CLI](#setup-google-cloud-cli)
    - [Install Terraform](#install-terraform)
    - [Fork this repository](#fork-this-repository)
    - [Deploy the open data stack](#deploy-the-open-data-stack)
  - [The different tools deployed](#the-different-tools-deployed)
    - [Airbyte](#airbyte)
    - [dbt](#dbt)
    - [Lightdash](#lightdash)
  - [Known issues and technical difficulties](#known-issues-and-technical-difficulties)

# Intro

This repository is made to deploy open source tools easily to have a modern data stack.

There is no real need for Airflow, because dbt is meant to be deployed in serverless mode with this repository (Cloud Workflows + Cloud Scheduler). This is an opinionated choice, because I dislike the current use data teams make of Airflow. But later on I will still add support for it.

It only supports GCP for now.

As Airbyte and Lightdash needs multiple containers to run, they can't be deployed in serverless. Thus they are deployed as Compute Engine VM.

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

TODO document github PAT

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

You can now create connectors between your sources and destinations on the url _localhost:8002_

When you don't need to connect to the instance anymore just run:

```bash
make airbyte-fuser
```

### dbt

You can initialize a dbt project with the command:

```bash
make dbt-init
```

It will be based on three env variables located in your .env file: _PROJECT_, _DBT_PROJECT_ and _DBT_DATASET_.

Then you can locally run your models, views, etc... with the following command:

```bash
make dbt-run
```

TODO develop serverless dbt

### Lightdash

If you want to directly access your lightdash instance, we can tunnel the instance IP to our localhost with this command:

```bash
make lightdash-tunnel
```

You can now connect on the url _localhost:8003_, sadly Lightdash isn't really terraform friendly so we need to do some UI few steps. For now I don't know how to automate this, I will need to deep dive in the CLI (or even API if there is any)

See Lightdash initial project setup tutorial in our docs [here](docs/lightdash.md)

When you don't need to connect to the instance anymore just run:

```bash
make lightdash-fuser
```

## Known issues and technical difficulties

[New latest image version](https://stackoverflow.com/questions/74029047/cloud-run-deployment-pattern-when-new-images-are-pushed-if-services-are-created)
