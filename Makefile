.PHONY: up

up:
	docker-compose up

certs:
	./gencerts.sh

docker:
	docker image build -t auth_server ./auth_server
