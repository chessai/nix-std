# nix-std

no-nixpkgs standard library for the nix expression language.

## Usage

```nix
with {
  std = import (builtins.fetchGit { url = "git@github.com:chessai/nix-std"; });
};

>>> std.list.filter std.even [1 2 3 4]
[ 2 4 ]
```
