with rec {
  list = import ./list.nix;
  set = import ./set.nix;
  tuple = import ./tuple.nix;
};

rec {
  /* empty :: tuple
  */
  empty = set.empty;

  /* new2 :: _0 -> _1 -> (_0, _1)
  */
  new2 = _0: _1: { inherit _0 _1; };

  /* fromList :: [a] -> tuple
  */
  fromList = xs: set.fromList (list.imap (i: tuple.new2 "_${toString i}") xs);

  /* toPair :: (key, value) -> pair
    Converts a tuple to the argument required by `builtins.listToAttrs`
  */
  toPair = { _0, _1 }: { name = _0; value = _1; };
}
