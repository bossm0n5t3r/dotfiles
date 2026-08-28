#!/usr/bin/env bash

mit-license() {
  (
    if [ "$#" -ne 0 ] && [ "$#" -lt 2 ]; then
      printf 'Usage: mit-license [year copyright-holder]\n' >&2
      return 2
    fi

    download_file=$(mktemp ./LICENSE.download.XXXXXX) || return 1
    rendered_file=

    trap '
            rm -f -- "$download_file"
            if [ -n "$rendered_file" ]; then
                rm -f -- "$rendered_file"
            fi
        ' EXIT HUP INT TERM

    if ! curl --fail --location \
      --output "$download_file" \
      https://spdx.org/licenses/MIT.txt; then
      return 1
    fi

    output_file=$download_file
    if [ "$#" -ge 2 ]; then
      year=$1
      shift
      copyright_holder=$*
      rendered_file=$(mktemp ./LICENSE.rendered.XXXXXX) || return 1

      while IFS= read -r line || [ -n "$line" ]; do
        if [ "$line" = 'Copyright (c) <year> <copyright holders>' ]; then
          printf 'Copyright (c) %s %s\n' \
            "$year" "$copyright_holder" || return 1
        else
          printf '%s\n' "$line" || return 1
        fi
      done <"$download_file" >|"$rendered_file"

      output_file=$rendered_file
    fi

    mv -- "$output_file" LICENSE
  )
}
