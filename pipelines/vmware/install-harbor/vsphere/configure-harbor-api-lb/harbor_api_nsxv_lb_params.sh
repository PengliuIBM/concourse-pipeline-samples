#!/bin/bash

# set the path for the secrets below to be created in vault or credhub
export concourse_root_secrets_path="/concourse"
export concourse_team_name="team-name"
export concourse_pipeline_name="harbor-api-config-nsxv"

# VAULT or CREDHUB - targeted secrets management system
export targeted_system="VAULT"
# This script assumes that:
# 1) the credhub or vault CLI is installed
# 2) you setup your vault or credhub target and login commands prior to invoking it
#    e.g. for VAULT
#    export VAULT_ADDR=https://myvaultdomain:8200
#    export VAULT_SKIP_VERIFY=true
#    export VAULT_TOKEN=vault-token
#
#    e.g. for CREDHUB
#    credhub login -s credhub-server-uri -u username -p password --skip-tls-validation

##
## TEAM level secrets (shared by all pipelines in that team)
##
export team_secrets=(

  # vcenter hostname, do not include protocol information
  "vcenter_host"::"vcenter.domain.com"
  # vcenter credentials and properties
  "vcenter_usr"::"myvcenteruser@vsphere.local"
  "vcenter_pwd"::"myvcenterpassword"
  "vcenter_datacenter"::"Datacenter"
  "vcenter_datastore"::"mydatastore"

  "nsxv_manager_address"::"mynsxv.domain.com"
  "nsxv_manager_admin_username"::"admin"
  "nsxv_manager_admin_password"::"password"
  "nsxv_gen_edge_name"::"nsxv_gen_edge_name"
  "nsxv_gen_edge_cluster"::"Cluster-A"
  "nsxv_gen_mgr_transport_zone"::"nsxv_gen_mgr_transport_zone"
  "nsxv_gen_vip_ip"::"nsxv_gen_vip_ip"

)

##
## PIPELINE LEVEL secrets (specific to the pipeline)
##
export pipeline_secrets=(

  "api_domain"::"harbor.domain.com"
  "api_cert_cn"::"*.domain.com" # match the existing certificate domain in vcenter
  "api_ips"::"192.168.24.100"

)

main () {

  # team level secrets
  concourse_team_level_secrets_path="${concourse_root_secrets_path}/${concourse_team_name}"
  writeCredentials "${concourse_team_level_secrets_path}" "${team_secrets[*]}"

  # pipeline level secrets
  concourse_pipeline_level_secrets_path="${concourse_team_level_secrets_path}/${concourse_pipeline_name}"
  writeCredentials "${concourse_pipeline_level_secrets_path}" "${pipeline_secrets[*]}"

}

writeCredentials () {
  secretsPath=${1}
  secretsObject=(${2})

  for i in "${secretsObject[@]}"
  do
    KEY="${i%%::*}"
    VALUE="${i##*::}"
    echo "Creating secret for [$KEY]"
    if [[ $targeted_system == "VAULT" ]]; then
      vault write "${secretsPath}/${KEY}" value="${VALUE}"
    else   # CREDHUB
      credhub set -n "${secretsPath}/${KEY}" -v "${VALUE}"
    fi
  done
}

main
