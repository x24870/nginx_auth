.PHONY: up

up:
	docker-compose up

docker:
	docker image build -t auth_server ./auth_server
