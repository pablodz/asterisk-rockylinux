MICROSERVICE_NAME=pablogod/asterisk-rockylinux:latest

build:
	docker build -t $(MICROSERVICE_NAME) .
release:
	docker --config ~/.docker/personal push $(MICROSERVICE_NAME)
run: build
	docker run -it  \
		--network host \
		--restart always \
		$(MICROSERVICE_NAME)

build-and-release: build release
