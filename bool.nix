with rec {
  optional = import ./optional.nix;
};

rec {
  /* true :: bool
  */
  true = builtins.true;

  /* false :: bool
  */
  false = builtins.false;

  /* not :: bool -> bool
  */
  not = x: !x;

  /* ifThenElse :: bool -> a -> a -> a
  */
  ifThenElse = b: x: y: if b then x else y;

  /* toOptional :: bool -> a -> Optional a
  */
  toOptional = b: x: if b then optional.just x else optional.nothing;

  /* toNullable :: bool -> a -> Nullable a
  */
  toNullable = b: x: if b then x else null;
}
