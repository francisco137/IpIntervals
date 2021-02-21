#!/bin/sh

export version_postgresql="${version_postgresql}"
export image_postgresql="${image_postgresql}"

docker build --build-arg PG_VERSION="${version_postgresql}" -t "${image_postgresql}" .

