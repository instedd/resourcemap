#!/bin/sh

export CRYSTAL_CACHE_DIR=~/.crystal
export TARGET=$(uname -m -s | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

cd crystal-api-server

crystal deps
mkdir -p bin/release/$TARGET
crystal build bin/all.cr -o bin/release/$TARGET/all --release
