#!/usr/bin/env bash

#nixos-rebuild switch --upgrade
nixos-rebuild boot --upgrade

sleep 5

kbuildsycoca4 --noincremental

# OR
# nix-channel --update
# nixos-rebuild switch
