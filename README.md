# nix-std

[![Build
Status](https://travis-ci.org/chessai/nix-std.svg?branch=master)](https://travis-ci.org/chessai/nix-std)

no-nixpkgs standard library for the nix expression language.

## Usage

```nix
with {
  std = import (builtins.fetchTarball {
    url = "https://github.com/chessai/nix-std/archive/v0.0.0.1.tar.gz";
    sha256 = "0vglyghzj19240flribyvngmv0fyqkxl8pxzyn0sxlci8whmc9fr"; });
};
```
