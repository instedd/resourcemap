docker build -f Dockerfile.api-server-builder -t resmap-api-server-builder .

docker run -it --rm -v `pwd`:/host resmap-api-server-builder /host/build-api-server.sh
