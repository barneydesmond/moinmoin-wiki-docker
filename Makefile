IMAGENAME := meidokon-moin
DATADIR := /root/git/moinmoin-wiki-docker/datavol
HTTP_PORT := 8000
RUNNING_CONTAINER_NAME := meidokon_wiki
TZ := Australia/Sydney
MOIN_UID := 1002
MOIN_GID := 1002

build:
	docker build -t $(IMAGENAME) .

run:
	-docker kill $(RUNNING_CONTAINER_NAME)
	sleep 2
	-docker container rm meidokon_wiki
	docker run -e TZ=$(TZ) -e MOIN_UID=$(MOIN_UID) -e MOIN_GID=$(MOIN_GID) -d -p $(HTTP_PORT):80 -v $(DATADIR):/usr/local/share/moin/data --name $(RUNNING_CONTAINER_NAME) $(IMAGENAME)

update: build run

shell:
	docker exec -it meidokon_wiki /bin/bash
