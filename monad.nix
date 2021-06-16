with {
  list = import ./list.nix;
  nullable = import ./nullable.nix;
};

{
  list = list.monad;
  nullable = nullable.monad;
}
