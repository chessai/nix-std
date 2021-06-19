with {
  list = import ./list.nix;
  nullable = import ./nullable.nix;
  optional = import ./optional.nix;
};

{
  list = list.applicative;
  nullable = nullable.applicative;
  optional = optional.applicative;
}
