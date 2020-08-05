let
  function = import ./function.nix;
in
rec {
  #inherit (builtins) head tail length isList elemAt concatLists filter elem genList map;

  /* @partial
     head :: [a] -> a
  */
  head = builtins.head;

  /* @partial
     tail :: [a] -> [a]
  */
  tail = builtins.tail;

  /* length :: [a] -> int
  */
  length = builtins.length;

  /* singleton :: a -> [a]
  */
  singleton = x: [x];

  /* map :: (a -> b) -> [a] -> [b]
  */
  map = builtins.map;

  /* for :: [a] -> (a -> b) -> [b]
  */
  for = function.flip map;

  /* imap :: (int -> a -> b) -> [a] -> [b]
  */
  imap = f: xs0:
    let
      go = i: xs:
        let
          u = uncons xs;
        in if u.head == null
           then []
           else cons (f i u.head) (go (i + 1) u.tail);
    in go 0 xs0;

  /* ifor :: [a] -> (int -> a -> b) -> [b]
  */
  ifor = function.flip imap;

  /* @partial
     elemAt :: [a] -> int -> a
  */
  elemAt = builtins.elemAt;

  /* @partial
     index :: [a] -> int -> a
  */
  index = builtins.elemAt;

  /* concat :: [[a]] -> [a]
  */
  concat = builtins.concatLists;

  /* filter :: (a -> bool) -> [a] -> [a]
  */
  filter = builtins.filter;

  /* elem :: a -> [a] -> bool
  */
  elem = builtins.elem;

  /* notElem :: a -> [a] -> bool
  */
  notElem = x: xs: !(builtins.elem x xs);

  /* genList :: (int -> a) -> int -> [a]
  */
  genList = builtins.genList;

  /* generate :: (int -> a) -> int -> [a]
  */
  generate = builtins.genList;

  /* cons :: a -> [a] -> [a]
  */
  cons = x: xs: [x] ++ xs;

  /* uncons :: [a] -> { head: Maybe a, tail: [a] }
  */
  uncons = xs: if (length xs == 0)
    then { head = null; tail = []; }
    else { head = builtins.head xs; tail = builtins.tail xs; };

  /* foldr :: (a -> b -> b) -> b -> [a] -> b
  */
  foldr = k: z0: xs0:
    let
      go = xs:
        let
          u = uncons xs;
        in if u.head == null
           then z0
           else k u.head (go u.tail);
    in go xs0;

  /* foldl' :: (b -> a -> b) -> b -> [a] -> b
  */
  foldl' = builtins.foldl';

  /* concatMap :: (a -> [b]) -> [a] -> [b]
  */
  concatMap = builtins.concatMap;

  /* any :: (a -> bool) -> [a] -> bool
  */
  any = builtins.any;

  /* all :: (a -> bool) -> [a] -> bool
  */
  all = builtins.all;

  /* count :: (a -> bool) -> [a] -> int
  */
  count = p: foldl' (c: x: if p x then c + 1 else c) 0;

  /* optional :: bool -> a -> [a]
  */
  optional = b: x: if b then [x] else [];

  /* optionals :: bool -> [a] -> [a]
  */
  optionals = b: xs: if b then xs else [];

  /* range :: int -> int -> [int]
  */
  range = first: last: if first > last
                       then []
                       else generate (n: first + n) (last - first + 1);

  /* parition :: (a -> bool) -> [a] -> { sat :: [a], unsat :: [a] }
  */
  partition = p: xs:
    let
      bp = builtins.partition p xs;
    in { sat = bp.right; unset = bp.wrong; };
}
