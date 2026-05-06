#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_svg="$repo_root/apps/tablet/public/icon.svg"
asset_root="$repo_root/apps/watchos/AgentPulseWatch/AgentPulseWatch/Assets.xcassets"
app_icon_dir="$asset_root/AppIcon.appiconset"
logo_dir="$asset_root/AgentPulseLogo.imageset"

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "rsvg-convert is required to generate watch icons." >&2
  exit 1
fi

if command -v magick >/dev/null 2>&1; then
  image_magick=(magick)
elif command -v convert >/dev/null 2>&1; then
  image_magick=(convert)
else
  echo "ImageMagick is required to remove icon transparency." >&2
  exit 1
fi

mkdir -p "$app_icon_dir" "$logo_dir"

render_png() {
  local size="$1"
  local target="$2"
  rsvg-convert -w "$size" -h "$size" "$source_svg" \
    | "${image_magick[@]}" png:- -background '#020305' -alpha remove -alpha off "$target"
}

app_icons=(
  "48:AppIcon-24@2x.png"
  "55:AppIcon-27.5@2x.png"
  "58:AppIcon-29@2x.png"
  "87:AppIcon-29@3x.png"
  "80:AppIcon-40@2x.png"
  "88:AppIcon-44@2x.png"
  "90:AppIcon-45@2x.png"
  "100:AppIcon-50@2x.png"
  "108:AppIcon-54@2x.png"
  "172:AppIcon-86@2x.png"
  "196:AppIcon-98@2x.png"
  "1024:AppIcon-1024.png"
)

for icon in "${app_icons[@]}"; do
  size="${icon%%:*}"
  filename="${icon#*:}"
  render_png "$size" "$app_icon_dir/$filename"
done

render_png 64 "$logo_dir/AgentPulseLogo.png"
render_png 128 "$logo_dir/AgentPulseLogo@2x.png"
render_png 192 "$logo_dir/AgentPulseLogo@3x.png"

echo "Generated Agent Pulse watch icons in $asset_root"
