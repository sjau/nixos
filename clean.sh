#!/usr/bin/env bash

nix-env --delete-generations old
nix-collect-garbage
nix-collect-garbage -d
#nix-collect-garbage ----delete-older-than 30d
nix-store --optimise
