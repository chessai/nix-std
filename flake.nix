{
  description = "No-nixpkgs standard library for the Nix expression language";

  outputs = { self }:
    let
      defaultSystems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachDefaultSystem = self.lib.set.gen defaultSystems;
    in
    {
      lib = import ./default.nix;
      checks = eachDefaultSystem (system: {
        nix-std-test = import ./test/default.nix { inherit system; };
      });
    };
}
