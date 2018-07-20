team: engineering-enablement
pipeline: docker-vault-exporter
tasks:
- type: docker-push
  name: vault-exporter
  image: eu.gcr.io/halfpipe-io/vault-exporter
