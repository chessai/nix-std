rec {
  applicative = import ./applicative.nix;

  bool = import ./bool.nix;
  inherit (bool) true false not ifThenElse;

  fixpoints = import ./fixpoints.nix;
  inherit (fixpoints) fix;

  function = import ./function.nix;
  inherit (function) compose const flip id;

  functor = import ./functor.nix;

  list = import ./list.nix;
  inherit (list) map for;

  maybe = import ./maybe.nix;

  monad = import ./monad.nix;

  monoid = import ./monoid.nix;

  num = import ./num.nix;

  regex = import ./regex.nix;

  semigroup = import ./semigroup.nix;

  serde = import ./serde.nix;

  set = import ./set.nix;

  string = import ./string.nix;

  types = import ./types.nix;
}
