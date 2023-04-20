FROM ghcr.io/nelhage/llama as llama
FROM ubuntu:focal
RUN apt-get update && \
        apt-get -y install ca-certificates && \
        apt-get clean
COPY hello.sh /app/hello.sh
COPY --from=llama /llama_runtime /llama_runtime
WORKDIR /app
ENTRYPOINT ["/llama_runtime"]
