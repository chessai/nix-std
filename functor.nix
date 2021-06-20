with {
  list = import ./list.nix;
  nonempty = import ./nonempty.nix;
  nullable = import ./nullable.nix;
  optional = import ./optional.nix;
};

{
  list = list.functor;
  nonempty = nonempty.functor;
  nullable = nullable.functor;
  optional = optional.functor;
}
