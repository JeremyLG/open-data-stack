ARG GCLOUD_VERSION=slim
FROM google/cloud-sdk:${GCLOUD_VERSION}

# Use ARG so that values can be overriden by user/cloudbuild
ARG TERRAFORM_VERSION=1.3.7
ARG TERRAFORM_VERSION_SHA256SUM=b8cf184dee15dfa89713fe56085313ab23db22e17284a9a27c0999c67ce3021e

ENV ENV_TERRAFORM_VERSION=$TERRAFORM_VERSION
ENV ENV_TERRAFORM_VERSION_SHA256SUM=$TERRAFORM_VERSION_SHA256SUM

RUN apt-get update && \
    apt-get -y install curl jq unzip git ca-certificates google-cloud-sdk-terraform-tools && \
    curl https://releases.hashicorp.com/terraform/${ENV_TERRAFORM_VERSION}/terraform_${ENV_TERRAFORM_VERSION}_linux_amd64.zip \
    > terraform_linux_amd64.zip && \
    echo "${ENV_TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS && \
    sha256sum -c terraform_SHA256SUMS --status && \
    mkdir -p /builder && \
    unzip terraform_linux_amd64.zip -d /builder/terraform && \
    rm -f terraform_linux_amd64.zip terraform_SHA256SUMS

RUN apt-get install -y gettext-base psmisc bash-completion

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir dbt-bigquery

RUN apt-get --purge -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/builder/terraform/:$PATH

WORKDIR /opt/app

ENTRYPOINT ["/bin/bash"]
