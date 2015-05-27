#!/bin/bash -e

source /build_environment.sh

godep go vet ./... > go_vet.txt
golint ./... > golint.txt

godep go test -race ./...

# Run test coverage on each subdirectories and merge the coverage profile.
echo "mode: count" > profile.cov
 
# Standard go tooling behavior is to ignore dirs with leading underscors
for dir in $(find . -maxdepth 10 -not -path './.git*' -not -path '*/_*' -type d);
do
if ls $dir/*.go &> /dev/null; then
    godep go test -covermode=count -coverprofile=$dir/profile.tmp $dir
    if [ -f $dir/profile.tmp ]
    then
        cat $dir/profile.tmp | tail -n +2 >> profile.cov
        rm $dir/profile.tmp
    fi
fi
done
 
godep go tool cover -html profile.cov -o cover.html

# Compile statically linked version of package
echo "Building $pkgName"
`CGO_ENABLED=${CGO_ENABLED:-0} godep go build -a --installsuffix cgo --ldflags="${LDFLAGS:--s}" $pkgName`

# Grab the last segment from the package name
name=${pkgName##*/}

if [[ $COMPRESS_BINARY == "true" ]];
then
  goupx $name
fi

if [ -e "/var/run/docker.sock" ] && [ -e "./Dockerfile" ];
then
  # Default TAG_NAME to package name if not set explicitly
  tagName=${tagName:-"$name":latest}

  # Build the image from the Dockerfile in the package directory
  docker build -t $tagName .
fi
