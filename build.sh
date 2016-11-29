#!/bin/bash

set -e -o pipefail

source /build_environment.sh

mkdir buildreport
novendor_dirs=$(go list ./... | grep -v '/vendor/')

echo "--------------------------------------"
echo "Using nonvendor dirs:"
echo "$novendor_dirs"

echo "--------------------------------------"
echo "* Run vet + golint"
for f in go_vet.txt golint.txt
do
    touch buildreport/${f}
done

for d in $novendor_dirs
do
    go vet ${d} 2>> buildreport/go_vet.txt || true
    golint ${d} >> buildreport/golint.txt || true
done

echo "--------------------------------------"
echo "* Run errcheck"
errcheck -ignoretests ${novendor_dirs} > buildreport/errcheck.txt || true

if [ "$SKIP_TESTS" == "yes" ]
then
    echo "--------------------------------------"
    echo "* Skipping Tests: disabled"
else
    # Run test coverage on each subdirectories and merge the coverage profile.
    echo "--------------------------------------"
    echo " Run tests with race detector"
    START=$(date +%s)
    echo "mode: atomic" > buildreport/profile.cov
    test_output_file="buildreport/test-stdout.txt"
    for dir in ${novendor_dirs}
    do
        path="$GOPATH/src/$dir"
        if ls $path/*.go &> /dev/null; then
            go test --race -covermode=atomic -coverprofile=$path/profile.tmp $dir  | tee -a ${test_output_file}
            if [ -f $path/profile.tmp ]
            then
                cat $path/profile.tmp | tail -n +2 >> buildreport/profile.cov
                rm $path/profile.tmp
            fi
        fi
    done
    echo "* Building coverage report"
    go tool cover -html buildreport/profile.cov -o buildreport/cover.html
    echo "* Building junit style test report"
    cat ${test_output_file} | go-junit-report > buildreport/test-report.xml
    END=$(date +%s)
    echo "* Completed: $((END-START))s"
fi

echo "--------------------------------------"
main_packages=$(go list ./... |grep -v vendor |grep cmd || true)
if [[ -z main_packages ]];
then
    main_packages=( ${pkgName} )
fi

touch buildreport/docker-artifacts

for pkg in ${main_packages[@]}
do
    START=$(date +%s)
    # Grab the last segment from the package name
    name=${pkg##*/}
    echo "* Building Go binary: $pkg"

    flags=(-a -installsuffix cgo)
    ldflags=('-s -X main.version='$BUILD_VERSION)

    # Compile statically linked version of package
    # see https://golang.org/cmd/link/ for all ldflags
    CGO_ENABLED=${CGO_ENABLED:-0} go build \
        "${flags[@]}" \
        -ldflags "${ldflags[@]}" \
        -o "$goPath/src/$pkg/$name" \
        "$pkg"

    if [[ $COMPRESS_BINARY == "true" ]];
    then
      goupx $name
    fi
    END=$(date +%s)
    echo "* Completed: $((END-START))s"

    echo "--------------------------------------"
    if [ -e "/var/run/docker.sock" ] && [ -e "$goPath/src/$pkg/Dockerfile" ];
    then
        START=$(date +%s)
        # Default to latest if version is `not set explicitly
        tagName=${name}:${versionName:-latest}
        echo "* Building Docker image: $tagName"

        # Build the image from the Dockerfile in the package directory
        docker build --pull -t ${tagName} -f "$goPath/src/$pkg/Dockerfile" .
        echo ${tagName} >> buildreport/docker-artifacts

        END=$(date +%s)
        echo "* Completed: $((END-START))s"
    else
        echo "* Skipping Docker build"
    fi
done
echo "--------------------------------------"
echo "* done"