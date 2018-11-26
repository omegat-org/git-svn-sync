HOSTS := git.code.sf.net svn.code.sf.net

.PHONY: build run shell

id_rsa:
	ssh-keygen -t rsa -N "" -f $@

known_hosts:
	ssh-keyscan $(HOSTS) > $@

build: | id_rsa known_hosts
	docker-compose build

run:
	docker-compose run --rm sync

shell:
	docker-compose run --entrypoint /bin/sh --rm sync
