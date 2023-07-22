#!/bin/bash

# Patch script to get compatible version of bb.js
echo "Building compatible bb.js from source"
echo "Warning: this will take ~15-20 minutes"

# Clone the barretenberg repository
git clone https://github.com/AztecProtocol/barretenberg.git

# Build the barretenberg cpp library to wasm
cd ./barretenberg/cpp
./bootstap.sh

# Build the bb.js library
cd ../ts
yarn
yarn build

# move to node_js folder
cd ../..
mv barretenberg/ts/dest/ ./bb.js
