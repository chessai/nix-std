with {
  list = import ./list.nix;
  nullable = import ./nullable.nix;
};

{
  list = list.functor;
  nullable = nullable.functor;
}
