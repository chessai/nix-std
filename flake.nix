{
  description = "No-nixpkgs standard library for the Nix expression language";

  outputs = { self }:
    let
      attrsToList = as:
        builtins.map (n: { name = n; value = as."${n}"; })
          (builtins.attrNames as);
      defaultSystems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachDefaultSystem = f:
        builtins.foldl'
          (acc: system:
            builtins.foldl'
              (acc: { name, value }:
                acc // { "${name}" = (acc.${name} or { }) // { "${system}" = value; }; }
              )
              acc
              (attrsToList (f system))
          )
          { }
          defaultSystems;
    in
    {
      lib = import ./default.nix;
    } // eachDefaultSystem (system: {
      checks.nix-std-test = import ./test/default.nix { inherit system; };
    });
}
