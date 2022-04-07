#TODO Handle platforms

# Go compilers
FROM golang:1.18-alpine AS go

RUN apk add --no-cache git

# See https://pkg.go.dev/google.golang.org/protobuf@v1.28.0/cmd/protoc-gen-go
ARG GO_GEN_VERION=1.28.0
ARG GO_GRPC_URL="google.golang.org/protobuf/cmd/protoc-gen-go@v$GO_GEN_VERION"
RUN go install $GO_GRPC_URL

# See https://pkg.go.dev/google.golang.org/grpc/cmd/protoc-gen-go-grpc
ARG GO_GRPC_VERSION=1.2.0
ARG GO_GRPC_URL="google.golang.org/grpc/cmd/protoc-gen-go-grpc@v$GO_GRPC_VERSION"
RUN go install $GO_GRPC_URL

FROM golang:1.18-alpine AS java

# See https://mvnrepository.com/artifact/io.grpc/protoc-gen-grpc-java
ARG JAVA_GRPC_VERSION=1.45.1
ARG JAVA_PLATFORM=linux-x86_64
ARG JAVA_GRPC_URL="https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-java/$JAVA_GRPC_VERSION/protoc-gen-grpc-java-$JAVA_GRPC_VERSION-$JAVA_PLATFORM.exe"

RUN echo "Installing protoc-gen-grpc-java-$JAVA_GRPC_VERSION-$JAVA_PLATFORM" && \
    wget --quiet "$JAVA_GRPC_URL" -O /go/bin/protoc-gen-grpc-java

ARG BUF_VERSION=1.3.1
FROM bufbuild/buf:1.3.1

RUN apk add --no-cache unzip

# See https://github.com/protocolbuffers/protobuf/releases
ARG PROTOBUF_VERSION=3.20.0
ARG PROTOBUF_PLATFORM=linux-x86_64
ARG PROTOBUF_URL="https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protoc-$PROTOBUF_VERSION-$PROTOBUF_PLATFORM.zip"

# See https://github.com/protocolbuffers/protobuf/releases
RUN echo "Installing protoc-$PROTOBUF_VERSION-$PROTOBUF_PLATFORM" && \
    wget --quiet $PROTOBUF_URL -O protoc.zip && \
    unzip protoc.zip -d protoc && \
    cp -R protoc/bin/* /usr/local/bin/ && \
    cp -R protoc/include/* /usr/local/include/ && \
    rm -rf protoc protoc.zip

COPY --from=go /go/bin/protoc-gen-go /usr/local/bin/
COPY --from=go /go/bin/protoc-gen-go-grpc /usr/local/bin/
COPY --from=java /go/bin/protoc-gen-grpc-java /usr/local/bin/

RUN chmod -R -x /usr/local/bin/
RUN ls -al /usr/local/bin/

# TODO One day if the grpc are release by version we could use this to downlaod the correct versions.
# git ls-remote --tags git@github.com:grpc/grpc.git v1.9.1 | cut -f1
# wget https://packages.grpc.io/# -O - | xmllint --xpath 'packages/builds/build[@commit="a3b54ef90841ec45fe5e28f54245b7944d0904f9"]' -