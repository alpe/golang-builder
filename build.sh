#!/bin/bash -e

source /build_environment.sh

mkdir buildreport

go vet ./... > buildreport/go_vet.txt || true
golint ./... > buildreport/golint.txt || true
errcheck ./... > buildreport/errcheck.txt || true

go test -race ./...

# Run test coverage on each subdirectories and merge the coverage profile.
echo "mode: count" > buildreport/profile.cov

# Standard go tooling behavior is to ignore dirs with leading underscors
for dir in $(find . -maxdepth 10 -not -path './.git*' -not -path '*/_*' -type d);
do
if ls $dir/*.go &> /dev/null; then
    go test -covermode=count -coverprofile=$dir/profile.tmp $dir
    if [ -f $dir/profile.tmp ]
    then
        cat $dir/profile.tmp | tail -n +2 >> buildreport/profile.cov
        rm $dir/profile.tmp
    fi
fi
done

go tool cover -html buildreport/profile.cov -o buildreport/cover.html

# Compile statically linked version of package
echo "Building $pkgName"
`CGO_ENABLED=${CGO_ENABLED:-0} go build -a --installsuffix cgo --ldflags="${LDFLAGS:--s}" $pkgName`

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
