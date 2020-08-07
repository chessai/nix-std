with rec {
  function = import ./function.nix;
  inherit (function) flip compose;
};

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
    bind = flip concatMap;
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

  /* match :: [a] -> { nil :: b; cons :: a -> [a] -> b; } -> b
  */
  match = xs: { nil, cons }@args:
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

  /* take :: int -> [a] -> [a]
  */
  take = n:
    let go = i: (flip match) {
          nil = nil;
          cons = x: xs:
            if i < n
            then cons x (go (i + 1) xs)
            else nil;
        };
    in go 0;

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
  for = flip map;

  /* imap :: (int -> a -> b) -> [a] -> [b]
  */
  imap = f:
    let go = i:
          (flip match) {
            nil = [];
            cons = x: xs: cons (f i x) (go (i + 1) xs);
          };
    in go 0;

  /* ifor :: [a] -> (int -> a -> b) -> [b]
  */
  ifor = flip imap;

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
  foldr = k: z0:
    let go = (flip match) {
          nil = z0;
          cons = x: xs: k x (go xs);
        };
    in go;

  /* foldl' :: (b -> a -> b) -> b -> [a] -> b
  */
  foldl' = builtins.foldl';

  /* foldMap :: Monoid m => (a -> m) -> [a] -> m
  */
  foldMap = m: f: foldr (compose m.append f) m.empty;

  sum = foldl' (x: y: builtins.add x y) 0;

  product = foldl' (x: y: builtins.mul x y) 1;

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

  /* parition :: (a -> bool) -> [a] -> ([a], [a])
  */
  partition = p: xs:
    let bp = builtins.partition p xs;
    in { _0 = bp.right; _1 = bp.wrong; };

  /* traverse :: Applicative f => (a -> f b) -> [a] -> [f b]
  */
  traverse = ap: f: foldr (x: ap.lift2 cons (f x)) (ap.pure nil);

  /* zipWith :: (a -> b -> c) -> [a] -> [b] -> [c]
  */
  zipWith = f:
    let go = xs0: ys0:
          match xs0 {
            nil = nil;
            cons = x: xs: match ys0 {
              nil = nil;
              cons = y: ys: cons (f x y) (go xs ys);
            };
          };
    in go;

  /* zip :: [a] -> [b] -> [{ _0 :: a, _1 :: b }]
  */
  zip = zipWith (x: y: { _0 = x; _1 = y; });
}
