with {
  set = import ./set.nix;
  types = import ./types.nix;
};

rec {
  /* id :: a -> a
  */
  id = x: x;

  /* const :: a -> b -> a
  */
  const = a: _: a;

  /* compose :: (b -> c) -> (a -> b) -> (a -> c)
  */
  compose = bc: ab: a: bc (ab a);

  /* flip :: (a -> b -> c) -> b -> a -> c
  */
  flip = f: b: a: f a b;

  /* not :: (a -> bool) -> a -> bool

     Inverts the boolean result of a function.

     > function.not function.id true
     false
  */
  not = f: a: ! f a;

  /* args :: (a -> b) -> set
  */
  args = f:
    if f ? __functor then f.__functionArgs or (args (f.__functor f))
    else builtins.functionArgs f;

  /* setArgs :: set -> (a -> b) -> (a -> b)
  */
  setArgs = args: f: set.assign "__functionArgs" args (toSet f);

  /* copyArgs :: (a -> b) -> (c -> b) -> (c -> b)
  */
  copyArgs = src: dst: setArgs (args src) dst;

  /* toSet :: (a -> b) -> set

     Convert a lambda into a callable set, unless `f` already is one.

     > function.toSet function.id // { foo = "bar"; }
     { __functor = «lambda»; foo = "bar"; }
  */
  toSet = f: if types.lambda.check f then {
    __functor = self: f;
  } else f;
}
