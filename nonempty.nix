with rec {
  function = import ./function.nix;
  inherit (function) const flip compose id;

  num = import ./num.nix;
  inherit (num) min max;

  list = import ./list.nix;
  optional = import ./optional.nix;
};

/* type nonempty a = { head :: a, tail :: [a] }
*/
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
  monad = applicative // rec {
    /* join :: nonempty (nonempty a) -> nonempty a
    */
    join = foldl' semigroup.append;

    /* bind :: nonempty a -> (a -> nonempty b) -> nonempty b
    */
    bind = { head, tail }: k:
      let r = k head;
      in make r.head (r.tail ++ list.monad.bind tail (x: toList (k x)));
  };

  monadFix = monad // {
    /* fix :: (a -> nonempty a) -> nonempty a
    */
    fix = f: match (fix (compose f head)) {
      cons = x: _: make x (fix (compose tail f));
    };
  };

  /* Nonempty list semigroup object
  */
  semigroup = {
    /* append :: nonempty a -> nonempty a -> nonempty a
    */
    append = xs: ys: {
      head = xs.head;
      tail = xs.tail ++ [ys.head] ++ ys.tail;
    };
  };

  /* make :: a -> [a] -> nonempty a

     Make a nonempty list from a head and a possibly-empty tail.
  */
  make = head: tail: { inherit head tail; };

  /* fromList :: [a] -> optional (nonempty a)

     Safely convert a list into a nonempty list, returning `optional.nothing` if
     the list is empty.
  */
  fromList = xs:
    if builtins.length xs == 0
    then optional.nothing
    else optional.just (unsafeFromList xs);

  /* @partial
     unsafeFromList :: [a] -> nonempty a

     Unsafely convert a list to a nonempty list. Throws an exception if the list
     is empty.
  */
  unsafeFromList = xs:
    if builtins.length xs == 0
    then builtins.throw "std.nonempty.unsafeFromList: empty list"
    else { head = list.head xs; tail = list.tail xs; };

  /* toList :: nonempty a -> [a]

     Converts the nonempty list to a list by forgetting the invariant that it
     has at least one element.
  */
  toList = { head, tail }: [head] ++ tail;

  /* match :: nonempty a -> { cons :: a -> [a] -> b; } -> b

     Pattern match on a nonempty list. As the list is never empty, 'cons' is run
     on the head and tail of the list.
  */
  match = xs: { cons }@args: args.cons xs.head xs.tail;

  /* head :: nonempty a -> a

     Get the first element of a nonempty list.
  */
  head = x: x.head;

  /* tail :: nonempty a -> [a]

     Return the list minus the first element, which may be an empty list.
  */
  tail = x: x.tail;

  /* init :: nonempty a -> [a]

     Return the list minus the last element, which may be an empty list.
  */
  init = { head, tail }:
    if builtins.length tail == 0
    then []
    else [head] ++ list.init tail;

  /* last :: [a] -> a

     Get the last element of a nonempty list.
  */
  last = { head, tail }:
    if builtins.length tail == 0
    then head
    else list.last tail;

  /* slice :: int -> int -> [a] -> [a]

     Extract a sublist from a list given a starting position and a length. If
     the starting position is past the end of the list, return the empty list.
     If there are fewer than the requested number of elements after the starting
     position, take as many as possible. If the requested length is negative,
     ignore the length and return until the end of the list.

     Fails if the given offset is negative.
  */
  slice = offset: len: { head, tail }:
    if offset < 0
    then builtins.throw "std.nonempty.slice: negative start position"
    else
      let
        remaining = max 0 (builtins.length tail + 1 - offset);
        len' = if len == null then remaining else min (max len 0) remaining;
      in list.generate
        (i:
          let i' = i + offset;
          in if i' == 0
            then head
            else list.index tail (i' - 1)
        )
        len';

  /* take :: int -> nonempty a -> [a]

     Take the first n elements of a list. If there are less than n elements,
     return as many elements as possible.
  */
  take = n: slice 0 (max 0 n);

  /* drop :: int -> nonempty a -> [a]

     Return the list minus the first n elements. If there are less than n
     elements, return the empty list.
  */
  drop = n: slice (max 0 n) null;

  /* takeEnd :: int -> nonempty a -> [a]

     Take the last n elements of a list. If there are less than n elements,
     return as many elements as possible.
  */
  takeEnd = n: xs:
    let
      len = length xs;
      n' = min len n;
    in slice (len - n') n' xs;

  /* dropEnd :: int -> nonempty a -> [a]

     Return the list minus the last n elements. If there are less than n
     elements, return the empty list.
  */
  dropEnd = n: xs: slice 0 (max 0 (length xs - n)) xs;

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
  map = f: { head, tail }: {
    head = f head;
    tail = builtins.map f tail;
  };

  /* for :: nonempty a -> (a -> b) -> nonempty b

     Like 'map', but with its arguments reversed.
  */
  for = flip map;

  /* imap :: (int -> a -> b) -> nonempty a -> nonempty b

     Apply a function to every element of a list and its index, returning the
     resulting list.
  */
  imap = f: { head, tail }: {
    head = f 0 head;
    tail = list.imap (ix: x: f (ix + 1) x) tail;
  };

  /* modifyAt :: int -> (a -> a) -> nonempty a -> nonempty a

     Apply a function to the nth element of a list, returning the new list. If
     the index is out of bounds, return the list unchanged.
  */
  modifyAt = i: f: imap (j: x: if j == i then f x else x);

  /* setAt :: int -> a -> [a] -> [a]

     Insert an element as the nth element of a list, returning the new list. If
     the index is out of bounds, return the list unchanged.

     > list.setAt 1 20 [ 1 2 3 ]
     [ 1 20 3 ]
  */
  setAt = i: x: modifyAt i (const x);

  /* insertAt :: int -> a -> [a] -> [a]

     Insert an element as the nth element of a list, returning the new list. If
     the index is out of bounds, fail with an exception.
  */
  insertAt = i: x: { head, tail }:
    if i < 0 || i > builtins.length tail + 1 then
      builtins.throw "std.nonempty.insertAt: index out of bounds"
    else if i == 0 then
      { head = x; tail = [head] ++ tail; }
    else
      { inherit head; tail = list.insertAt (i - 1) x tail; };

  /* ifor :: nonempty a -> (int -> a -> b) -> nonempty b

     Like 'imap', but with its arguments reversed.
  */
  ifor = flip imap;

  /* @partial
     elemAt :: nonempty a -> int -> a

     Get the nth element of a list, indexed from 0.
  */
  elemAt = { head, tail }: n: if n == 0 then head else builtins.elemAt tail (n - 1);

  /* @partial
     index :: nonempty a -> int -> a

     Get the nth element of a list, indexed from 0. An alias for 'elemAt'.
  */
  index = { head, tail }: n: if n == 0 then head else builtins.elemAt tail (n - 1);

  /* filter :: (a -> bool) -> nonempty a -> [a]

     Apply a predicate to a list, keeping only the elements that match the
     predicate.
  */
  filter = p: xs: list.filter p (toList xs);

  /* elem :: a -> nonempty a -> bool

     Check if an element is contained in a list.
  */
  elem = e: { head, tail }: head == e || builtins.elem e tail;

  /* notElem :: a -> nonempty a -> bool

     Check if an element is not contained in a list.
  */
  notElem = e: { head, tail }: head != e && !(builtins.elem e tail);

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
  foldr = k: { head, tail }:
    let tailLen = builtins.length tail;
        go = n:
          if n == tailLen - 1
          then builtins.elemAt tail n
          else k (builtins.elemAt tail n) (go (n + 1));
    in if tailLen == 0
      then head
      else k head (go 0);

  /* foldl' :: (b -> a -> b) -> [a] -> b

     Strict left-associative fold over a nonempty list.
  */
  foldl' = k: { head, tail }: list.foldl' k head tail;

  /* foldMap :: Semigroup m => (a -> m) -> nonempty a -> m

     Apply a function to each element of a list, turning it into a semigroup,
     and append all the results using the provided semigroup.
  */
  foldMap = s: f: foldr (compose s.append f);

  /* fold :: Semigroup m => nonempty m -> m

     Append all elements of a list using a provided semigroup.
  */
  fold = s: foldr s.append;

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
  any = p: { head, tail }: p head || builtins.any p tail;

  /* all :: (a -> bool) -> nonempty a -> bool

     Check if every element of a list matches a predicate.
  */
  all = p: { head, tail }: p head && builtins.all p tail;

  /* none :: (a -> bool) -> [a] -> bool

     Check that none of the elements in a list match the given predicate.
  */
  none = p: { head, tail }: (!p head) && builtins.all (x: !p x) tail;

  /* count :: (a -> bool) -> nonempty a -> int

     Count the number of times a predicate holds on the elements of a list.
  */
  count = p: { head, tail }: (if p head then 1 else 0) + list.count p tail;

  /* traverse :: Apply f => (a -> f b) -> nonempty a -> f (nonempty b)

     Apply a function to every element of a list, and sequence the results using
     the provided applicative functor.
  */
  traverse = ap: f: { head, tail }:
    let
      tailLen = builtins.length tail;
      go = n:
        if n == tailLen - 1
        then ap.map list.singleton (f (list.index tail n))
        else ap.lift2 list.cons (f (list.index tail n)) (go (n + 1));
    in if tailLen == 0
      then ap.map (x: make x []) (f head)
      else ap.lift2 make (f head) (go 0);

  /* sequence :: Apply f => nonempty (f a) -> f (nonempty a)

     Sequence a nonempty list using the provided applicative functor.
  */
  sequence = ap: { head, tail }:
    let
      tailLen = builtins.length tail;
      go = n:
        if n == tailLen - 1
        then ap.map list.singleton (list.index tail n)
        else ap.lift2 list.cons (list.index tail n) (go (n + 1));
    in if tailLen == 0
      then ap.map (x: make x []) (f head)
      else ap.lift2 make head (go 0);

  /* zipWith :: (a -> b -> c) -> nonempty a -> nonempty b -> nonempty c

     Zip two lists together with the provided function. The resulting list has
     length equal to the length of the shorter list.
  */
  zipWith = f: xs: ys: {
    head = f xs.head ys.head;
    tail = list.zipWith f xs.tail ys.tail;
  };

  /* zip :: nonempty a -> nonempty b -> nonempty (a, b)

     Zip two lists together into a list of tuples. The resulting list has length
     equal to the length of the shorter list.
  */
  zip = zipWith (x: y: { _0 = x; _1 = y; });

  /* reverse :: nonempty a -> nonempty a

     Reverse a nonempty list.
  */
  reverse = { head, tail }@xs:
    let
      tailLen = builtins.length tail;
    in if tailLen == 0
      then xs
      else {
        head = list.last tail;
        tail = list.generate
          (i:
            if i == tailLen - 1
            then head
            else list.index tail (tailLen - i - 2)
          )
          tailLen;
      };
}
