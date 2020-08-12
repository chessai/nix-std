with {
  function = import ./function.nix;
  inherit (function) id;
};

rec {
  functor = {
    /* map :: (a -> b) -> Maybe a -> Maybe b
    */
    map = f: x:
      if x == null
      then null
      else f x;
  };

  applicative = functor // {
    /* pure :: a -> Maybe a
    */
    pure = id;
    /* ap :: Maybe (a -> b) -> Maybe a -> Maybe b
    */
    ap = lift2 id;
    /* lift2 :: (a -> b -> c) -> Maybe a -> Maybe b -> Maybe c
    */
    lift2 = f: x: y:
      if x == null
      then null
      else if y == null
           then null
           else f x y;
  };

  monad = applicative // {
    /* join :: Maybe (Maybe a) -> Maybe a
    */
    join = m: match m {
      nothing = null;
      just = id;
    };

    /* bind :: Maybe a -> (a -> Maybe b) -> Maybe b
    */
    bind = m: k: match m {
      nothing = null;
      just = k;
    };
  };

  /* match :: { nothing :: b, just :: a -> b } -> Maybe a -> b
  */
  match = x: { nothing, just }:
    if x == null
    then nothing
    else just x;
}
