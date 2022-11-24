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
}
