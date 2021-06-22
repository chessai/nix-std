with {
  list = import ./list.nix;
  nonempty = import ./nonempty.nix;
  nullable = import ./nullable.nix;
  optional = import ./optional.nix;
};

{
  list = list.applicative;
  nonempty = nonempty.applicative;
  nullable = nullable.applicative;
  optional = optional.applicative;
}
