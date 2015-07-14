#!/bin/sh

export CRYSTAL_C=crystal
export CRYSTAL_CACHE_DIR=~/.crystal
export TARGET=$(uname -m -s | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

cd crystal-api-server

$CRYSTAL_C deps
mkdir -p bin/release/$TARGET
$CRYSTAL_C build bin/cli-server.cr -o bin/release/$TARGET/cli-server --release
