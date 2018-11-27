HOSTS := git.code.sf.net svn.code.sf.net
AWSENV = env $$(cat awsconfig)

.PHONY: build run-local run-s3 shell

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

repo:
	$(info Put a local copy of the git repo to be synced in ./repo/NAME)
	$(error ./repo not found)

run-local: | awsconfig repo
	$(AWSENV) docker-compose run -v "$(PWD)/repo:/repo" --rm sync

run-s3: | awsconfig
	$(AWSENV) docker-compose run --rm sync

shell: | awsconfig
	$(AWSENV) docker-compose run --entrypoint /bin/sh --rm sync
