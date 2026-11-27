# Usa a imagem do Nginx baseada em Alpine para servir a página HTML.
FROM nginx:alpine
# Define a versão escolhida no build, usando 1.0.0 como valor padrão.
ARG VERSION=1.0.0
# Registra a versão escolhida nos metadados da imagem.
LABEL version="${VERSION}"
# Copia a página da versão escolhida para o diretório servido pelo Nginx.
COPY v${VERSION}/index.html /usr/share/nginx/html/index.html
# Documenta a porta HTTP usada pelo Nginx dentro do contêiner.
EXPOSE 80
