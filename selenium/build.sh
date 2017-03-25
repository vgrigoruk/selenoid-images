#!/bin/bash
set -e

download_selenium() {
    selenium_version=$1
    url=""
    case selenium_version in
        2.21.0|2.32.0|2.35.0|2.39.0|2.40.0|2.41.0|2.43.1|2.44.0|2.45.0)
            url="https://repo.jenkins-ci.org/releases/org/seleniumhq/selenium/selenium-server-standalone/$selenium_version/selenium-server-standalone-$selenium_version.jar"
            ;;
        2.47.1)
            url="http://selenium-release.storage.googleapis.com/2.47/selenium-server-standalone-2.47.1.jar"
            ;;
        2.53.1)
            url="http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.1.jar"
            ;;
        *)
            echo "Unsupported Selenium version: $selenium_version"
            exit 1
            ;;
    esac
    wget -O selenium-server-standalone.jar "$url"
}

download_geckodriver() {
    wget -O geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v$1/geckodriver-v$1-linux64.tar.gz
    tar xvzf geckodriver.tar.gz
    rm -Rf geckodriver.tar.gz
}

download_chromedriver() {
    wget -O chromedriver.zip http://chromedriver.storage.googleapis.com/$1/chromedriver_linux64.zip
    unzip chromedriver.zip
    rm chromedriver.zip
}

download_operadriver() {
    wget -O operadriver.zip https://github.com/operasoftware/operachromiumdriver/releases/download/v$1/operadriver_linux64.zip
    unzip operadriver.zip -d /usr/bin
    rm operadriver.zip
}

if [ -z $1 -o -z $2 -o $3 ]; then
    echo 'Usage: build.sh {chromedriver|operadriver|selenium} <browser_version> <driver_or_selenium_version> [<screen_resolution in form 1280x1600x24>] [<port>]'
    exit 1
fi

mode=$1
version=$2
screen_resolution=${4-"1280x1600x24"}
port=${5-"4444"}
dir_name="/tmp/$(uuidgen | sed -e 's|-||g')"
mkdir -p "$dir_name"
cat Docker.driver.tmpl | sed -e "s|@@VERSION@@|$version|g" > "$dir_name/Dockerfile"
pushd "$dir_name"
if [ "$mode" == "chromedriver" ]; then
    download_chromedriver "$3"
else if [ "$mode" == "operadriver" ]; then
    download_operadriver "$3"
else if [ "$mode" == "geckodriver" ]; then
    download_geckodriver "$3"
else if [ "$mode" == "selenium" ]; then
    download_selenium "$3"
else
    echo "Unsupported mode: will do nothing. Exiting."
    exit 1
fi
docker build --build-arg SCREEN_RESOLUTION="$screen_resolution" --build-arg PORT="$port" .
popd
rm -Rf "$dir_name"
exit 0
