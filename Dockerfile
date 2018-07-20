FROM golang:1.10-alpine AS BUILDER
ADD . /go/src/github.com/springernature/vault_exporter
WORKDIR /go/src/github.com/springernature/vault_exporter
RUN go build -o /vault_exporter

FROM alpine:3.6
COPY --from=BUILDER /vault_exporter /usr/bin/vault_exporter
ENTRYPOINT ["/usr/bin/vault_exporter"]
