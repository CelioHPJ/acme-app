# ACME App — Gerenciamento de Releases

Roteiro para execução manual. É necessário ter Docker instalado e em execução,
além de `curl` e `grep`. Execute os comandos na ordem indicada. O botão da
versão 1.1.0 é demonstrativo, sem integração com um serviço de contato.

## 1. Build das imagens

Partindo do diretório que contém a pasta `acme-app`, entre no projeto.
O ponto final dos comandos de build indica o diretório atual como contexto.
No primeiro build, é necessário acesso à imagem base `nginx:alpine`.

```bash
cd acme-app
docker build --build-arg VERSION=1.0.0 -t acme-app:1.0.0 .
docker build --build-arg VERSION=1.1.0 -t acme-app:1.1.0 .
```

## 2. Execução dos contêineres de teste

Cada imagem terá seu próprio contêiner. As portas 8081 e 8082 do computador
serão encaminhadas para a porta 80 dos respectivos contêineres.

```bash
docker run -d --name acme-teste-100 -p 8081:80 acme-app:1.0.0
docker run -d --name acme-teste-110 -p 8082:80 acme-app:1.1.0
```

Abra `http://localhost:8081` e `http://localhost:8082` no navegador para comparar
as versões, as cores e a nova funcionalidade.

## 3. Verificação da versão com curl e grep

Os comandos devem exibir a linha HTML com a versão esperada.
Se o Nginx ainda estiver iniciando, aguarde alguns instantes e repita.

```bash
curl -fsS http://localhost:8081 | grep -F 'Versão 1.0.0'
curl -fsS http://localhost:8082 | grep -F 'Versão 1.1.0'
```

## 4. Evidências das imagens e dos contêineres

Registre a saída destes comandos para demonstrar as duas tags e os dois
contêineres de teste em execução.

```bash
docker images acme-app
docker ps
```

## 5. Simulação de deploy, atualização e rollback

### Deploy inicial da versão 1.0.0

O ambiente de produção simulado usa o nome `acme-prod` e a porta 8080.

```bash
docker run -d --name acme-prod -p 8080:80 acme-app:1.0.0
curl -fsS http://localhost:8080 | grep -F 'Versão 1.0.0'
```

### Atualização para a versão 1.1.0

Pare e remova o contêiner atual para liberar o nome e a porta. Depois, crie
outro contêiner com a imagem 1.1.0. Há uma breve interrupção nessa simulação.

```bash
docker stop acme-prod
docker rm acme-prod
docker run -d --name acme-prod -p 8080:80 acme-app:1.1.0
curl -fsS http://localhost:8080 | grep -F 'Versão 1.1.0'
```

### Rollback para a versão 1.0.0

Recrie o contêiner com a imagem anterior, que permanece disponível localmente.

```bash
docker stop acme-prod
docker rm acme-prod
docker run -d --name acme-prod -p 8080:80 acme-app:1.0.0
curl -fsS http://localhost:8080 | grep -F 'Versão 1.0.0'
```

Em qualquer verificação, se o Nginx ainda estiver iniciando, aguarde alguns
instantes e repita o comando `curl`. Confira também `http://localhost:8080`
no navegador após cada troca.

## 6. Limpeza dos contêineres

Remova os três contêineres da atividade. A opção `-f` permite remover os
contêineres mesmo que estejam em execução. As imagens são preservadas.

```bash
docker rm -f acme-teste-100 acme-teste-110 acme-prod
```

## 7. Plano B sem internet: docker save e docker load

Prepare o arquivo abaixo em uma máquina que já tenha as duas imagens
construídas, antes de ficar sem internet. O arquivo inclui as duas tags e
suas camadas necessárias para execução.

```bash
docker save -o acme-app-imagens.tar acme-app:1.0.0 acme-app:1.1.0
```

Transfira `acme-app-imagens.tar` para a máquina sem internet, que deve ter
Docker instalado. No diretório que contém o arquivo, carregue as imagens:

```bash
docker load -i acme-app-imagens.tar
docker images acme-app
```

Depois da carga, siga os passos 2 a 6 diretamente, sem executar o build do
passo 1. As imagens já estarão disponíveis localmente para os contêineres
de teste, o deploy, a atualização e o rollback.
