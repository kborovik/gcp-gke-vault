#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

source "scripts/lib-functions.sh"

_usage() {
  echo -e "\n Usage: $(basename $0)"
  echo -e "\t -p <google_project>   - GCP Project ID (required)"
  echo -e "\t -a                    - Apply Terraform scripts (optional)"
  echo -e "\t -l                    - Show Terraform state (optional)"
  echo -e "\t -s                    - Suspend Terraform resources (optional)"
  echo -e "\t -d                    - Destroy Terraform resources (optional)"
  echo -e "\n Examples:"
  echo -e "\n Terraform plan:\n\t $(basename $0) -p <google_project>"
  echo -e "\n Terraform apply:\n\t $(basename $0) -p <google_project> -a"
  echo -e "\n Terraform show:\n\t $(basename $0) -p <google_project> -l"
  echo -e "\n Terraform destroy:\n\t $(basename $0) -p <google_project> -d"
  exit 1
}

while getopts "p:adslh" option; do
  case ${option} in
  p)
    google_project=${OPTARG}
    ;;
  a)
    terraform="apply"
    ;;
  d)
    terraform="destroy"
    ;;
  s)
    terraform="suspend"
    ;;
  l)
    terraform="show"
    ;;
  *)
    _usage
    ;;
  esac
done

if [[ -z ${google_project} ]]; then
  _usage
fi

_validate_google_project_name ${google_project}
_activate_gcloud_profile ${google_project}

export GOOGLE_PROJECT=${google_project}

cd terraform/gcp || exit

_validate_terraform_fmt

terraform init -upgrade -input=false -reconfigure \
  -backend-config="bucket=terraform-${google_project}" \
  -backend-config="prefix=terraform-state/gcp"

terraform validate

google_project_config="${google_project}.tfvars"

if [[ ! -f ${google_project_config} ]]; then
  echo -e "### ERROR: Google project ${google_project} config file ${google_project_config} not found"
  exit 1
fi

if [[ ${terraform} == "apply" ]]; then

  terraform apply -auto-approve -var-file="${google_project_config}" -input=false -refresh=true
  terraform output -json -no-color >output.json
  gsutil cp "file://output.json" "gs://terraform-${google_project}/terraform-state/gcp/"

elif [[ ${terraform} == "destroy" ]]; then

  terraform plan -destroy -var-file="${google_project_config}" -out tfplan.bin
  read -r -N 1 -p "Destroy Terraform deployment? Y/N: " destroy
  if [[ "${destroy}" =~ [Yy] ]]; then
    terraform apply -destroy -input=false tfplan.bin
  fi

elif [[ ${terraform} == "suspend" ]]; then

  for gcp_instance in $(gcloud compute instances list --filter='labels.daily_shutdown=yes AND status=RUNNING' --format='value(name)'); do
    gcp_zone=$(gcloud compute instances list --filter="${gcp_instance}" --format='value(zone)')
    gcloud compute instances stop "${gcp_instance}" --zone="${gcp_zone:?}"
  done

  for gcp_privateca in $(gcloud privateca roots list --format=json | jq -r ".[] | select(.state==\"ENABLED\") | .name"); do
    gcloud privateca roots disable "${gcp_privateca}"
  done

  for gcp_cluster in $(terraform state list | grep google_container_cluster); do
    terraform plan -destroy -var-file="${google_project_config}" -compact-warnings -out tfplan.bin -target="${gcp_cluster}"
    terraform apply -destroy tfplan.bin
    rm -rf tfplan.bin
  done

elif [[ ${terraform} == "show" ]]; then
  terraform show
else
  terraform plan -var-file="${google_project_config}" -input=false -refresh=true
fi
