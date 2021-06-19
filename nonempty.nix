with rec {
  function = import ./function.nix;
  inherit (function) const flip compose id;

  num = import ./num.nix;
  inherit (num) min max;

  list = import ./list.nix;
  optional = import ./optional.nix;
};

rec {
  /* List functor object
  */
  functor = {
    /* map :: (a -> b) -> nonempty a -> nonempty b
    */
    inherit map;
  };

  /* List applicative object
  */
  applicative = functor // rec {
    /* pure :: a -> nonempty a
    */
    pure = singleton;
    /* ap :: nonempty a -> b -> nonempty a -> nonempty b
    */
    ap = lift2 id;
    /* lift2 :: (a -> b -> c) -> nonempty a -> nonempty b -> nonempty c
    */
    lift2 = f: xs: ys: monad.bind xs (x: monad.bind ys (y: singleton (f x y)));
  };

  /* List monad object
  */
  monad = applicative // {
    /* join :: nonempty (nonempty a) -> nonempty a
    */
    join = concat;

    /* bind :: nonempty a -> (a -> nonempty b) -> nonempty b
    */
    bind = flip concatMap;
  };

  monadFix = monad // {
    /* fix :: (a -> nonempty a) -> nonempty a
    */
    fix = f: match (fix (compose f head)) {
      nil = nil;
      cons = x: _: cons x (fix (compose tail f));
    };
  };

  /* Nonempty list semigroup object
  */
  semigroup = {
    /* append :: nonempty a -> nonempty a -> nonempty a
    */
    append = xs: ys: xs ++ ys;
  };

  fromList = xs:
    if builtins.length xs == 0
    then builtins.throw "std.nonempty.fromList: empty list"
    else { head = list.head xs; tail = list.tail xs; };

  toList = { head, tail }: [head] ++ tail;

  nonEmpty = xs:
    if builtins.length xs == 0
    then optional.nothing
    else optional.just (fromList xs);

  /* match :: nonempty a -> { cons :: a -> [a] -> b; } -> b

     Pattern match on a nonempty list. As the list is never empty, 'cons' is run
     on the head and tail of the list.
  */
  match = xs: { cons }@args: args.cons xs.head xs.tail;

  /* head :: nonempty a -> a

     Get the first element of a nonempty list.
  */
  head = builtins.head;

  /* tail :: nonempty a -> [a]

     Return the list minus the first element, which may be an empty list.
  */
  tail = builtins.tail;

  /* init :: nonempty a -> [a]

     Return the list minus the last element, which may be an empty list.
  */
  init = { head, tail }:
    if builtins.length tail == 0
    then [head]
    else [head] ++ list.init tail;

  /* last :: [a] -> a

     Get the last element of a nonempty list.
  */
  last = { head, tail }:
    if builtins.length tail == 0
    then head
    else list.last tail;

  /* take :: int -> nonempty a -> [a]

     Take the first n elements of a list. If there are less than n elements,
     return as many elements as possible.
  */
  take = builtins.throw "TODO";

  /* drop :: int -> nonempty a -> [a]

     Return the list minus the first n elements. If there are less than n
     elements, return the empty list.
  */
  drop = builtins.throw "TODO";

  /* takeEnd :: int -> nonempty a -> [a]

     Take the last n elements of a list. If there are less than n elements,
     return as many elements as possible.
  */
  takeEnd = builtins.throw "TODO";

  /* dropEnd :: int -> nonempty a -> [a]

     Return the list minus the last n elements. If there are less than n
     elements, return the empty list.
  */
  dropEnd = builtins.throw "TODO";

  /* length :: nonempty a -> int

     Return the length of a nonempty list.
  */
  length = { head, tail }: builtins.length tail + 1;

  /* singleton :: a -> nonempty a

     Wrap an element in a singleton list.
  */
  singleton = head: { inherit head; tail = []; };

  /* map :: (a -> b) -> nonempty a -> nonempty b

     Apply a function to every element of a nonempty list, returning the
     resulting list.
  */
  map = builtins.throw "TODO";

  /* for :: nonempty a -> (a -> b) -> nonempty b

     Like 'map', but with its arguments reversed.
  */
  for = flip map;

  /* imap :: (int -> a -> b) -> nonempty a -> nonempty b

     Apply a function to every element of a list and its index, returning the
     resulting list.
  */
  imap = builtins.throw "TODO";

  /* modifyAt :: int -> (a -> a) -> nonempty a -> nonempty a

     Apply a function to the nth element of a list, returning the new list. If
     the index is out of bounds, return the list unchanged.
  */
  modifyAt = builtins.throw "TODO";

  /* insertAt :: int -> a -> nonempty a -> nonempty a

     Insert an element as the nth element of a list, returning the new list. If
     the index is out of bounds, return the list unchanged.
  */
  insertAt = builtins.throw "TODO";

  /* ifor :: nonempty a -> (int -> a -> b) -> nonempty b

     Like 'imap', but with its arguments reversed.
  */
  ifor = flip imap;

  /* @partial
     elemAt :: nonempty a -> int -> a

     Get the nth element of a list, indexed from 0.
  */
  elemAt = builtins.elemAt;

  /* @partial
     index :: nonempty a -> int -> a

     Get the nth element of a list, indexed from 0. An alias for 'elemAt'.
  */
  index = builtins.elemAt;

  /* filter :: (a -> bool) -> nonempty a -> [a]

     Apply a predicate to a list, keeping only the elements that match the
     predicate.
  */
  filter = builtins.throw "TODO";

  /* elem :: a -> nonempty a -> bool

     Check if an element is contained in a list.
  */
  elem = builtins.throw "TODO";

  /* notElem :: a -> nonempty a -> bool

     Check if an element is not contained in a list.
  */
  notElem = builtins.throw "TODO";

  /* cons :: a -> nonempty a -> nonempty a

     Prepend an element to a nonempty list
  */
  cons = x: xs: { head = x; tail = [xs.head] ++ xs.tail; };

  /* uncons :: nonempty a -> (a, [a])

     Split a nonempty list into its head and tail.
  */
  uncons = { head, tail }: { _0 = head; _1 = tail; };

  /* snoc :: nonempty a -> a -> nonempty a

     Append an element to a nonempty list
  */
  snoc = xs: x: { head = xs.head; tail = xs.tail ++ [x]; };

  /* foldr :: (a -> b -> b) -> [a] -> b

     Right-associative fold over a nonempty list.
  */
  foldr = builtins.throw "TODO";

  /* foldl' :: (b -> a -> b) -> [a] -> b

     Strict left-associative fold over a nonempty list.
  */
  foldl' = builtins.throw "TODO";

  /* foldMap :: Semigroup m => (a -> m) -> nonempty a -> m

     Apply a function to each element of a list, turning it into a semigroup,
     and append all the results using the provided semigroup.
  */
  foldMap = builtins.throw "TODO";

  /* fold :: Semigroup m => nonempty m -> m

     Append all elements of a list using a provided semigroup.
  */
  fold = builtins.throw "TODO";

  /* sum :: nonempty number -> number

     Sum a nonempty list of numbers.
  */
  sum = foldl' builtins.add;

  /* product :: [number] -> number

     Take the product of a list of numbers.

     > list.product [ 1 2 3 4 ]
     24
  */
  product = foldl' builtins.mul;

  /* any :: (a -> bool) -> nonempty a -> bool

     Check if any element of a list matches a predicate.
  */
  any = builtins.throw "TODO";

  /* all :: (a -> bool) -> nonempty a -> bool

     Check if every element of a list matches a predicate. Note that if a list
     is empty, the predicate matches every element vacuously.
  */
  all = builtins.throw "TODO";

  /* count :: (a -> bool) -> nonempty a -> int

     Count the number of times a predicate holds on the elements of a list.
  */
  count = builtins.throw "TODO";

  /* sequence :: Ap f => nonempty (f a) -> f (nonempty a)

     Sequence a nonempty list using the provided applicative functor.
  */
  traverse = builtins.throw "TODO";


  /* traverse :: Ap f => (a -> f b) -> nonempty a -> f (nonempty b)

     Apply a function to every element of a list, and sequence the results using
     the provided applicative functor.
  */
  traverse = builtins.throw "TODO";

  /* zipWith :: (a -> b -> c) -> nonempty a -> nonempty b -> nonempty c

     Zip two lists together with the provided function. The resulting list has
     length equal to the length of the shorter list.
  */
  zipWith = builtins.throw "TODO";

  /* zip :: nonempty a -> nonempty b -> nonempty (a, b)

     Zip two lists together into a list of tuples. The resulting list has length
     equal to the length of the shorter list.
  */
  zip = zipWith (x: y: { _0 = x; _1 = y; });

  /* reverse :: nonempty a -> nonempty a

     Reverse a nonempty list.
  */
  reverse = builtins.throw "TODO";
}
