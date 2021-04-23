#!/usr/bin/env bash

if [[ -f "$PGDATA/configured" ]] && pg_isready -U postgres; then
  exit 0
else
  exit 1
fi
