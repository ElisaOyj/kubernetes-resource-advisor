BINARY_NAME := resource-advisor
ifeq ($(USE_JSON_OUTPUT), 1)
GOTEST_REPORT_FORMAT := -json
endif

.PHONY: clean deps test gofmt run ensure build build-linux-amd64 build-darwin-amd64 build-darwin-arm64 build-windows build-all package-binaries build-all-packaged

clean:
	git clean -Xdf

deps:
	GO111MODULE=off go get -u golang.org/x/lint/golint

test:
	GO111MODULE=on go test ./... -v -coverprofile=gotest-coverage.out $(GOTEST_REPORT_FORMAT) > gotest-report.out && cat gotest-report.out || (cat gotest-report.out; exit 1)
	GO111MODULE=off golint -set_exit_status cmd/... pkg/... > golint-report.out && cat golint-report.out || (cat golint-report.out; exit 1)
	GO111MODULE=on go vet -mod vendor ./...
	./hack/gofmt.sh
	git diff --exit-code go.mod go.sum

gofmt:
	./hack/gofmt.sh

ensure:
	GO111MODULE=on go mod tidy
	GO111MODULE=on go mod vendor

run: build
	./bin/$(BINARY_NAME)

prepare-build:
	rm -rf bin/

build: prepare-build
	rm -f bin/$(BINARY_NAME)
	GO111MODULE=on go build -v -o bin/$(BINARY_NAME) ./cmd

build-linux-amd64: prepare-build
	GO111MODULE=on GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -v -o bin/$(BINARY_NAME)-linux-amd64 ./cmd

build-darwin-amd64: prepare-build
	GO111MODULE=on GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -v -o bin/$(BINARY_NAME)-darwin-amd64 ./cmd

build-darwin-arm64: prepare-build
	GO111MODULE=on GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="-s -w" -v -o bin/$(BINARY_NAME)-darwin-arm64 ./cmd

build-windows: prepare-build
	GO111MODULE=on GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -v -o bin/$(BINARY_NAME)-windows-amd64.exe ./cmd

build-all: build-linux-amd64 build-darwin-amd64 build-darwin-arm64 build-windows

package-binaries:
	upx --brute bin/resource-advisor-*

build-all-packaged: build-all package-binaries
	cd bin && sha256sum -b resource-advisor-* > sha256sum.txt
