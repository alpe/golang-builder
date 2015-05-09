FROM golang:1.4
MAINTAINER Alex Peters <info@alexanderpeters.de>

RUN apt-get update && apt-get install -y upx-ucl
# Install Docker binary
RUN wget -nv https://get.docker.com/builds/Linux/x86_64/docker-1.3.3 -O /usr/bin/docker && \
  chmod +x /usr/bin/docker
RUN go get github.com/pwaller/goupx
RUN go get github.com/tools/godep
RUN	go get golang.org/x/tools/cmd/cover

VOLUME /src
WORKDIR /src


COPY build_environment.sh /
COPY build.sh /

ENTRYPOINT ["/build.sh"]
