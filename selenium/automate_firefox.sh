#!/bin/bash
set -e
set -x
browser_version=$1
selenoid_version=$2
tag=$3
driver_version=$4
./build-dev.sh firefox/apt $browser_version false false $tag
./build-dev.sh firefox/apt $browser_version true false $tag
pushd firefox/gecko+selenoid
../../build.sh gecko+selenoid $tag $selenoid_version selenoid/firefox:$tag $driver_version
popd
docker rm -f selenium || true
docker run -d --name selenium -p 4444:4444  selenoid/firefox:$tag
tests_dir=../../selenoid-container-tests/
if [ -d "$tests_dir" ]; then
    pushd "$tests_dir"
    mvn clean test -Dgrid.browser.version=$tag || true
    popd
else
    echo "Skipping tests as $tests_dir does not exist."
fi
read -p "Push?" yn
if [ "$yn" == "y" ]; then
	docker push "selenoid/dev:firefox_"$tag
	docker push "selenoid/dev:firefox_"$tag"_full"
	docker push "selenoid/firefox:$tag"
  docker tag "selenoid/firefox:$tag" "selenoid/firefox:latest"
  docker push "selenoid/firefox:latest"
fi
