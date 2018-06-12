VERSION           ?= v0.1.1
COMMIT            ?= $(shell git rev-parse --short HEAD)
IMAGE_NAME        ?= grapeshot/vault_exporter
DOCKER_IMAGE      ?= $(IMAGE_NAME):$(COMMIT)

ECR								?= 163537733247.dkr.ecr.eu-west-1.amazonaws.com
ECR_IMAGE         ?= $(ECR)/$(IMAGE_NAME):$(COMMIT)
ECR_LOGIN_COMMAND := "eval $$\( aws ecr --profile jenkins get-login --no-include-email \)"

HUB_CREDENTIALS   ?= username:password
HUB_SUBST         ?= $(subst :, ,$(HUB_CREDENTIALS))
HUB_USERNAME      ?= $(word 1, $(HUB_SUBST))
HUB_PASSWORD      ?= $(word 2, $(HUB_SUBST))

GO                ?= go
GOFMT             ?= $(GO)fmt
GOOS              ?= linux
GOARCH            ?= amd64

build:
	env GOOS=$(GOOS) GOARCH=$(GOARCH) go build -o _output/bin/vault_exporter-$(VERSION).$(GOOS)-$(GOARCH)
	ln -s vault_exporter-$(VERSION).$(GOOS)-$(GOARCH) ./_output/bin/vault_exporter
.PHONY: build

build-image:
	docker build -t $(DOCKER_IMAGE) .
	docker tag $(DOCKER_IMAGE) $(ECR_IMAGE)
.PHONY: build-image

clean:
	rm -rf _output
.PHONY: clean

ecr-login:
	@eval $(ECR_LOGIN_COMMAND)
.PHONY: ecr-login

ecr-push: ecr-login
	docker push $(ECR_IMAGE)
	docker tag $(DOCKER_IMAGE) $(ECR)/$(IMAGE_NAME):$(VERSION)
	docker push $(ECR)/$(IMAGE_NAME):$(VERSION)
.PHONY: ecr-login

ecr-release: ecr-login
	docker tag $(DOCKER_IMAGE) $(ECR)/$(IMAGE_NAME):$(VERSION)
	docker push $(ECR)/$(IMAGE_NAME):$(VERSION)
.PHONY: ecr-release

hub-login:
	docker login --username=$(HUB_USERNAME) --password=$(HUB_PASSWORD)
.PHONY: hub-login

hub-push: hub-login
	docker push $(DOCKER_IMAGE)
.PHONY: hub-push

hub-release: hub-login
	docker tag $(DOCKER_IMAGE) $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):$(VERSION)
.PHONY: hub-release

format:
	$(GOFMT) -s -w .
.PHONY: format

lint:
	# To install gometalinter
	# `go get -u gopkg.in/alecthomas/gometalinter.v2`
	# `gometalinter.v2 --install`
	gometalinter.v2 --vendor --deadline=5m
.PHONY: lint

release: ecr-release hub-release

update-dependencies:
	dep ensure
.PHONY: update-vendor
