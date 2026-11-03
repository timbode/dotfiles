#!/usr/bin/env bash
# Writes ~/Library/Colors/Dotfiles.clr: a macOS color palette holding the main
# colour of each starship theme. iTerm's tab colour menu → "Other…" opens the
# system colour picker, whose "Color Palettes" tab then lists "Dotfiles", so a
# tab can be tinted to match the machine it is connected to.
#
# Each colour is the theme's directory-segment background (color_yellow in
# config/starship/<variant>.toml), the largest block of colour in the prompt.
# Keep the two in sync when a theme changes.
set -euo pipefail

out="$HOME/Library/Colors/Dotfiles.clr"
mkdir -p "$(dirname "$out")"

swift - "$out" <<'SWIFT'
import AppKit
let colors: [(String, String)] = [
    ("mac (amber)",     "d79921"),
    ("server (teal)",   "0d9488"),
    ("cluster (purple)","7c3aed"),
    ("gpu (blue)",      "1e88e5"),
    ("cloud (pink)",    "c2709a"),
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
