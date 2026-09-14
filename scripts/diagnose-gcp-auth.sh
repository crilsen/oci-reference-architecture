#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ID="${1:-}"
CLUSTER_NAME="${2:-kubernetes-lab}"
CLUSTER_ZONE="${3:-us-east1-b}"
GCLOUD_BIN="$(command -v gcloud || true)"

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'AVISO: %s\n' "$*" >&2
}

fail() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}

[[ -n "${PROJECT_ID}" ]] || {
  printf 'Uso: %s PROJECT_ID [CLUSTER_NAME] [ZONE]\n' "$0" >&2
  printf 'Exemplo: %s gcp-referente-infrastructure kubernetes-lab us-east1-b\n' "$0" >&2
  exit 2
}

[[ -n "${GCLOUD_BIN}" ]] || fail "gcloud não encontrado no PATH. Execute: source ~/.zshrc"
command -v curl >/dev/null 2>&1 || fail "curl não encontrado."

log "Versão do Google Cloud CLI"
"${GCLOUD_BIN}" version | sed -n '1,4p'

ACTIVE_ACCOUNT="$("${GCLOUD_BIN}" auth list --filter=status:ACTIVE --format='value(account)' | head -n 1)"
CONFIGURED_PROJECT="$("${GCLOUD_BIN}" config get-value project 2>/dev/null || true)"
IMPERSONATED_ACCOUNT="$("${GCLOUD_BIN}" config get-value auth/impersonate_service_account 2>/dev/null || true)"

printf 'Conta ativa do gcloud: %s\n' "${ACTIVE_ACCOUNT:-não encontrada}"
printf 'Projeto configurado:     %s\n' "${CONFIGURED_PROJECT:-não configurado}"
if [[ -n "${IMPERSONATED_ACCOUNT}" && "${IMPERSONATED_ACCOUNT}" != "(unset)" ]]; then
  printf 'Impersonação ativa:      %s\n' "${IMPERSONATED_ACCOUNT}"
fi

ADC_EMAIL=""
log "Identificando a credencial ADC usada pelo Terraform"
if ADC_TOKEN="$("${GCLOUD_BIN}" auth application-default print-access-token 2>/dev/null)"; then
  USERINFO="$(curl --fail --silent --show-error \
    --header "Authorization: Bearer ${ADC_TOKEN}" \
    https://openidconnect.googleapis.com/v1/userinfo 2>/dev/null || true)"
  unset ADC_TOKEN

  ADC_EMAIL="$(printf '%s' "${USERINFO}" | sed -nE 's/.*"email"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"
  if [[ -n "${ADC_EMAIL}" ]]; then
    printf 'Identidade ADC:          %s\n' "${ADC_EMAIL}"
  else
    warn "O token ADC existe, mas o endpoint não retornou o e-mail."
  fi
else
  warn "ADC não configurado. Execute: gcloud auth application-default login"
fi

if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  printf 'GOOGLE_APPLICATION_CREDENTIALS está definido: %s\n' "${GOOGLE_APPLICATION_CREDENTIALS}"
  if [[ -r "${GOOGLE_APPLICATION_CREDENTIALS}" ]] && [[ -x /usr/bin/python3 ]]; then
    SERVICE_ACCOUNT_EMAIL="$(/usr/bin/python3 -c \
      'import json,sys; print(json.load(open(sys.argv[1])).get("client_email", ""))' \
      "${GOOGLE_APPLICATION_CREDENTIALS}" 2>/dev/null || true)"
    [[ -n "${SERVICE_ACCOUNT_EMAIL}" ]] && printf 'Service account do arquivo: %s\n' "${SERVICE_ACCOUNT_EMAIL}"
  fi
fi

if [[ -n "${ADC_EMAIL}" && -n "${ACTIVE_ACCOUNT}" && "${ADC_EMAIL}" != "${ACTIVE_ACCOUNT}" ]]; then
  warn "A conta do gcloud é diferente da conta ADC usada pelo Terraform."
  printf 'Deseja autenticar e ativar %s no gcloud? [s/N] ' "${ADC_EMAIL}"
  read -r SWITCH_REPLY
  if [[ "${SWITCH_REPLY}" =~ ^[sSyY]$ ]]; then
    if ! "${GCLOUD_BIN}" auth list --filter="account:${ADC_EMAIL}" --format='value(account)' | grep -Fxq "${ADC_EMAIL}"; then
      "${GCLOUD_BIN}" auth login "${ADC_EMAIL}"
    fi
    "${GCLOUD_BIN}" config set account "${ADC_EMAIL}"
    ACTIVE_ACCOUNT="${ADC_EMAIL}"
  fi
fi

log "Configurando o projeto ${PROJECT_ID}"
"${GCLOUD_BIN}" config set project "${PROJECT_ID}" >/dev/null

log "Verificando acesso ao projeto"
if ! PROJECT_DETAILS="$("${GCLOUD_BIN}" projects describe "${PROJECT_ID}" \
  --format='yaml(projectId,name,projectNumber,lifecycleState)' 2>&1)"; then
  printf '%s\n' "${PROJECT_DETAILS}" >&2
  printf '\nA conta %s não consegue acessar %s.\n' "${ACTIVE_ACCOUNT:-ativa}" "${PROJECT_ID}" >&2
  printf 'Projetos visíveis para essa conta:\n' >&2
  "${GCLOUD_BIN}" projects list --format='table(projectId,name)' || true
  printf '\nEntre no Console com a conta proprietária e conceda Kubernetes Engine Admin:\n' >&2
  printf 'https://console.cloud.google.com/iam-admin/iam?project=%s\n' "${PROJECT_ID}" >&2
  exit 3
fi
printf '%s\n' "${PROJECT_DETAILS}"

log "Verificando acesso ao GKE"
if ! "${GCLOUD_BIN}" container clusters list \
  --project "${PROJECT_ID}" \
  --filter="name=${CLUSTER_NAME}" \
  --format='table(name,location,status,currentMasterVersion)'; then
  fail "A conta acessa o projeto, mas não possui permissão suficiente no GKE. Solicite roles/container.admin."
fi

if ! "${GCLOUD_BIN}" container clusters describe "${CLUSTER_NAME}" \
  --zone "${CLUSTER_ZONE}" \
  --project "${PROJECT_ID}" >/dev/null 2>&1; then
  fail "Cluster ${CLUSTER_NAME} não encontrado em ${CLUSTER_ZONE}, ou acesso negado."
fi

log "Obtendo credenciais do cluster"
"${GCLOUD_BIN}" container clusters get-credentials "${CLUSTER_NAME}" \
  --zone "${CLUSTER_ZONE}" \
  --project "${PROJECT_ID}"

if command -v kubectl >/dev/null 2>&1; then
  log "Testando acesso Kubernetes"
  kubectl get nodes
else
  warn "kubectl não está instalado; as credenciais do cluster foram configuradas."
fi

log "Diagnóstico concluído com sucesso"
