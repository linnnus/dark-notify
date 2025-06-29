# `dark-notify`

CLI to monitor the system-wide dark mode on MacOS.

## Usage

Every time the system theme changes, a line is printed to standard output.
By default the current theme is printed immediately on startup.

```sh
$ ./dark-notify
light
dark
light
dark
```

The following flags are supported.

* `--exit`, `-e`: Exit after the first color has been shown.
* `--only-changes`, `-o`: Do not show the current value when starting.

## Building

It's a single source file so building should be pretty simple.
Either invoke CC with the flags in `compile_flags.txt` or use the included Nix flake.

```sh
$ cc @compile_flags.txt -o dark-notify dark-notify.m
$ nix build
```

## Neovim plugin

A Neovim plugin is also included. It spawns `dark-notify`
(which must be in `$PATH`)
and monitors its output.
When it changes the 'background' option (see `:h 'background') is updated.
It should be compatible with all colorschemes which respect that option.

A demo Neovim pre-configured with the plugin is also included.

```sh
$ nix run .#demo-vim
```
