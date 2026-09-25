set shell := ["bash", "-euo", "pipefail", "-c"]

prefix     := env("PREFIX", env("HOME") / ".local")
bindir     := prefix / "bin"
session    := justfile_directory() / "compositor/session/install.sh"
system     := if prefix == env("HOME") / ".local" { "" } else { "--system" }

packages   := "compositor/compositor bar launcher settings wallpaper"
binaries   := "crownpositor crownbar launcher crownsettings crownpaper"

default:
    @just --list

# Fetch every desktop component submodule
sync:
    git submodule update --init --recursive

# Pull the latest commit of every component
update:
    git submodule update --remote --merge

# Compile every component in release mode
build:
    for p in {{ packages }}; do cargo build --release --manifest-path "$p/Cargo.toml"; done

# Install every component binary into the prefix and register the session
install:
    for p in {{ packages }}; do cargo install --path "$p" --root "{{ prefix }}" --force; done
    {{ session }} {{ system }}

# Remove the installed binaries and the session entry
uninstall:
    for b in {{ binaries }}; do cargo uninstall --root "{{ prefix }}" "$b" || true; done
    {{ session }} --uninstall

# Launch the desktop session (a TTY or a display manager entry)
start:
    "{{ bindir }}/crownos-session"

# Launch the desktop nested inside the current session
start-nested:
    CROWN_BACKEND=winit "{{ bindir }}/crownos-session"

# Type-check every component without producing binaries
check:
    for p in {{ packages }}; do cargo check --manifest-path "$p/Cargo.toml" --all-targets; done

fmt:
    for p in {{ packages }}; do cargo fmt --manifest-path "$p/Cargo.toml" --all; done

clean:
    for p in {{ packages }}; do cargo clean --manifest-path "$p/Cargo.toml"; done
