#!/usr/bin/env bash

nix-env --delete-generations old
nix-collect-garbage
