REGISTRY := alleninstitute
BASENAME := mies-igor/docu
IMAGE    := ${REGISTRY}/${BASENAME}
TAG      := latest

LOCAL_TOP_LEVEL := $(shell git rev-parse --show-toplevel)
REMOTE_ROOT := /build
ROOT        := -v ${LOCAL_TOP_LEVEL}:${REMOTE_ROOT}
LINKDIR     := ${ROOT}
COMMAND     := /bin/bash
DOCKERFILE  = .

.PHONY : default all build doxygen shell

default: | all
all:
	$(MAKE) build
	$(MAKE) doxygen


build:
	docker build --tag ${IMAGE}:${TAG} ${DOCKERFILE}

doxygen: COMMAND := /bin/bash -c 'cd ${REMOTE_ROOT} && ${REMOTE_ROOT}/tools/build-documentation.sh'
doxygen: shell
shell:
	docker run --rm -it ${LINKDIR} ${IMAGE}:${TAG} ${COMMAND}
