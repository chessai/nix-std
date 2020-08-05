{
  inherit (import ./function.nix) compose const flip identity;

  bool = import ./bool.nix;
  fixpoints = import ./fixpoints.nix;
  function = import ./function.nix;
  list = import ./list.nix;
}
