with {
  list = import ./list.nix;
  nullable = import ./nullable.nix;
  optional = import ./optional.nix;
};

{
  list = list.functor;
  nullable = nullable.functor;
  optional = optional.functor;
}
