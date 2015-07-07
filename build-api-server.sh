#!/bin/sh

cd crystal-api-server
crystal deps
mkdir bin/release
crystal build bin/all.cr -o bin/release/all --release
