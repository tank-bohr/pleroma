.DEFAULT_GOAL := app
.PHONY: app app-setup run-consumer clean

app:
	docker-compose run --rm --service-ports app sh

psql:
	docker-compose run --rm postgres psql --host=postgres --username=pleroma --password --dbname=pleroma

app-setup:
	docker-compose run --rm app mix do deps.get, compile

run-consumer:
	docker-compose up -d consumer
	docker-compose logs -f consumer

clean:
	docker-compose down
	rm -rf .postgres_data
	rm -rf .neo4j_data

#### Debezium setup
.PHONY: start-debezium register-connector check-connector review-connector remove-connector watch

watch:
	# See https://debezium.io/documentation/reference/1.6/connectors/postgresql.html#postgresql-topic-names for details
	docker-compose run --rm -e "KAFKA_BROKER=kafka:9092" kafka watch-topic -a -k dbserver1.public.users

start-debezium:
	docker-compose up -d connect

register-connector: connector.json
	curl --include \
		--header "Accept: application/json" \
		--header "Content-Type: application/json" \
		--data @connector.json \
		http://localhost:8083/connectors/

check-connector:
	curl -s -H "Accept: application/json" http://localhost:8083/connectors/ | jq .

review-connector:
	curl -s -H "Accept: application/json" http://localhost:8083/connectors/main-connector | jq .

remove-connector:
	curl -v -H "Accept: application/json" -X DELETE http://localhost:8083/connectors/main-connector | jq .

#### Postgres setup
.PHONY: start-postgres setup-postgres ecto-setup ecto-seeds

start-postgres:
	docker-compose up -d postgres

setup-postgres:
	docker-compose exec postgres psql -U pleroma -c "CREATE EXTENSION IF NOT EXISTS citext;"
	docker-compose exec postgres psql -U pleroma -c "ALTER SYSTEM SET wal_level=logical;"
	docker-compose restart postgres

ecto-setup: app-setup config/dev.secret.exs
	docker-compose run --rm app mix do ecto.create, ecto.migrate

ecto-reset: app-setup config/dev.secret.exs
	docker-compose run --rm app mix ecto.reset

ecto-seeds:
	docker-compose run --rm app mix do run priv/repo/seeds.exs

config/dev.secret.exs: secret.exs
	cp secret.exs config/dev.secret.exs

#### Neo4j
.PHONY: neo4j

neo4j:
	open http://localhost:7474
