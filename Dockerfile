# Stage 1: Build the React frontend
FROM node:18-alpine AS frontend-builder
WORKDIR /app/web-client
COPY web-client/package*.json ./
RUN npm install --no-audit --no-fund
COPY web-client/ ./
RUN npm run build

# Stage 2: Build the Go backend
FROM golang:1.21-alpine AS backend-builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o bin/mmb-server ./cmd/mmb-server

# Stage 3: Final image
FROM alpine:latest
WORKDIR /app

# Copia o binário em Go
COPY --from=backend-builder /app/bin/mmb-server ./bin/mmb-server

# Prepara os arquivos estáticos do front-end
RUN mkdir -p bin/web-client
COPY --from=frontend-builder /app/web-client/dist/public/ ./bin/web-client/

# Cria os arquivos de dados necessários
RUN mkdir -p data
RUN touch data/proxies.txt data/uas.txt

# Expõe a porta que o servidor roda
EXPOSE 3000

# Variáveis de ambiente
ENV ALLOW_NO_PROXY=true
# Como o Render mapeia portas pela env PORT, se for o caso o ideal é a aplicação suportar, 
# mas o Render também detecta a porta exposta pelo Dockerfile (3000).

# Roda o servidor
CMD ["./bin/mmb-server"]
