#!/usr/bin/env bash
# ACME App - Simulação de falha e rollback (Gabriel Domingueti)
# Uso: bash rollback.sh
# Pré-requisitos: Docker em execução, imagens acme-app:1.0.0 e acme-app:1.1.0,
# e a 1.1.0 rodando como acme-producao na porta 8080 (parte do Mateus).
# O script pausa entre as etapas e grava tudo em evidencias-rollback.txt.

# Nome do contêiner de produção. Se o grupo decidir usar acme-prod, troque só esta linha.
PROD="acme-producao"
LOG="evidencias-rollback.txt"
URL="http://localhost:8080"
: > "$LOG"

passo() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
  read -r -p "ENTER para executar... "
}

run() {
  # Mostra o comando, executa e registra a saída no log (sem abortar em erro).
  echo "\$ $*" | tee -a "$LOG"
  "$@" 2>&1 | tee -a "$LOG"
  echo | tee -a "$LOG"
}

stamp() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

# ---------- Verificação prévia ----------
for tag in 1.0.0 1.1.0; do
  if ! docker image inspect "acme-app:$tag" >/dev/null 2>&1; then
    echo "Imagem acme-app:$tag não encontrada. Construa com:"
    echo "  docker build --build-arg VERSION=$tag -t acme-app:$tag ."
    exit 1
  fi
done

# Se a produção não estiver de pé (Mateus ainda não rodou), cria na 1.1.0.
if ! docker ps --format '{{.Names}}' | grep -qx "$PROD"; then
  echo "$PROD não está rodando. Preparando a 1.1.0 em produção..."
  docker rm -f $PROD >/dev/null 2>&1
  docker run -d --name $PROD -p 8080:80 acme-app:1.1.0 >/dev/null
  sleep 2
fi

# ---------- Etapa 1 ----------
passo "ETAPA 1 - Produção na 1.1.0 respondendo em $URL"
stamp "ETAPA 1: estado inicial"
run docker ps --filter name=$PROD
run docker inspect --format 'Imagem do contêiner: {{.Config.Image}}' $PROD
echo "\$ curl -fsS $URL | grep -F 'Versão 1.1.0'" | tee -a "$LOG"
curl -fsS "$URL" | grep -F 'Versão 1.1.0' | tee -a "$LOG"
echo ">> Tire print do navegador em $URL (deve mostrar 1.1.0)"

# ---------- Etapa 2 ----------
passo "ETAPA 2 - Falha simulada: parar $PROD"
stamp "ETAPA 2: parando o contêiner"
run docker stop $PROD
echo "\$ curl -fsS $URL   (falha esperada)" | tee -a "$LOG"
curl -fsS "$URL" 2>&1 | tee -a "$LOG"
echo "(curl retornou erro: serviço indisponível)" | tee -a "$LOG"
run docker ps -a --filter name=$PROD
echo ">> Tire print do navegador (site inacessível) e deste terminal"

# ---------- Etapa 3 ----------
passo "ETAPA 3 - Rollback: remover o contêiner e recriar com a 1.0.0"
stamp "ETAPA 3: executando rollback"
run docker rm $PROD
run docker run -d --name $PROD -p 8080:80 acme-app:1.0.0
sleep 2

# ---------- Etapa 4 ----------
passo "ETAPA 4 - Confirmar que o serviço voltou na 1.0.0"
stamp "ETAPA 4: verificação pós-rollback"
run docker ps --filter name=$PROD
run docker inspect --format 'Imagem do contêiner: {{.Config.Image}}' $PROD
echo "\$ curl -fsS $URL | grep -F 'Versão 1.0.0'" | tee -a "$LOG"
curl -fsS "$URL" | grep -F 'Versão 1.0.0' | tee -a "$LOG"
echo ">> Tire print do navegador em $URL (deve mostrar 1.0.0)"

echo
echo "Concluído. Evidências em texto salvas em: $LOG"
