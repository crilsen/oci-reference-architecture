#!/usr/bin/env bash
set -Eeuo pipefail

GCLOUD_VERSION="${GCLOUD_VERSION:-583.0.0}"
INSTALL_PARENT="${GCLOUD_INSTALL_PARENT:-${HOME}/.local}"
INSTALL_DIR="${INSTALL_PARENT}/google-cloud-sdk"
ZSH_RC="${HOME}/.zshrc"

log() {
  printf '\n==> %s\n' "$*"
}

fail() {
  printf '\nERRO: %s\n' "$*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || fail "curl não foi encontrado."
command -v tar >/dev/null 2>&1 || fail "tar não foi encontrado."
[[ "$(uname -s)" == "Darwin" ]] || fail "Este script suporta somente macOS."

case "$(uname -m)" in
  arm64)  GCLOUD_ARCH="arm" ;;
  x86_64) GCLOUD_ARCH="x86_64" ;;
  *)      fail "Arquitetura não suportada: $(uname -m)" ;;
esac

DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-darwin-${GCLOUD_ARCH}.tar.gz"
TEMP_DIR="$(mktemp -d)"

cleanup() {
  if [[ -d "${TEMP_DIR}" ]]; then
    rm -rf -- "${TEMP_DIR}"
  fi
}
trap cleanup EXIT

log "Verificando instalação incompleta do Homebrew"
if command -v brew >/dev/null 2>&1 && brew list --cask gcloud-cli >/dev/null 2>&1; then
  brew uninstall --cask gcloud-cli --force
fi

log "Baixando Google Cloud CLI ${GCLOUD_VERSION} para ${GCLOUD_ARCH}"
curl --fail --location --retry 3 --progress-bar \
  --output "${TEMP_DIR}/google-cloud-cli.tar.gz" \
  "${DOWNLOAD_URL}"

log "Extraindo pacote oficial"
tar -xzf "${TEMP_DIR}/google-cloud-cli.tar.gz" -C "${TEMP_DIR}"
[[ -x "${TEMP_DIR}/google-cloud-sdk/install.sh" ]] || fail "Pacote baixado não contém o instalador esperado."

mkdir -p "${INSTALL_PARENT}"
if [[ -e "${INSTALL_DIR}" ]]; then
  BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
  log "Preservando instalação anterior em ${BACKUP_DIR}"
  mv "${INSTALL_DIR}" "${BACKUP_DIR}"
fi

mv "${TEMP_DIR}/google-cloud-sdk" "${INSTALL_DIR}"

log "Instalando Google Cloud CLI com Python gerenciado pelo instalador oficial"
"${INSTALL_DIR}/install.sh" \
  --quiet \
  --usage-reporting=false \
  --path-update=true \
  --command-completion=true \
  --rc-path="${ZSH_RC}" \
  --install-python=true

GCLOUD_BIN="${INSTALL_DIR}/bin/gcloud"
[[ -x "${GCLOUD_BIN}" ]] || fail "O executável gcloud não foi criado."

log "Validando a instalação"
"${GCLOUD_BIN}" version

printf '\nDeseja autenticar agora e configurar o projeto para o Terraform? [s/N] '
read -r AUTH_REPLY
if [[ "${AUTH_REPLY}" =~ ^[sSyY]$ ]]; then
  "${GCLOUD_BIN}" auth login
  "${GCLOUD_BIN}" auth application-default login

  printf '\nInforme o project ID do Google Cloud: '
  read -r PROJECT_ID
  [[ -n "${PROJECT_ID}" ]] || fail "Project ID vazio."

  "${GCLOUD_BIN}" config set project "${PROJECT_ID}"
  "${GCLOUD_BIN}" auth application-default set-quota-project "${PROJECT_ID}"

  log "Verificando credenciais ADC e faturamento"
  "${GCLOUD_BIN}" auth application-default print-access-token >/dev/null
  "${GCLOUD_BIN}" billing projects describe "${PROJECT_ID}" \
    --format='yaml(projectId,billingEnabled,billingAccountName)'
fi

log "Instalação concluída"
printf '%s\n' \
  "Abra um novo terminal ou execute:" \
  "  source ${ZSH_RC}" \
  "Depois valide com:" \
  "  gcloud version" \
  "  terraform version"
