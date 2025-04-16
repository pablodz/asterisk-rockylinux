MICROSERVICE_NAME=asteriskdocker

build:
	docker build -t $(MICROSERVICE_NAME)-$(tag) .
release:
	docker --config ~/.docker/vozy push $(MICROSERVICE_NAME)-$(tag)
run: build
	docker run -it  \
		--network host \
		--restart always \
		$(MICROSERVICE_NAME)-$(tag)

build-and-release: build release 
