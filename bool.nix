rec {
  /* not :: bool -> bool
  */
  not = x: !x;

  /* ifThenElse :: bool -> a -> a -> a
  */
  ifThenElse = b: x: y: if b then x else y;
}
