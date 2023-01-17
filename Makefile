.DEFAULT_GOAL := help
SHELL := /bin/bash

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

docker-build-backend: ## Build the backend app
	@docker build -t fsteccanella/todo-app-backend ./backend

docker-build-frontend: ## Build the frontend app
	@docker build -t fsteccanella/todo-app-frontend ./frontend

docker-build: ## Build all the apps
	@$(MAKE) docker-build-backend
	@$(MAKE) docker-build-frontend

docker-push-backend: ## Push the backend app
	@docker push fsteccanella/todo-app-backend

docker-push-frontend: ## Push the frontend app
	@docker push fsteccanella/todo-app-frontend

docker-push: ## Push all the apps
	@$(MAKE) docker-push-backend
	@$(MAKE) docker-push-frontend

docker-run-mongo: ## Start MongoDB
	@docker run -it --rm -p 27017:27017 mongo:4.2

docker-run-backend: guard-MONGO_SERVER ## Start backend app
	@docker run -it --rm -e API_PORT=3000 -e MONGO_SERVER=$(MONGO_SERVER) -p 3000:3000 --name todo-backend fsteccanella/todo-app-backend

docker-run-frontend: guard-TODO_API_SERVER ## Start frontend app
	@docker run -it --rm -e TODO_API_SERVER=$(TODO_API_SERVER) -p 8080:80 fsteccanella/todo-app-frontend

####################

docker-compose-build: ## Build all the apps with docker compose
	@docker compose build

docker-compose-push: ## Push all the apps with docker compose
	@docker compose push

docker-compose-start: ## Start the docker compose stack
	@docker compose up

####################

k8s-minikube-start: ## Start minikiube cluster
	@minikube start

k8s-minikube-addons: k8s-minikube-start ## Enable ingress and metrics on minkube
	@minikube addons enable ingress
	@minikube addons enable metrics-server

k8s-deploy-mongo: ## Deploy MongoDB manually
	@kubectl apply -f ./_db/_k8s/statefulset.yaml -f ./_db/_k8s/service.yaml 

k8s-deploy-mongo-helm: ## Deploy MongoDB with Helm (https://github.com/bitnami/charts/tree/main/bitnami/mongodb/#installing-the-chart)
	@helm repo add bitnami https://charts.bitnami.com/bitnami
	@helm upgrade --install todo-app-db bitnami/mongodb --set auth.enabled=false --set architecture=replicaset --set service.nameOverride=mongodb

k8s-deploy-backend: ## Deploy backend app
	@kubectl apply -f ./backend/_k8s/deployment.yaml -f ./backend/_k8s/service.yaml -f ./backend/_k8s/hpa.yaml

k8s-deploy-frontend: ## Deploy frontend app
	@kubectl apply -f ./frontend/_k8s/deployment.yaml -f ./frontend/_k8s/service.yaml -f ./frontend/_k8s/ingress.yaml

k8s-break-frontend-proxy: ## Break frontend proxy (Demo)
	@kubectl patch deployment todo-app-frontend --patch-file ./frontend/_k8s/patches/break-proxy.yaml

k8s-deploy-backend-ingress: ## Deploy dedicated backend ingress
	@kubectl apply -f ./backend/_k8s/ingress.yaml 


####################

load-test:
	@ab -n 1000000  "http://todo-app.example.local/api/todos"	

####################

help: ## Show this help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'