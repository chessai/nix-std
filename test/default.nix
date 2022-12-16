{ system ? builtins.currentSystem
}:

with { std = import ./../default.nix; };
with std;

with { sections = import ./sections/default.nix; };

builtins.deepSeq std builtins.derivation {
  name = "nix-std-test-${import ./../version.nix}";
  inherit system;
  builder = "/bin/sh";
  args = [
    "-c"
    (string.unlines (builtins.attrValues sections) + ''
      echo > "$out"
    '')
  ];
}
