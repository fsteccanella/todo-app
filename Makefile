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

k8s-minikube-start: ## Start minikiube cluster (use --driver=hyperv on win)	
	@minikube start

k8s-minikube-addons: k8s-minikube-start ## Enable ingress and metrics on minkube
	@minikube addons enable ingress
	@minikube addons enable metrics-server

k8s-deploy-ns:
	@kubectl create ns todo --dry-run=client -o yaml | kubectl apply -f -
	@kubectl config set-context --current --namespace=todo

k8s-deploy-mongo: ## Deploy MongoDB manually
	@kubectl apply -f ./_db/_k8s

k8s-deploy-backend: ## Deploy backend app
	@kubectl apply -f ./backend/_k8s

k8s-deploy-frontend: ## Deploy frontend app
	@kubectl apply -f ./frontend/_k8s

k8s-deploy-todo: k8s-deploy-ns## Deploy todo app
	@kubectl config set-context --current --namespace=todo
	@$(MAKE) k8s-deploy-mongo
	@$(MAKE) k8s-deploy-backend
	@$(MAKE) k8s-deploy-frontend
	@kubectl create ingress todo-app-backend --rule=todo-app.example.local/api/todos*=todo-app-backend:3000 --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create ingress todo-app-frontend --rule=todo-app.example.local/*=todo-app-frontend:80 --dry-run=client -o yaml | kubectl apply -f -

####################

helm-deploy-ns:
	@kubectl create ns todo-helm --dry-run=client -o yaml | kubectl apply -f -
	@kubectl config set-context --current --namespace=todo-helm

helm-deploy-mongo: helm-deploy-ns ## Deploy MongoDB with Helm
	@helm repo add bitnami https://charts.bitnami.com/bitnami
	@helm upgrade --install todo-app-db bitnami/mongodb --set auth.enabled=false --set architecture=replicaset

####################

istio-build-frontend-red: ## Build the red frontend app
	@echo "body { background: red; }" > ./frontend/public/theme.css
	@docker build -t fsteccanella/todo-app-frontend:red ./frontend
	@echo "" > ./frontend/public/theme.css

istio-push-frontend-red: ## Push the frontend app
	@docker push fsteccanella/todo-app-frontend:red

istio-setup: ## Install Istio with istioctl
	@curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.16.1 TARGET_ARCH=x86_64 sh -
	@./istio-1.16.1/bin/istioctl install -y
	@kubectl apply -f ./istio-1.16.1/samples/addons/prometheus.yaml
	@kubectl apply -f ./istio-1.16.1/samples/addons/kiali.yaml
	@rm -rf ./istio-1.16.1

istio-deploy-ns:
	@kubectl create ns todo-istio --dry-run=client -o yaml | kubectl apply -f -
	@kubectl config set-context --current --namespace=todo-istio
	@$(MAKE) istio-label-ns

istio-label-ns: ## Label todo namespace for istio sidecar injection
	@kubectl label namespace todo-istio istio-injection=enabled

istio-deploy-mongo: ## Deploy MongoDB manually
	@kubectl apply -f ./_db/_k8s

istio-deploy-backend: ## Deploy backend app
	@kubectl apply -f ./backend/_k8s

istio-deploy-frontend: ## Deploy frontend app
	@kubectl apply -f ./frontend/_k8s

istio-deploy-frontend-red: ## Deploy the frontend app
	@kubectl apply -f ./frontend/_k8s/red

istio-deploy-todo: ## Deploy istio components to show canary deploy	
	@kubectl config set-context --current --namespace=todo-istio
	@$(MAKE) istio-deploy-mongo
	@$(MAKE) istio-deploy-backend
	@$(MAKE) istio-deploy-frontend
	@$(MAKE) istio-deploy-frontend-red
	@kubectl apply -f ./_istio

####################

load-test: ## Perform load test
	@ab -n 1000000  "http://todo-app.example.local/api/todos"	

####################

help: ## Show this help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'