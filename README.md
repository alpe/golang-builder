# golang-builder
Heavily inspired by:[CenturyLinkLabs golang-builder](https://github.com/CenturyLinkLabs/golang-builder).

~~~bash
set -e
service=$JOB_NAME
branch=$(echo $GIT_BRANCH | cut -d/ -f 2)

# build
docker build -t $service:$branch .

# tag + upload image
docker tag $service:$branch registry:5000/$service:$branch-$BUILD_NUMBER
docker push registry:5000/$service:$branch-$BUILD_NUMBER
~~~

## Test local
~~~
# build new image
docker build -t go_builder_image .

# run image with example project
docker run --rm \
  -v $(pwd):/src \
  -v /var/run/docker.sock:/var/run/docker.sock \
  go_builder_image \
  ci-example-project
~~~

### Resources
https://gist.github.com/hailiang/0f22736320abe6be71ce