#!/usr/env/bin bash

nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nixos-rebuild switch --upgrade

