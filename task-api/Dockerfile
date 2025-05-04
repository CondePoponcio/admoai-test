# Stage 1: Build with Go 1.24.2
FROM golang:1.24.2-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o task-api ./cmd/server


# Stage 2: Minimal runtime image
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/task-api .
EXPOSE 8080
ENTRYPOINT ["./task-api"]
