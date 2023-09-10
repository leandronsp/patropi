SHELL = /bin/bash
.ONESHELL:
.DEFAULT_GOAL: help

help: ## Prints available commands
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[.a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

rinha.setup: ## Setup
	@docker compose run ruby bundle
	@cargo install rinha

rinha.run: ## Run interpreter from STDIN
	@docker compose run --rm --no-TTY ruby ruby patropi.rb

rinha.hello: ## Run a sample hello world
	@rinha examples/hello.rinha | jq | tee examples/hello.json | make rinha.run
