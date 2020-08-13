with {
  list = import ./list.nix;
  maybe = import ./maybe.nix;
};

{
  list = list.monad;
  maybe = maybe.monad;
}
