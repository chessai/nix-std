{
  description = "No-nixpkgs standard library for the Nix expression language";

  outputs = { self }: {
    lib = import ./default.nix;
  };
}
