#!/bin/sh -e

docker compose pull
docker compose up -d db elasticsearch redis
docker compose run --rm --no-deps web bundle
docker compose run --rm --no-deps web rake db:setup
docker compose run --rm --no-deps web rake db:test:prepare
