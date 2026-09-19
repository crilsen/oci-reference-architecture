#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${project_root}/environments/kubernetes/private.auto.tfvars"
public_tfvars="${project_root}/environments/kubernetes/terraform.tfvars"
oci_config="${OCI_CLI_CONFIG_FILE:-${HOME}/.oci/config}"
profile="${OCI_CLI_PROFILE:-DEFAULT}"

command -v oci >/dev/null || { echo "OCI CLI nao encontrada." >&2; exit 1; }
[[ -f "${oci_config}" ]] || { echo "Configuracao OCI nao encontrada." >&2; exit 1; }

tenancy_ocid=$(awk -F= -v section="[${profile}]" '$0 == section { active=1; next } /^\[/ { active=0 } active && $1 == "tenancy" { print $2; exit }' "${oci_config}")
oci_region=$(awk -F= -v section="[${profile}]" '$0 == section { active=1; next } /^\[/ { active=0 } active && $1 == "region" { print $2; exit }' "${oci_config}")
[[ -n "${tenancy_ocid}" ]] || { echo "Tenancy nao encontrada no perfil ${profile}." >&2; exit 1; }
[[ -n "${oci_region}" ]] || { echo "Regiao nao encontrada no perfil ${profile}." >&2; exit 1; }

[[ -f "${public_tfvars}" ]] || { echo "terraform.tfvars nao encontrado." >&2; exit 1; }
vcn_id=$(awk -F= '/^[[:space:]]*vcn_id[[:space:]]*=/{gsub(/[[:space:]"\\]/, "", $2); print $2; exit}' "${public_tfvars}")
configured_compartment=$(awk -F= '/^[[:space:]]*compartment_ocid[[:space:]]*=/{gsub(/[[:space:]"\\]/, "", $2); print $2; exit}' "${public_tfvars}")
[[ -n "${vcn_id}" ]] || { echo "vcn_id nao encontrado em terraform.tfvars." >&2; exit 1; }

compartment_ocid="${configured_compartment}"
if [[ -z "${compartment_ocid}" ]]; then
  compartment_ocid=$(oci network vcn get --vcn-id "${vcn_id}" --query 'data."compartment-id"' --raw-output)
fi
availability_domain=$(oci iam availability-domain list --compartment-id "${tenancy_ocid}" --query 'data[0].name' --raw-output)
ssh_key_path="${SSH_PUBLIC_KEY_PATH:-${HOME}/.ssh/id_ed25519.pub}"
[[ -f "${ssh_key_path}" ]] || ssh_key_path="${HOME}/.ssh/id_rsa.pub"
[[ -n "${compartment_ocid}" && "${compartment_ocid}" != "null" && -n "${availability_domain}" && -f "${ssh_key_path}" ]] || { echo "Nao foi possivel obter dados OCI ou chave SSH." >&2; exit 1; }

image_ocid=$(oci compute image list --compartment-id "${compartment_ocid}" --operating-system "Canonical Ubuntu" --operating-system-version "24.04" --shape "VM.Standard.A1.Flex" --sort-by TIMECREATED --sort-order DESC --query 'data[0].id' --raw-output)
[[ -n "${image_ocid}" && "${image_ocid}" != "null" ]] || { echo "Imagem Ampere nao encontrada." >&2; exit 1; }

nat_image_ocid=$(oci compute image list --compartment-id "${compartment_ocid}" --operating-system "Canonical Ubuntu" --operating-system-version "24.04" --shape "VM.Standard.E2.1.Micro" --sort-by TIMECREATED --sort-order DESC --query 'data[0].id' --raw-output)
[[ -n "${nat_image_ocid}" && "${nat_image_ocid}" != "null" ]] || { echo "Imagem x86 para NAT nao encontrada." >&2; exit 1; }

umask 077
{
  echo '# Gerado localmente; nao versione.'
  printf 'tenancy_ocid        = "%s"\n' "${tenancy_ocid}"
  printf 'oci_region          = "%s"\n' "${oci_region}"
  printf 'compartment_ocid    = "%s"\n' "${compartment_ocid}"
  printf 'availability_domain = "%s"\n' "${availability_domain}"
  printf 'instance_image_ocid = "%s"\n' "${image_ocid}"
  printf 'nat_instance_image_ocid = "%s"\n' "${nat_image_ocid}"
  printf 'ssh_public_key      = "%s"\n' "$(<"${ssh_key_path}")"
} > "${target_file}"

echo "Criado: ${target_file}"
