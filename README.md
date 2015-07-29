# golang-builder

This is a docker image to build Go projects and docker images. The container will run:
* go vet
* go vet
* golint
* errcheck
* race detector
* coverage


and generate reports in a `buildreport/` directory.

It is heavily inspired by:[CenturyLinkLabs golang-builder](https://github.com/CenturyLinkLabs/golang-builder).

## Requirements

### Canonical Import Path
To build the project with valid package references the Go builder needs to create the `GOPATH` with proper directories. Which directories
these are is not in the project therefore Go allows you to define it via [Canonical import paths](https://golang.org/doc/go1.4#canonicalimports). For example:

```
package main // import "github.com/alpe/ci-example-project"
```

An alternative would be to provide a *default path* which works for all your projects. See the `build_environment.sh`.

### Dependency management
[gpm](https://github.com/pote/gpm) is used for dependency management. This doesn't give you reproducable builds and comes with
other issues. Though a lot of our projects use it therfore we stick with it until a better solution comes with Go 1.5.
Current alternatives would be [gb] http://dave.cheney.net/2015/06/09/gb-a-project-based-build-tool-for-the-go-programming-language or 
[godep](https://github.com/tools/godep) which do vendoring and solve the problem better. (You can find a previous version in the commit history supporting godep.)

## Build local

* Create `.netrc` for [gpm](https://github.com/pote/gpm) to access private github repositories.
You'll need a new [github token](https://github.com/settings/tokens).

~~~netrc
machine github.com login <token>
~~~

* Build new go-builder docker image
~~~bash
docker build -t go-builder .
~~~

* Run container to build binary and code metrics
~~~bash
docker run --rm \
  -v $(pwd):/src \
  go-builder
~~~

* Run container to build docker image, binary and code metrics
~~~bash
docker run --rm \
  -v $(pwd):/src \
  -v /var/run/docker.sock:/var/run/docker.sock \
  go-builder mytag
~~~


### Other Resources
* More details how to build minimal docker images: https://labs.ctl.io/small-docker-images-for-go-apps/
* goclean.sh: https://gist.github.com/hailiang/0f22736320abe6be71ce
