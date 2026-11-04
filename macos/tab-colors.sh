#!/usr/bin/env bash
# Writes ~/Library/Colors/Dotfiles.clr: a macOS color palette holding the tab
# colour of each machine type. iTerm's tab colour menu → "Other…" opens the
# system colour picker, whose "Color Palettes" tab then lists "Dotfiles", so a
# tab can be tinted to match the machine it is connected to.
#
# Each colour has the hue of the theme's directory-segment background
# (color_yellow in config/starship/<variant>.toml), the largest block of colour
# in the prompt, darkened to OKLCH lightness 0.50. At full strength those
# backgrounds glare in iTerm's tab bar, and they differ in lightness (the amber
# at 0.73, the purple at 0.54), so the tabs would not read as one set. Server and
# cluster land on their themes' git-segment colours. The same values are in
# config/iterm/hosts.json and in the local-tab escape in config/shell/tools.zsh;
# keep all three in sync when a theme changes.
set -euo pipefail

out="$HOME/Library/Colors/Dotfiles.clr"
mkdir -p "$(dirname "$out")"

swift - "$out" <<'SWIFT'
import AppKit
let colors: [(String, String)] = [
    ("mac (amber)",     "835a03"),
    ("server (teal)",   "0f766e"),
    ("cluster (purple)","6d28d9"),
    ("gpu (blue)",      "0065b2"),
    ("cloud (pink)",    "92456e"),
]
let list = NSColorList(name: "Dotfiles")
for (i, (name, hex)) in colors.enumerated() {
    let v = Int(hex, radix: 16)!
    let c = NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
                    green:   CGFloat((v >> 8) & 0xff) / 255,
                    blue:    CGFloat(v & 0xff) / 255, alpha: 1)
    list.insertColor(c, key: name, at: i)
}
try list.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
SWIFT
echo "wrote $out"
