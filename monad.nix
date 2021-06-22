with {
  list = import ./list.nix;
  nonempty = import ./nonempty.nix;
  optional = import ./optional.nix;
};

{
  list = list.monad;
  nonempty = nonempty.monad;
  optional = optional.monad;
}
