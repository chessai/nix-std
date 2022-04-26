with rec {
  function = import ./function.nix;
  inherit (function) id;
  optional = import ./optional.nix;
};

/*
type Nullable a = a | null
*/

rec {
  functor = {
    /* map :: (a -> b) -> Nullable a -> Nullable b
    */
    map = f: x:
      if x == null
      then null
      else f x;
  };

  applicative = functor // rec {
    /* pure :: a -> Nullable a
    */
    pure = id;
    /* ap :: Nullable (a -> b) -> Nullable a -> Nullable b
    */
    ap = lift2 id;
    /* lift2 :: (a -> b -> c) -> Nullable a -> Nullable b -> Nullable c
    */
    lift2 = f: x: y:
      if x == null
      then null
      else if y == null
           then null
           else f x y;
  };

  /* match :: Nullable a -> { nothing :: b, just :: a -> b } -> b
  */
  match = x: { nothing, just }:
    if x == null
    then nothing
    else just x;

  semigroup = a: {
    append = x: y:
      if x == null
        then y
      else if y == null
        then x
      else a.append x y;
  };

  monoid = a: semigroup a // {
    empty = null;
  };
}
