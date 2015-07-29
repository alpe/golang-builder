FROM golang:1.4
MAINTAINER Alex Peters <info@alexanderpeters.de>

RUN apt-get update && apt-get install -y upx-ucl
# Install Docker binary
RUN wget -nv https://get.docker.com/builds/Linux/x86_64/docker-1.5.0 -O /usr/bin/docker && \
  chmod +x /usr/bin/docker
RUN go get github.com/pwaller/goupx
RUN	go get golang.org/x/tools/cmd/cover
RUN	go get golang.org/x/tools/cmd/vet
RUN go get -u github.com/golang/lint/golint
RUN go get github.com/kisielk/errcheck

RUN wget https://raw.githubusercontent.com/pote/gpm/v1.3.2/bin/gpm -O /usr/local/bin/gpm && \
  chmod +x /usr/local/bin/gpm


VOLUME /src
WORKDIR /src


COPY build_environment.sh /
COPY build.sh /
COPY .netrc /root/

ENV GOMAXPROCS=2
ENV GORACE="halt_on_error=1"

ENTRYPOINT ["/build.sh"]
