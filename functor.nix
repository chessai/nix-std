with {
  list = import ./list.nix;
  maybe = import ./maybe.nix;
};

{
  list = list.functor;
  maybe = maybe.functor;
}
