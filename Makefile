IMAGENAME := meidokon-moin
DATADIR := /root/git/moinmoin-wiki-docker/datavol
HTTP_PORT := 8000

build:
	docker build -t $(IMAGENAME) .

run:
	docker run -d -p $(HTTP_PORT):80 -v $(DATADIR):/usr/local/share/moin/data $(IMAGENAME)
