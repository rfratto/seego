REPOSITORY ?= rfratto/goop

all: build

build:
	docker build -t ${REPOSITORY} --build-arg OSXCROSS_SDK_URL=${OSXCROSS_SDK_URL} .

push:
	docker push ${REPOSITORY}:latest
