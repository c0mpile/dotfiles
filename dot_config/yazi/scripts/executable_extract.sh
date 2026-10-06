#!/usr/bin/env bash

case "$1" in
  *.rar) unrar x -mt -o+ "$1" "${1%.*}/" ;;
  *)     7z x "$1" -o"${1%.*}" ;;
esac
