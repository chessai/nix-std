with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

let
  testDrv = builtins.derivation {
    name = "test";
    builder = "test";
    system = "x86_64-linux";
  };
in section "std.path" {
  check = string.unlines [
    (assertEqual true (types.path.check ./foo.nix))
    (assertEqual false (types.path.check (toString ./foo.nix)))
    (assertEqual true (types.pathlike.check ./foo.nix))
    (assertEqual true (types.pathlike.check testDrv))
    (assertEqual true (types.pathlike.check (toString ./foo.nix)))
    (assertEqual false (types.pathlike.check "a/b/c"))
  ];

  baseName = string.unlines [
    (assertEqual "foo.nix" (path.baseName ./foo.nix))
    (assertEqual "path.nix" (path.baseName ./path.nix))
    (assertEqual "foo.nix" (path.baseName (toString ./foo.nix)))
    (assertEqual "-test" (string.substring 32 (-1) (path.baseName testDrv)))
  ];

  dirName = string.unlines [
    (assertEqual ./. (path.parent ./foo.nix))
    (assertEqual ./. (path.parent ./path.nix))
    (assertEqual (toString ./.) (path.dirName (toString ./path.nix)))
    (assertEqual (toString builtins.storeDir) (path.dirName testDrv))
  ];

  fromString = string.unlines [
    (assertEqual (optional.just /a/b/c) (path.fromString "/a/b/c"))
    (assertEqual optional.nothing (path.fromString "a/b/c"))
  ];
}
