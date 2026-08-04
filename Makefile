.PHONY: help up-dev down-dev ps logs build-java test-java build-camel test-camel run-control run-adapter run-camel run-camel-datdai console-dev typegen test-opa e2e-thin at-ph04 ci-local

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COMPOSE := docker compose --env-file $(ROOT)/.env -f $(ROOT)/deploy/compose/docker-compose.yml
MVN := mvn -f $(ROOT)/pom.xml
CAMEL_MVN := mvn -f $(ROOT)/camel/dancu/pom.xml
CAMEL_DATDAI_MVN := mvn -f $(ROOT)/camel/datdai/pom.xml

help:
	@echo "LGSP DEV targets:"
	@echo "  make up-dev       - start Postgres Valkey Garage Keycloak Mailpit"
	@echo "  make down-dev     - stop compose"
	@echo "  make ps / logs    - status / follow logs"
	@echo "  make build-java   - compile libs + control"
	@echo "  make test-java    - unit/modulith tests"
	@echo "  make build-camel  - Camel Quarkus dancu + datdai (JVM)"
	@echo "  make run-control  - spring-boot:run apps/control"
	@echo "  make run-adapter  - spring-boot:run apps/adapter-mgr"
	@echo "  make run-camel    - quarkus:dev camel/dancu"
	@echo "  make run-camel-datdai - quarkus:dev camel/datdai :8087"
	@echo "  make console-dev  - Vite console"
	@echo "  make typegen      - OpenAPI → TS types"
	@echo "  make e2e-thin     - WP-16 thin-slice script"
	@echo "  make at-ph04      - WP-26 AT lõi PH-04 (≥10)"
	@echo "  make test-opa     - opa test (nếu có opa CLI)"
	@echo "  make ci-local     - Gate A tối thiểu"

up-dev:
	@test -f $(ROOT)/.env || cp $(ROOT)/.env.example $(ROOT)/.env
	$(COMPOSE) up -d
	@echo "Keycloak   http://localhost:$${KEYCLOAK_PORT:-8081} (admin/admin_dev_change_me)"
	@echo "Mailpit    http://localhost:$${MAILPIT_UI_PORT:-8025}"
	@echo "Garage S3  http://localhost:$${GARAGE_S3_PORT:-3900}"
	@echo "Seaweed S3 http://localhost:$${SEAWEED_S3_PORT:-8333} (WORM audit)"
	@echo "Garage layout lần đầu: xem deploy/README.md § Garage bootstrap"

down-dev:
	$(COMPOSE) down

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=200

build-java:
	$(MVN) -q -DskipTests package

test-java:
	$(MVN) -q test

build-camel:
	$(CAMEL_MVN) -q -DskipTests package
	$(CAMEL_DATDAI_MVN) -q -DskipTests package

test-camel:
	$(CAMEL_MVN) -q test
	$(CAMEL_DATDAI_MVN) -q test

run-control:
	LGSP_APISIX_ROUTES_DIR=$(ROOT)/deploy/apisix/routes \
	OIDC_ISSUER_URI=http://localhost:8081/realms/lgsp \
	$(MVN) -pl apps/control spring-boot:run

run-adapter:
	$(MVN) -pl apps/adapter-mgr spring-boot:run

run-camel:
	$(CAMEL_MVN) quarkus:dev

run-camel-datdai:
	$(CAMEL_DATDAI_MVN) quarkus:dev

e2e-thin:
	bash $(ROOT)/tests/e2e/thin-slice.sh

at-ph04:
	bash $(ROOT)/tests/at/ph04/run.sh

console-dev:
	cd $(ROOT)/apps/console && npm install && npm run dev

typegen:
	cd $(ROOT)/apps/console && npm install && npm run typegen

test-opa:
	@command -v opa >/dev/null || { echo "Cài opa: https://www.openpolicyagent.org/docs/latest/#running-opa"; exit 1; }
	opa test $(ROOT)/contracts/opa -v

ci-local: test-java test-camel
	@echo "Gate A local OK (gitleaks chạy trên CI)"
