SHELL := /bin/bash -O extglob

HOSTS := git.code.sf.net svn.code.sf.net
AWS_ARGS :=
AWS = aws $(AWS_ARGS)
AWS_GET = $(AWS) configure get
AWS_ACCOUNT_ID = $(shell $(AWS) sts get-caller-identity --query 'Account' --output text)
AWS_REGION = $(shell $(AWS_GET) region)
AWSENV = AWS_ACCESS_KEY_ID=$(shell $(AWS_GET) aws_access_key_id) \
  AWS_SECRET_ACCESS_KEY=$(shell $(AWS_GET) aws_secret_access_key) \
  AWS_DEFAULT_REGION=$(AWS_REGION)


id_rsa:
	ssh-keygen -t rsa -N "" -f $@

known_hosts:
	ssh-keyscan $(HOSTS) > $@

.PHONY: build
build: | id_rsa known_hosts
	docker-compose build

repo:
	$(info Put a local copy of the git repo to be synced in ./repo/NAME)
	$(error ./repo not found)

.PHONY: run-local
run-local: | repo
	@$(AWSENV) docker-compose run -v "$(PWD)/repo:/repo" --rm sync

.PHONY: run-s3
run-s3:
	@$(AWSENV) docker-compose run --rm sync

.PHONY: shell
shell:
	@$(AWSENV) docker-compose run -v "$(PWD)/repo:/repo" --entrypoint /bin/sh --rm sync

AWS_ECR_TAG = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/omegat/git-svn-sync

.PHONY: deploy
deploy:
	$$($(AWS) ecr get-login --no-include-email)
	TAG=$(AWS_ECR_TAG); \
		docker tag git-svn-sync:latest $$TAG; \
		docker push $$TAG

LAMBDA_TRIGGER := OmegatGitSvnSyncFunction
LAMBDA_AUTH := OmegatGitSvnSyncAuthorizerFunction

lambda_trigger.zip: lambda_trigger.py
	rm -rf $(@)
	zip $(@) $(^) -x \*.pyc

auth_secret:
	$(info Put the webhook secret into ./auth_secret)
	$(error ./auth_secret not found)

lambda_auth.zip: lambda_auth.py auth_secret
	rm -rf $(@)
	zip $(@) $(^) -x \*.pyc

AWS_LAMBDA_UPDATE = $(AWS) lambda update-function-code \
	--function-name $1 \
	--zip-file fileb://$$(pwd)/$(<)

.PHONY: deploy-trigger
deploy-trigger: lambda_trigger.zip
	$(call AWS_LAMBDA_UPDATE,$(LAMBDA_TRIGGER))

.PHONY: deploy-auth
deploy-auth: lambda_auth.zip
	$(call AWS_LAMBDA_UPDATE,$(LAMBDA_AUTH))

AWS_LAMBDA_INVOKE = $(AWS) lambda invoke --function-name $1 /dev/null

.PHONY: invoke-trigger
invoke-trigger:
	$(call AWS_LAMBDA_UPDATE,$(LAMBDA_TRIGGER))

.PHONY: invoke-auth
invoke-auth:
	$(call AWS_LAMBDA_UPDATE,$(LAMBDA_AUTH))
