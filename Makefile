include Makefile.variables
# local-disk-manager build definitions
LDM_MODULE_NAME = local-disk-manager
LDM_BUILD_INPUT = ${CMDS_DIR}/${LDM_MODULE_NAME}/diskmanager.go

# local-storage build definitions
LS_MODULE_NAME = local-storage
LS_BUILD_INPUT = ${CMDS_DIR}/${LS_MODULE_NAME}/storage.go

# scheduler build definitions
SCHEDULER_MODULE_NAME = scheduler
SCHEDULER_BUILD_INPUT = ${CMDS_DIR}/${SCHEDULER_MODULE_NAME}/scheduler.go

# admission build definitions
ADMISSION_MODULE_NAME = admission
ADMISSION_BUILD_INPUT = ${CMDS_DIR}/${ADMISSION_MODULE_NAME}/admission.go

EVICTOR_MODULE_NAME = evictor
EVICTOR_BUILD_INPUT = ${CMDS_DIR}/${EVICTOR_MODULE_NAME}/main.go

METRICS_MODULE_NAME = metrics
METRICS_BUILD_INPUT = ${CMDS_DIR}/${METRICS_MODULE_NAME}/main.go

APISERVER_MODULE_NAME = apiserver
APISERVER_BUILD_INPUT = ${CMDS_DIR}/${APISERVER_MODULE_NAME}/main.go

.PHONY: debug
debug:
	${DOCKER_DEBUG_CMD} ash

SWAGGER_INCLUDE_DIRS = ${CMDS_DIR}/${APISERVER_MODULE_NAME} \
	pkg/${APISERVER_MODULE_NAME} \
	pkg/apis/hwameistor/v1alpha1 \
	vendor/k8s.io/apimachinery/pkg/apis/meta/v1 \
	vendor/k8s.io/apimachinery/pkg/types

comma:= ,
empty:=
space:= $(empty) $(empty)
SWAGGER_INPUT_DIRS = $(subst $(space),$(comma),${SWAGGER_INCLUDE_DIRS})

.PHONY: apiserver_swag
apiserver_swag:
	swag init --dir ${SWAGGER_INPUT_DIRS} --output ./pkg/${APISERVER_MODULE_NAME}/docs

.PHONY: apiserver_run
apiserver_run: apiserver_swag
	echo "Please browse at http://127.0.0.1/swagger/index.html"
	GIN_MODE=debug go run ${BUILD_OPTIONS} ${APISERVER_BUILD_INPUT}

.PHONY: compile
compile: compile_ldm compile_ls compile_scheduler compile_admission compile_evictor compile_metrics compile_apiserver

.PHONY: image
image: build_ldm_image build_ls_image build_scheduler_image build_admission_image build_evictor_image build_metrics_image build_apiserver_image


.PHONY: arm-image
arm-image: build_ldm_image_arm64 build_ls_image_arm64 build_scheduler_image_arm64 build_admission_image_arm64 build_evictor_image_arm64 build_metrics_image_arm64 build_apiserver_image_arm64


.PHONY: release
release: release_ldm release_ls release_scheduler release_admission release_evictor release_metrics release_apiserver

.PHONY: unit-test
unit-test:
	go test -race -coverprofile=coverage.txt -covermode=atomic `go list ./pkg/... | grep -v -E './pkg/local-storage/member|./pkg/scheduler|./pkg/evictor|./pkg/apiserver'`
	curl -s https://codecov.io/bash | bash

.PHONY: vendor
vendor:
	go mod tidy -compat=1.18
	go mod vendor

.PHONY: release_ldm
release_ldm:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_ldm
	${DOCKER_BUILDX_CMD_AMD64} -t ${LDM_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${LDM_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_ldm_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${LDM_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${LDM_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${LDM_IMAGE_NAME}:${RELEASE_TAG}

.PHONY: release_ls
release_ls:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_ls
	${DOCKER_BUILDX_CMD_AMD64} -t ${LS_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${LS_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_ls_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${LS_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${LS_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${LS_IMAGE_NAME}:${RELEASE_TAG}

.PHONY: release_scheduler
release_scheduler:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_scheduler
	${DOCKER_BUILDX_CMD_AMD64} -t ${SCHEDULER_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${SCHEDULER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_scheduler_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${SCHEDULER_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${SCHEDULER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${SCHEDULER_IMAGE_NAME}:${RELEASE_TAG}

.PHONY: release_admission
release_admission:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_admission
	${DOCKER_BUILDX_CMD_AMD64} -t ${ADMISSION_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${ADMISSION_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_admission_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${ADMISSION_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${ADMISSION_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${ADMISSION_IMAGE_NAME}:${RELEASE_TAG}

.PHONY: release_evictor
release_evictor:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_evictor
	${DOCKER_BUILDX_CMD_AMD64} -t ${EVICTOR_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${EVICTOR_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_evictor_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${EVICTOR_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${EVICTOR_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${EVICTOR_IMAGE_NAME}:${RELEASE_TAG}

.PHONY: release_metrics
release_metrics:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_metrics
	${DOCKER_BUILDX_CMD_AMD64} -t ${METRICS_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${METRICS_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_metrics_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${METRICS_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${METRICS_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${METRICS_IMAGE_NAME}:${RELEASE_TAG}

.PHONY: release_apiserver
release_apiserver:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_apiserver
	${DOCKER_BUILDX_CMD_AMD64} -t ${APISERVER_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${APISERVER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_apiserver_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${APISERVER_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${APISERVER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${APISERVER_IMAGE_NAME}:${RELEASE_TAG}


.PHONY: build_ldm_image
build_ldm_image:
	@echo "Build local-disk-manager image ${LDM_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_ldm
	docker build -t ${LDM_IMAGE_NAME}:${IMAGE_TAG} -f ${LDM_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_ls_image
build_ls_image:
	@echo "Build local-storage image ${LS_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_ls
	docker build -t ${LS_IMAGE_NAME}:${IMAGE_TAG} -f ${LS_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_scheduler_image
build_scheduler_image:
	@echo "Build scheduler image ${SCHEDULER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_scheduler
	docker build -t ${SCHEDULER_IMAGE_NAME}:${IMAGE_TAG} -f ${SCHEDULER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_admission_image
build_admission_image:
	@echo "Build admission image ${ADMISSION_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_admission
	docker build -t ${ADMISSION_IMAGE_NAME}:${IMAGE_TAG} -f ${ADMISSION_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_evictor_image
build_evictor_image:
	@echo "Build evictor image ${EVICTOR_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_evictor
	docker build -t ${EVICTOR_IMAGE_NAME}:${IMAGE_TAG} -f ${EVICTOR_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_metrics_image
build_metrics_image:
	@echo "Build metrics image ${METRICS_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_metrics
	docker build -t ${METRICS_IMAGE_NAME}:${IMAGE_TAG} -f ${METRICS_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}


.PHONY: build_apiserver_image
build_apiserver_image:
	@echo "Build hwameistor apiserver image ${APISERVER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_apiserver
	docker build -t ${APISERVER_IMAGE_NAME}:${IMAGE_TAG} -f ${APISERVER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}


.PHONY: build_ldm_image_arm64
build_ldm_image_arm64:
	@echo "Build local-disk-manager image ${LDM_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_ldm_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${LDM_IMAGE_NAME}:${IMAGE_TAG} -f ${LDM_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_ls_image_arm64
build_ls_image_arm64:
	@echo "Build local-storage image ${LS_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_ls_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${LS_IMAGE_NAME}:${IMAGE_TAG} -f ${LS_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_scheduler_image_arm64
build_scheduler_image_arm64:
	@echo "Build scheduler image ${SCHEDULER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_scheduler_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${SCHEDULER_IMAGE_NAME}:${IMAGE_TAG} -f ${SCHEDULER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_admission_image_arm64
build_admission_image_arm64:
	@echo "Build admission image ${ADMISSION_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_admission_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${ADMISSION_IMAGE_NAME}:${IMAGE_TAG} -f ${ADMISSION_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_evictor_image_arm64
build_evictor_image_arm64:
	@echo "Build evictor image ${EVICTOR_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_evictor_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${EVICTOR_IMAGE_NAME}:${IMAGE_TAG} -f ${EVICTOR_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_metrics_image_arm64
build_metrics_image_arm64:
	@echo "Build metrics image ${METRICS_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_metrics_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${METRICS_IMAGE_NAME}:${IMAGE_TAG} -f ${METRICS_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_apiserver_image_arm64
build_apiserver_image_arm64:
	@echo "Build hwameistor apiserver image ${APISERVER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_apiserver_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${APISERVER_IMAGE_NAME}:${IMAGE_TAG} -f ${APISERVER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}


.PHONY: apis
apis:
	${DOCKER_MAKE_CMD} make _gen-apis

.PHONY: builder
builder:
	docker build -t ${BUILDER_NAME}:${BUILDER_TAG} -f ${BUILDER_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	docker push ${BUILDER_NAME}:${BUILDER_TAG}

.PHONY: _gen-apis
_gen-apis:
	${OPERATOR_CMD} generate k8s
	${OPERATOR_CMD} generate crds
	GOPROXY=https://goproxy.cn,direct /code-generator/generate-groups.sh all github.com/hwameistor/hwameistor/pkg/apis/client github.com/hwameistor/hwameistor/pkg/apis "hwameistor:v1alpha1" --go-header-file /go/src/github.com/hwameistor/hwameistor/build/boilerplate.go.txt

.PHONY: compile_ldm
compile_ldm:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${LDM_BUILD_OUTPUT} ${LDM_BUILD_INPUT}

.PHONY: compile_ldm_arm64
compile_ldm_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${LDM_BUILD_OUTPUT} ${LDM_BUILD_INPUT}

.PHONY: compile_ls
compile_ls:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${LS_BUILD_OUTPUT} ${LS_BUILD_INPUT}

.PHONY: compile_ls_arm64
compile_ls_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${LS_BUILD_OUTPUT} ${LS_BUILD_INPUT}

.PHONY: compile_scheduler
compile_scheduler:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${SCHEDULER_BUILD_OUTPUT} ${SCHEDULER_BUILD_INPUT}

.PHONY: compile_scheduler_arm64
compile_scheduler_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${SCHEDULER_BUILD_OUTPUT} ${SCHEDULER_BUILD_INPUT}

.PHONY: compile_admission
compile_admission:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${ADMISSION_BUILD_OUTPUT} ${ADMISSION_BUILD_INPUT}

.PHONY: compile_admission_arm64
compile_admission_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${ADMISSION_BUILD_OUTPUT} ${ADMISSION_BUILD_INPUT}

.PHONY: compile_evictor
compile_evictor:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${EVICTOR_BUILD_OUTPUT} ${EVICTOR_BUILD_INPUT}

.PHONY: compile_evictor_arm64
compile_evictor_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${EVICTOR_BUILD_OUTPUT} ${EVICTOR_BUILD_INPUT}

.PHONY: compile_metrics
compile_metrics:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${METRICS_BUILD_OUTPUT} ${METRICS_BUILD_INPUT}

.PHONY: compile_metrics_arm64
compile_metrics_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${METRICS_BUILD_OUTPUT} ${METRICS_BUILD_INPUT}

.PHONY: compile_apiserver
compile_apiserver:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${APISERVER_BUILD_OUTPUT} ${APISERVER_BUILD_INPUT}

.PHONY: compile_apiserver_arm64
compile_apiserver_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${APISERVER_BUILD_OUTPUT} ${APISERVER_BUILD_INPUT}

.PHONY: _enable_buildx
_enable_buildx:
	@echo "Checking if buildx enabled"
	@if [[ "$(shell docker version -f '{{.Server.Experimental}}')" == "true" ]]; \
	then \
		docker buildx inspect mutil-platform-builder &>/dev/null; \
	        [ $$? == 0 ] && echo "ok" && exit 0; \
		docker buildx create --name mutil-platform-builder &>/dev/null&& echo "ok" && exit 0; \
	else \
		echo "experimental config of docker is false"; \
		exit 1; \
	fi


.PHONY: e2e-test
e2e-test:
	bash test/e2e-test.sh

.PHONY: pr-test
pr-test:
	bash test/pr-test.sh

