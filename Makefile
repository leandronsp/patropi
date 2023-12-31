SHELL = /bin/bash
.ONESHELL:
.DEFAULT_GOAL: help

help: ## Prints available commands
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[.a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

patropi.build: ## Build Patropi
	@docker build -t patropi .

patropi.hello: ## Run hello world
	@bin/patropi examples/hello.rinha

patropi.showcase: # Run showcase examples
	@bin/patropi examples/showcase.rinha

patropi.test: ## Run tests
	@bin/test

patropi.bench: ## Run benchmarks
	@bin/bench

patropi.check: ## Check everything is OK
	@bin/check

docker.push : ## Push docker image
	@docker build -t patropi .
	@docker tag patropi leandronsp/patropi
	@docker push leandronsp/patropi

docker.stats: ## Docker stats
	@docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
