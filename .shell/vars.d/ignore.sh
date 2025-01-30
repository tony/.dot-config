#!/usr/bin/env zsh

# ---------------------------
# FILE EXTENSIONS (Array)
# ---------------------------
file_exts=(
  # Archives
  gz tar rar zip 7z

  # Minified
  "min.js" "min.map"

  # Office / PDF
  pdf doc docx ppt pptx

  # Images
  gif jpeg jpg png svg psd xcf

  # Vector / eBook
  ai epub kpf mobi

  # Fonts
  TTF ttf otf eot woff woff2

  # Audio
  wma mp3 m4a ape ogg opus flac

  # Video
  mp4 wmv avi mkv webm m4b

  # iTunes / Music DB
  musicdb itdb itl itc

  # Binaries
  o so dll

  # Serialized / Pack
  cbor msgpack

  # Misc
  wpj pyc "js.map" snap
)

# Join them with the pipe character: gz|tar|rar|...
export IGNORE_FILE_EXT="$(printf '%s|' "${file_exts[@]}")"
# Trim the trailing pipe:
IGNORE_FILE_EXT="${IGNORE_FILE_EXT%|}"

# ---------------------------
# FOLDER / PATH WILDCARDS (Array)
# ---------------------------
wilds=(
  '^snap/'
  '^cache' '^_cache'
  'Library' '^Cache'
  'AppData'
  'Android'
  'site-packages' 'egg-info' 'dist-info'
  'node-gyp' 'node_modules' 'bower_components'
  '^build' 'webpack_bundles'
  'json/test/data'
  'drive_[a-z]/'
  '(^\.?/)?snap/'    # covers ./snap/ or snap/
  '/gems/'
  '^work/' '^study/' # canvas-lms
  '__pycache__/'
  '^\.cache/'
  '(_)?build/'
  '__generated__/'
)

# Join them with '|', then strip the trailing pipe
export IGNORE_FILE_WILD="$(printf '%s|' "${wilds[@]}")"
IGNORE_FILE_WILD="${IGNORE_FILE_WILD%|}"