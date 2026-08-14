.PHONY: run migrate

run: migrate
	go run ./app

migrate:
	goose up
