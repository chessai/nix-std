with {
  list = import ./list.nix;
  maybe = import ./maybe.nix;
};

{
  list = list.applicative;
  maybe = maybe.applicative;
}
