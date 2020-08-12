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
}
