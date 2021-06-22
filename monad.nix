with {
  list = import ./list.nix;
  optional = import ./optional.nix;
};

{
  list = list.monad;
  optional = optional.monad;
}
