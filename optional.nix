with rec {
  function = import ./function.nix;
  inherit (function) id;
};

/*
type Optional a = { value :: Nullable a }
*/

rec {
  /* nothing :: Optional a
  */
  nothing = { value = null; };

  /* just :: a -> Optional a
  */
  just = x: { value = x; };

  functor = {
    /* map :: (a -> b) -> Optional a -> Optional b
    */
    map = f: x:
      if x == nothing
      then nothing
      else { value = f x.value; };
  };

  applicative = functor // rec {
    /* pure :: a -> Optional a
    */
    pure = x: { value = x; };
    /* ap :: Optional (a -> b) -> Optional a -> Optional b
    */
    ap = lift2 id;
    /* lift2 :: (a -> b -> c) -> Optional a -> Optional b -> Optional c
    */
    lift2 = f: x: y:
      if x == nothing
      then nothing
      else if y == nothing
           then nothing
           else { value = f x.value y.value; };
  };

  monad = applicative // {
    /* join :: Optional (Optional a) -> Optional a
    */
    join = m: match m {
      nothing = { value = null; };
      just = x: { value = x; };
    };

    /* bind :: Optional a -> (a -> Optional b) -> Optional b
    */
    bind = m: k: match m {
      nothing = { value = null; };
      just = k;
    };
  };

  /* `optional.semigroup` recovers a monoid from a semigroup by adding
     `optional.nothing` as the empty element. The semigroup's append will simply
     discard nothings in favor of other elements.
  */
  semigroup = a: {
    append = x: y:
      if x.value == null
      then y
      else if y.value == null
           then x
           else { value = a.append x.value y.value; };
  };

  /* `optional.monoid` recovers a monoid from a semigroup by adding
     `optional.nothing` as the empty element.
  */
  monoid = a: semigroup a // {
    empty = { value = null; };
  };

  /* match :: Optional a -> { nothing :: b, just :: a -> b } -> b
  */
  match = x: con:
    if x == nothing
    then con.nothing
    else con.just x.value;

  /* fromNullable :: nullable a -> optional a
  */
  fromNullable = x:
    if x == null
    then nothing
    else just x;

  /* toNullable :: optional a -> nullable a
  */
  toNullable = x: x.value;

  /* optional a -> bool
  */
  isJust = x: x.value != null;

  /* optional a -> bool
  */
  isNothing = x: x.value == null;
}
