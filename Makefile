#!make

DOCKER_BUILDX_OUTPUT ?= type=registry
DOCKER_BUILDX_PLATFORM ?= linux/amd64
CTR_REGISTRY = cybwan

.PHONY: buildx-context
buildx-context:
	@if ! docker buildx ls | grep -q "^fsm "; then docker buildx create --name fsm --driver-opt network=host; fi


.PHONY: package-consumer
package-consumer:
	@cd cloud-consumer;mvn clean package -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: clean-consumer
clean-consumer:
	@cd cloud-consumer;mvn clean

.PHONY: run-consumer
run-consumer:
	@java -jar cloud-consumer/target/cloud-consumer-1.0.0.jar


.PHONY: package-consumer-feign
package-consumer-feign:
	@cd cloud-consumer-feign;mvn clean package -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: clean-consumer-feign
clean-consumer-feign:
	@cd cloud-consumer-feign;mvn clean

.PHONY: run-consumer-feign
run-consumer-feign:
	@java -jar cloud-consumer-feign/target/cloud-consumer-feign-1.0.0.jar


.PHONY: package-consumer-feign-hystrix
package-consumer-feign-hystrix:
	@cd cloud-consumer-feign-hystrix;mvn clean package -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: clean-consumer-feign-hystrix
clean-consumer-feign-hystrix:
	@cd cloud-consumer-feign-hystrix;mvn clean

.PHONY: run-consumer-feign-hystrix
run-consumer-feign-hystrix:
	@java -jar cloud-consumer-feign-hystrix/target/cloud-consumer-feign-hystrix-1.0.0.jar


.PHONY: package-provider1
package-provider1:
	@cd cloud-provider1;mvn clean package -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: clean-provider1
clean-provider1:
	@cd cloud-provider1;mvn clean

.PHONY: run-provider1
run-provider1:
	@java -jar cloud-provider1/target/cloud-provider1-1.0.0.jar


.PHONY: package-provider2
package-provider2:
	@cd cloud-provider2;mvn clean package -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: clean-provider2
clean-provider2:
	@cd cloud-provider2;mvn clean

.PHONY: run-provider2
run-provider2:
	@java -jar cloud-provider2/target/cloud-provider2-1.0.0.jar


.PHONY: package-server-eureka
package-server-eureka:
	@cd cloud-server-eureka;mvn clean package -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: clean-server-eureka
clean-server-eureka:
	@cd cloud-server-eureka;mvn clean

.PHONY: run-server-eureka
run-server-eureka:
	@java -jar cloud-server-eureka/target/cloud-server-eureka-1.0.0.jar


.PHONY: package-zuul
package-zuul:
	@cd cloud-zuul;mvn clean package -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: clean-zuul
clean-zuul:
	@cd cloud-zuul;mvn clean

.PHONY: run-zuul
run-zuul:
	@java -jar cloud-zuul/target/cloud-zuul-1.0.0.jar

.PHONY: package
package:
	@mvn clean package -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: clean
clean:
	@mvn clean -Dmaven.test.skip=true -Dmaven.plugin.validation=BRIEF

.PHONY: docker-build-server-eureka
docker-build-server-eureka: package-server-eureka
	docker buildx build --builder fsm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) \
	-t $(CTR_REGISTRY)/spring-eureka-demo:server-eureka \
	-f dockerfiles/Dockerfile.server-eureka .

.PHONY: docker-build-consumer
docker-build-consumer: package-consumer
	docker buildx build --builder fsm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) \
	-t $(CTR_REGISTRY)/spring-eureka-demo:consumer \
	-f dockerfiles/Dockerfile.consumer .

.PHONY: docker-build-provider1
docker-build-provider1: package-provider1
	docker buildx build --builder fsm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) \
	-t $(CTR_REGISTRY)/spring-eureka-demo:provider1 \
	-f dockerfiles/Dockerfile.provider1 .

.PHONY: docker-build-provider2
docker-build-provider2: package-provider2
	docker buildx build --builder fsm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) \
	-t $(CTR_REGISTRY)/spring-eureka-demo:provider2 \
	-f dockerfiles/Dockerfile.provider2 .

SERVICE_TARGETS = server-eureka consumer provider1 provider2
DOCKER_SERVICE_TARGETS = $(addprefix docker-build-, $(SERVICE_TARGETS))

.PHONY: $(DOCKER_SERVICE_TARGETS)
$(DOCKER_SERVICE_TARGETS): NAME=$(@:docker-build-%=%)

.PHONY: docker-build
docker-build: buildx-context clean $(DOCKER_SERVICE_TARGETS)

.PHONY: docker-build-cross
docker-build-cross: DOCKER_BUILDX_PLATFORM=linux/amd64,linux/arm64
docker-build-cross: docker-build


.PHONY: deploy-eureka
deploy-eureka:
	kubectl apply -n disco -f deploy/eureka.yml

.PHONY: undeploy-eureka
undeploy-eureka:
	kubectl delete -n disco -f deploy/eureka.yml

.PHONY: deploy-provider1
deploy-provider1:
	kubectl apply -n cloud -f deploy/provider1.yml

.PHONY: undeploy-provider1
undeploy-provider1:
	kubectl delete -n cloud -f deploy/provider1.yml

.PHONY: deploy-provider2
deploy-provider2:
	kubectl apply -n cloud -f deploy/provider2.yml

.PHONY: undeploy-provider2
undeploy-provider2:
	kubectl delete -n cloud -f deploy/provider2.yml

.PHONY: deploy-consumer
deploy-consumer:
	kubectl apply -n cloud -f deploy/consumer.yml

.PHONY: undeploy-consumer
undeploy-consumer:
	kubectl delete -n cloud -f deploy/consumer.yml

.PHONY: deploy-curl
deploy-curl:
	kubectl apply -n cloud -f deploy/curl.yml

.PHONY: undeploy-curl
undeploy-curl:
	kubectl delete -n cloud -f deploy/curl.yml

.PHONY: deploy-ns
deploy-ns:
	kubectl create namespace disco
	kubectl create namespace cloud

.PHONY: undeploy-ns
undeploy-ns:
	kubectl delete namespace disco
	kubectl delete namespace cloud

.PHONY: deploy
deploy: deploy-ns deploy-eureka deploy-provider1 deploy-provider2 deploy-consumer deploy-curl

.PHONY: undeploy
undeploy: undeploy-eureka undeploy-provider1 undeploy-provider2 undeploy-consumer undeploy-curl undeploy-ns

.PHONY: port-forward-eureka
port-forward-eureka:
	@scripts/port-forward-eureka.sh

.PHONY: test
test:
	@scripts/test-curl.sh