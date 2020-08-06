let
  function = import ./function.nix;
in
rec {
  /* List functor object
  */
  functor = {
    /* map :: (a -> b) -> [a] -> [b]
    */
    inherit map;
  };

  /* List applicative object
  */
  applicative = functor // {
    /* pure :: a -> [a]
    */
    pure = singleton;
    /* lift2 :: (a -> b -> c) -> [a] -> [b] -> [c]
    */
    lift2 = f: xs: ys: monad.bind xs (x: monad.bind ys (y: singleton (f x y)));
  };

  /* List monad object
  */
  monad = applicative // {
    /* join :: [[a]] -> [a]
    */
    join = concat;

    /* bind :: [a] -> (a -> [b]) -> [b]
    */
    bind = function.flip concatMap;
  };

  /* List semigroup object
  */
  semigroup = {
    /* append :: [a] -> [a] -> [a]
    */
    append = xs: ys: xs ++ ys;
  };

  /* List monoid object
  */
  monoid = semigroup // {
    /* empty :: [a]
    */
    empty = nil;
  };

  /* match :: { nil :: b; cons :: a -> [a] -> b; } -> [a] -> b
  */
  match = { nil, cons }@args: xs:
    let u = uncons xs;
    in if u.head == null
       then args.nil
       else args.cons u.head u.tail;

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
    let go = i:
          match {
            nil = [];
            cons = x: xs: cons (f i x) (go (i + 1) xs);
          };
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

  /* generate :: (int -> a) -> int -> [a]
  */
  generate = builtins.genList;

  /* nil :: [a]
  */
  nil = [];

  /* cons :: a -> [a] -> [a]
  */
  cons = x: xs: [x] ++ xs;

  /* uncons :: [a] -> { head: Maybe a, tail: [a] }
  */
  uncons = xs: if (length xs == 0)
    then { head = null; tail = []; }
    else { head = builtins.head xs; tail = builtins.tail xs; };

  /* snoc :: [a] -> a -> [a]
  */
  snoc = xs: x: xs ++ [x];

  /* foldr :: (a -> b -> b) -> b -> [a] -> b
  */
  foldr = k: z0: xs0:
    let go = match {
          nil = z0;
          cons = x: xs: k x (go xs);
        };
    in go xs0;

  /* foldl' :: (b -> a -> b) -> b -> [a] -> b
  */
  foldl' = builtins.foldl';

  /* foldMap :: Monoid m => (a -> m) -> [a] -> m
  */
  foldMap = m: f: foldr (function.compose m.append f) m.empty;

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
  range = first: last:
    if first > last
    then []
    else generate (n: first + n) (last - first + 1);

  /* parition :: (a -> bool) -> [a] -> { sat :: [a], unsat :: [a] }
  */
  partition = p: xs:
    let bp = builtins.partition p xs;
    in { sat = bp.right; unset = bp.wrong; };

  /* traverse :: Applicative f => (a -> f b) -> [a] -> [f b]
  */
  traverse = ap: f: foldr (x: ap.lift2 cons (f x)) (ap.pure nil);
}
