with {
  list = import ./list.nix;
  nullable = import ./nullable.nix;
  optional = import ./optional.nix;
};

{
  list = list.monad;
  nullable = nullable.monad;
  optional = optional.monad;
}
