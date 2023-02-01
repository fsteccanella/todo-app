.DEFAULT_GOAL := help
SHELL := /bin/bash

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

_docker-build-backend: ## Build the backend app
	@docker build -t fsteccanella/todo-app-backend ./backend

_docker-build-frontend: ## Build the frontend app
	@docker build -t fsteccanella/todo-app-frontend ./frontend

docker-build: ## Build all the apps
	@$(MAKE) _docker-build-backend
	@$(MAKE) _docker-build-frontend

_docker-push-backend: ## Push the backend app
	@docker push fsteccanella/todo-app-backend

_docker-push-frontend: ## Push the frontend app
	@docker push fsteccanella/todo-app-frontend

docker-push: ## Push all the apps
	@$(MAKE) _docker-push-backend
	@$(MAKE) _docker-push-frontend

docker-run-mongo: ## Start MongoDB
	@docker run -it --rm -p 27017:27017 mongo:4.2

docker-run-backend: guard-MONGO_SERVER ## Start backend app
	@docker run -it --rm -e API_PORT=3000 -e MONGO_SERVER=$(MONGO_SERVER) -p 3000:3000 --name todo-backend fsteccanella/todo-app-backend

docker-run-frontend: guard-TODO_API_SERVER ## Start frontend app
	@docker run -it --rm -e TODO_API_SERVER=$(TODO_API_SERVER) -p 8080:80 fsteccanella/todo-app-frontend

####################

_docker-compose-build: ## Build all the apps with docker compose
	@docker compose build

_docker-compose-push: ## Push all the apps with docker compose
	@docker compose push

docker-compose-start: ## Start the docker compose stack
	@docker compose up

####################

k8s-minikube-start: ## Start minikiube cluster (use --driver=hyperv on win)	
	@minikube start
	@minikube addons enable ingress
	@minikube addons enable metrics-server

_k8s-deploy-ns: ## Deploy todo namespace
	@kubectl create ns todo --dry-run=client -o yaml | kubectl apply -f -
	@kubectl config set-context --current --namespace=todo

_k8s-deploy-mongo: ## Deploy MongoDB manually
	@kubectl apply -f ./_db/_k8s

_k8s-deploy-backend: ## Deploy backend app
	@kubectl apply -f ./backend/_k8s

_k8s-deploy-frontend: ## Deploy frontend app
	@kubectl apply -f ./frontend/_k8s

k8s-deploy-todo: _k8s-deploy-ns ## Deploy the todo app
	@kubectl config set-context --current --namespace=todo
	@$(MAKE) _k8s-deploy-mongo
	@$(MAKE) _k8s-deploy-backend
	@$(MAKE) _k8s-deploy-frontend
	@kubectl create ingress todo-app-backend --rule=todo-app.example.local/api/todos*=todo-app-backend:3000 --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create ingress todo-app-frontend --rule=todo-app.example.local/*=todo-app-frontend:8080 --dry-run=client -o yaml | kubectl apply -f -
	@echo 
	@echo "To-Do App accessible at todo-app.example.local"

####################

_helm-deploy-ns: ## Deploy todo-helm namespace
	@kubectl create ns todo-helm --dry-run=client -o yaml | kubectl apply -f -
	@kubectl config set-context --current --namespace=todo-helm

_helm-deploy-mongo: _helm-deploy-ns ## Deploy MongoDB with Helm
	@helm repo add bitnami https://charts.bitnami.com/bitnami
	@helm upgrade --install todo-app-db bitnami/mongodb --set auth.enabled=false --set architecture=replicaset --set service.nameOverride=mongodb

_helm-deploy-backend: ## Deploy backend app
	@kubectl apply -f ./backend/_k8s

_helm-deploy-frontend: ## Deploy frontend app
	@kubectl apply -f ./frontend/_k8s

helm-deploy-todo: _helm-deploy-ns ## Deploy the todo app
	@kubectl config set-context --current --namespace=todo-helm
	@$(MAKE) _helm-deploy-mongo
	@$(MAKE) _helm-deploy-backend
	@$(MAKE) _helm-deploy-frontend
	@kubectl create ingress todo-app-backend --rule=todo-app-helm.example.local/api/todos*=todo-app-backend:3000 --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create ingress todo-app-frontend --rule=todo-app-helm.example.local/*=todo-app-frontend:8080 --dry-run=client -o yaml | kubectl apply -f -
	@echo 
	@echo "To-Do App accessible at todo-app-helm.example.local"


####################

_istio-build-frontend-red: ## Build the red frontend app
	@sed -i "s/theme\.css/theme-red\.css/g" ./frontend/public/index.html
	@docker build -t fsteccanella/todo-app-frontend:red ./frontend
	@sed -i "s/theme\-red.css/theme\.css/g" ./frontend/public/index.html

_istio-push-frontend-red: ## Push the frontend app
	@docker push fsteccanella/todo-app-frontend:red

istio-setup: ## Install Istio with istioctl
	@curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.16.1 TARGET_ARCH=x86_64 sh -
	@./istio-1.16.1/bin/istioctl install -y
	@kubectl apply -f ./istio-1.16.1/samples/addons/prometheus.yaml
	@kubectl apply -f ./istio-1.16.1/samples/addons/kiali.yaml
	@kubectl apply -f ./istio-1.16.1/samples/addons/jaeger.yaml
	@kubectl apply -f ./istio-1.16.1/samples/addons/grafana.yaml
	@rm -rf ./istio-1.16.1

_istio-deploy-ns: ## Deploy todo-istio namespace
	@kubectl create ns todo-istio --dry-run=client -o yaml | kubectl apply -f -
	@kubectl config set-context --current --namespace=todo-istio
	@$(MAKE) _istio-label-ns

_istio-label-ns: ## Label todo namespace for istio sidecar injection
	@kubectl label namespace todo-istio istio-injection=enabled

_istio-deploy-mongo: ## Deploy MongoDB manually
	@kubectl apply -f ./_db/_k8s

_istio-deploy-backend: ## Deploy backend app
	@kubectl apply -f ./backend/_k8s

_istio-deploy-frontend: ## Deploy frontend app
	@kubectl apply -f ./frontend/_k8s

_istio-deploy-frontend-red: ## Deploy the frontend app
	@kubectl apply -f ./frontend/_k8s/red

istio-deploy-todo: _istio-deploy-ns ## Deploy istio components to show canary deploy	
	@$(MAKE) _istio-deploy-mongo
	@$(MAKE) _istio-deploy-backend
	@$(MAKE) _istio-deploy-frontend
	@$(MAKE) _istio-deploy-frontend-red
	@kubectl apply -f ./_istio
	@echo 
	@echo "To-Do App accessible at todo-app-istio.example.local"

####################

k8s-load-test-backend: ## Perform load test
	@ab -n 1000000  "http://todo-app.example.local/api/todos"	

helm-load-test-backend: ## Perform load test
	@ab -n 1000000  "http://todo-app-helm.example.local/api/todos"	

istio-load-test-frontend: ## Perform load test
	@ab -n 1000000  "http://todo-app-istio.example.local/"	

####################

help: ## Show this help
	@grep -E '^[0-9a-zA-Z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'