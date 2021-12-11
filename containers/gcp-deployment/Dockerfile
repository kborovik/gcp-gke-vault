FROM ubuntu:rolling

ARG ROOT_CA_CERTIFICATE_URL

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update \
  && apt-get -y install apt-utils software-properties-common openssh-client curl jq ca-certificates uuid-runtime \
  && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/terraform.list \
  && curl -fsSL https://baltocdn.com/helm/signing.asc | apt-key add - && echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
  && curl -fsSLo /usr/local/share/ca-certificates/lab5-k8s-d1.crt ${ROOT_CA_CERTIFICATE_URL} \
  && apt-get -y update \
  && apt-get -y install terraform \
  && apt-get -y install vault \
  && apt-get -y install google-cloud-sdk \
  && apt-get -y install kubectl \
  && apt-get -y install helm \
  && apt-get -y remove apt-utils software-properties-common \
  && apt-get -y autoremove \
  && apt-get -y update \
  && apt-get -y upgrade \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src

ENTRYPOINT [ "/usr/bin/env" ]
