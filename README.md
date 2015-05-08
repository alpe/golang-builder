# golang-builder
Based on [].

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
docker run --rm \
  -v $(pwd):/src \
  -v /var/run/docker.sock:/var/run/docker.sock \
  $(boot2docker ip):5000/go_builder_image \
  ci-example-project
~~~
