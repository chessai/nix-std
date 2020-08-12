# nix-std

[![Build
Status](https://travis-ci.org/chessai/nix-std.svg?branch=master)](https://travis-ci.org/chessai/nix-std)

no-nixpkgs standard library for the nix expression language.

## Usage

```nix
with {
  std = import (builtins.fetchTarball {
    url = "git@github.com:chessai/nix-std/archive/v0.0.0.1.tar.gz";
    sha256 = "";
  });
};
```
