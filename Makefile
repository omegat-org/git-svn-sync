HOSTS := git.code.sf.net svn.code.sf.net
AWSENV = env $$(cat awsconfig)

.PHONY: build run shell

id_rsa:
	ssh-keygen -t rsa -N "" -f $@

known_hosts:
	ssh-keyscan $(HOSTS) > $@

build: | id_rsa known_hosts
	docker-compose build

define AWSCONFIG_TEMPLATE
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=
endef

awsconfig:
	$(info Put these values into a file ./awsconfig:)
	$(info $(AWSCONFIG_TEMPLATE))
	$(error ./awsconfig not found)

run: | awsconfig
	$(AWSENV) docker-compose run -v "$(PWD)/repo:/repo" --rm sync

shell: | awsconfig
	$(AWSENV) docker-compose run --entrypoint /bin/sh --rm sync
