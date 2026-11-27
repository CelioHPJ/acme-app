# ACME App — Falha e Rollback

**Objetivo:** partindo da 1.1.0 em produção (`acme-producao`, porta 8080), simular uma indisponibilidade e restaurar o serviço na 1.0.0 usando a imagem anterior, que continua disponível localmente.

## Pré-requisitos

- Docker em execução, além de `curl` e `grep`.
- Imagens `acme-app:1.0.0` e `acme-app:1.1.0` construídas (ver `comandos.md`, seção 1).
- Contêiner `acme-producao` rodando a 1.1.0 na porta 8080 (resultado do `deploy.md`).
- Contêineres de teste do removidos, se a porta 8081 for necessária para a homologação: `docker rm -f acme-teste-100 acme-teste-110`.

## Etapa 1 — Produção na 1.1.0

```bash
docker ps --filter name=acme-producao
curl -fsS http://localhost:8080 | grep -F 'Versão 1.1.0'
```

**Esperado:** contêiner `Up`, porta `0.0.0.0:8080->80/tcp`, linha HTML com `Versão 1.1.0`.

## Etapa 2 — Falha simulada

```bash
docker stop acme-producao
curl -fsS http://localhost:8080
docker ps -a --filter name=acme-producao
```

**Esperado:** `curl` falha com `Failed to connect ... Connection refused`; o contêiner aparece como `Exited`. No navegador, o site fica inacessível.

## Etapa 3 — Rollback para a 1.0.0

```bash
docker rm acme-producao
docker run -d --name acme-producao -p 8080:80 acme-app:1.0.0
```

**Esperado:** o `docker rm` libera o nome; o `docker run` devolve o ID do novo contêiner.

## Etapa 4 — Serviço restaurado

```bash
docker ps --filter name=acme-producao
docker inspect --format '{{.Config.Image}}' acme-producao
curl -fsS http://localhost:8080 | grep -F 'Versão 1.0.0'
```

**Esperado:** contêiner `Up`, imagem `acme-app:1.0.0`, linha HTML com `Versão 1.0.0`.

Se o Nginx ainda estiver iniciando, aguarde alguns segundos e repita o `curl`.

## Tabela de evidências (ordem cronológica)

| Ordem | Estado | Comando-chave | Resultado obtido | Evidência |
|---|---|---|---|---|
| 1 | Produção na 1.1.0 | `docker ps --filter name=acme-producao` + `curl ... grep 'Versão 1.1.0'` | Contêiner `37726299c559`, imagem `acme-app:1.1.0`, `Up`, porta 8080; página mostra `Versão 1.1.0` | `Container_em_produção_1_1_0.png` |
| 2 | Falha simulada | `docker stop acme-producao` + `curl -fsS http://localhost:8080` | `curl: (7) Failed to connect to localhost:8080`; contêiner `Exited (0)` | `Falha_simulada.png` |
| 3 | Rollback executado | `docker rm acme-producao` + `docker run ... acme-app:1.0.0` | Contêiner removido; novo contêiner criado (`6b7fee01e445...`) | `Rollback_para_1_0_0.png` |
| 4 | Produção restaurada na 1.0.0 | `docker ps` + `docker inspect` + `curl ... grep 'Versão 1.0.0'` | Contêiner `6b7fee01e445`, imagem `acme-app:1.0.0`, `Up`; página mostra `Versão 1.0.0` | `Serviço_restaurado.png` |

## Plano B

Se faltar internet no dia, use o `docker load` descrito na seção 7 do `comandos.md` e depois execute este roteiro normalmente.

## Execução automatizada

O script `rollback.sh` percorre as quatro etapas com pausas e grava a saída em `evidencias-rollback.txt`:

```bash
bash rollback.sh
```
