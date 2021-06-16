with {
  list = import ./list.nix;
  nullable = import ./nullable.nix;
};

{
  list = list.applicative;
  nullable = nullable.applicative;
}
