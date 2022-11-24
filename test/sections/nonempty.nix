with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.nonempty" {
  check = string.unlines [
    (assertEqual true (types.nonEmpty.check (nonempty.make 3 [2 1])))
    (assertEqual false (types.nonEmpty.check (nonempty.make 3 "foo")))
    (assertEqual false (types.nonEmpty.check [ 1 ]))
    (assertEqual false (types.nonEmpty.check (nonempty.make 3 [2 1] // { foo = "bar"; })))
    (assertEqual true ((types.nonEmptyOf types.int).check (nonempty.make 3 [2 1])))
    (assertEqual false ((types.nonEmptyOf types.int).check (nonempty.make 3 [2 "foo"])))
    (assertEqual true ((types.nonEmptyListOf types.int).check (nonempty.toList (nonempty.make 3 [2 1]))))
  ];

  show = string.unlines [
    (assertEqual "nonempty [ 0 ]" (types.nonEmpty.show (nonempty.make 0 [])))
    (assertEqual "nonempty [ 0, 1 ]" (types.nonEmpty.show (nonempty.make 0 [1])))
  ];

  laws = string.unlines [
    (functor nonempty.functor {
      typeName = "nonempty";
      identity = {
        x = nonempty.unsafeFromList [1 2 3 4 5];
      };
      composition = {
        f = x: nonempty.semigroup.append x x;
        g = nonempty.singleton;
        x = nonempty.unsafeFromList [1 2 3 4 5];
      };
    })
    (applicative nonempty.applicative {
      typeName = "nonempty";
      identity = {
        v = nonempty.unsafeFromList [1 2 3 4];
      };
      composition = {
        u = nonempty.unsafeFromList [
          (b: builtins.toString (b + 1))
          (b: builtins.toString (b * 2))
          (b: builtins.toString (5 * (b + 1)))
        ];
        v = nonempty.unsafeFromList [
          (a: a + 1)
          (a: a * 2)
          (b: 5 * (b + 1))
        ];
        w = nonempty.unsafeFromList [ 1 2 3 4 5 ];
      };
      homomorphism = {
        f = builtins.toString;
        x = 5;
      };
      interchange = {
        u = nonempty.ifor
              (nonempty.unsafeFromList ["foo" "bar" "baz"])
              (i: s: (u: builtins.toString u + "-" + s + "-" + builtins.toString i));
        y = 20.0;
      };
    })
    (monad nonempty.monad {
      typeName = "nonempty";
      leftIdentity = {
        f = x: nonempty.make x [x x];
        x = 10;
      };
      rightIdentity = {
        x = nonempty.unsafeFromList (list.range 1 10);
      };
      associativity = {
        m = nonempty.unsafeFromList [1 2 3 4 5];
        f = x: nonempty.singleton (x + 1);
        g = x: nonempty.unsafeFromList (list.range x (x + 1));
      };
    })
    (semigroup nonempty.semigroup {
      typeName = "nonempty";
      associativity = {
        a = nonempty.unsafeFromList [1 2];
        b = nonempty.unsafeFromList ["foo" "bar"];
        c = nonempty.unsafeFromList [true false];
      };
    })
  ];

  match =
    let ls = nonempty.unsafeFromList ["foo" "baz" "bow" "bar" "bed"];
        go = xs0: nonempty.match xs0 {
          cons = _: xs: builtins.head xs;
        };
    in assertEqual "baz" (go ls);

  fromList = string.unlines [
    (assertEqual optional.nothing (nonempty.fromList []))
    (assertEqual (optional.just (nonempty.singleton 1)) (nonempty.fromList [1]))
    (assertEqual (optional.just (nonempty.make 1 [2])) (nonempty.fromList [1 2]))
  ];

  unsafeFromList = string.unlines [
    (assertEqual false ((builtins.tryEval (nonempty.unsafeFromList [])).success))
    (assertEqual (nonempty.singleton 1) (nonempty.unsafeFromList [1]))
    (assertEqual (nonempty.make 1 [2]) (nonempty.unsafeFromList [1 2]))
  ];

  toList = string.unlines [
    (assertEqual [1] (nonempty.toList (nonempty.singleton 1)))
    (assertEqual [1 2] (nonempty.toList (nonempty.make 1 [2])))
  ];

  head = assertEqual 10 (nonempty.head (nonempty.make 10 [20 30]));
  tail = assertEqual [20 30] (nonempty.tail (nonempty.make 10 [20 30]));
  init = assertEqual [10 20] (nonempty.init (nonempty.make 10 [20 30]));
  last = assertEqual 30 (nonempty.last (nonempty.make 10 [20 30]));

  take = let xs = nonempty.unsafeFromList (list.range 1 20); in string.unlines [
    (assertEqual [1 2 3 4] (nonempty.take 4 xs))
    (assertEqual (nonempty.toList xs) (nonempty.take 100 xs))
  ];

  drop = let xs = nonempty.unsafeFromList (list.range 1 20); in string.unlines [
    (assertEqual (list.range 5 20) (nonempty.drop 4 xs))
    (assertEqual [] (nonempty.drop 100 xs))
    (assertEqual (nonempty.toList xs) (nonempty.drop (-1) xs))
  ];

  takeEnd = let xs = nonempty.unsafeFromList (list.range 1 20); in string.unlines [
    (assertEqual [17 18 19 20] (nonempty.takeEnd 4 xs))
    (assertEqual (nonempty.toList xs) (nonempty.takeEnd 100 xs))
    (assertEqual [] (nonempty.takeEnd (-1) xs))
  ];

  dropEnd = let xs = nonempty.unsafeFromList (list.range 1 20); in string.unlines [
    (assertEqual (list.range 1 16) (nonempty.dropEnd 4 xs))
    (assertEqual [] (nonempty.dropEnd 100 xs))
    (assertEqual (nonempty.toList xs) (nonempty.dropEnd (-1) xs))
  ];

  length = assertEqual 20 (nonempty.length (nonempty.unsafeFromList (list.range 1 20)));
  singleton = assertEqual (nonempty.make 10 []) (nonempty.singleton 10);
  map = assertEqual (nonempty.make "foo-0" [ "foo-1" ]) (nonempty.map (i: "foo-" + builtins.toString i) (nonempty.make 0 [ 1 ]));
  for = assertEqual (nonempty.make "foo-0" [ "foo-1" ]) (nonempty.for (nonempty.make 0 [1]) (i: "foo-" + builtins.toString i));
  imap = assertEqual (nonempty.make "foo-0" [ "bar-1" ]) (nonempty.imap (i: s: s + "-" + builtins.toString i) (nonempty.make "foo" [ "bar" ]));
  ifor = assertEqual (nonempty.make "foo-0" [ "bar-1" ]) (nonempty.ifor (nonempty.make "foo" [ "bar" ]) (i: s: s + "-" + builtins.toString i));
  modifyAt = string.unlines [
    (assertEqual (nonempty.make 1 [ 20 3 ]) (nonempty.modifyAt 1 (x: 10 * x) (nonempty.make 1 [ 2 3 ])))
    (assertEqual (nonempty.make 1 [ 2 3 ]) (nonempty.modifyAt (-3) (x: 10 * x) (nonempty.make 1 [ 2 3 ])))
  ];
  setAt = string.unlines [
    (assertEqual (nonempty.make 1 [ 20 3 ]) (nonempty.setAt 1 20 (nonempty.make 1 [ 2 3 ])))
    (assertEqual (nonempty.make 1 [ 2 3 ]) (nonempty.setAt (-3) 20 (nonempty.make 1 [ 2 3 ])))
  ];
  insertAt = string.unlines [
    (assertEqual (nonempty.make 1 [ 20 2 3 ]) (nonempty.insertAt 1 20 (nonempty.make 1 [ 2 3 ])))
    (assertEqual (nonempty.make 20 [ 1 2 3 ]) (nonempty.insertAt 0 20 (nonempty.make 1 [ 2 3 ])))
    (assertEqual (nonempty.make 1 [ 2 3 20 ]) (nonempty.insertAt 3 20 (nonempty.make 1 [ 2 3 ])))
  ];
  unsafeIndex = string.unlines [
    (assertEqual "bar" (nonempty.unsafeIndex (nonempty.make "bar" ["ry" "barry"]) 0))
    (assertEqual "barry" (nonempty.unsafeIndex (nonempty.make "bar" ["ry" "barry"]) 2))
  ];
  index = string.unlines [
    (assertEqual (optional.just "bar") (nonempty.index (nonempty.make "bar" ["ry" "barry"]) 0))
    (assertEqual (optional.just "barry") (nonempty.index (nonempty.make "bar" ["ry" "barry"]) 2))
    (assertEqual optional.nothing (nonempty.index (nonempty.make "bar" ["ry" "barry"]) 3))
  ];
  filter = assertEqual ["foo" "fun" "friends"] (nonempty.filter (string.hasPrefix "f") (nonempty.make "foo" ["oof" "fun" "nuf" "friends" "sdneirf"]));
  elem = assertEqual builtins.true (nonempty.elem "friend" (nonempty.make "texas" ["friend" "amigo"]));
  notElem = assertEqual builtins.true (nonempty.notElem "foo" (nonempty.make "texas" ["friend" "amigo"]));
  cons = assertEqual (nonempty.make 1 [2 3 4 5]) (nonempty.cons 1 (nonempty.make 2 [3 4 5]));
  uncons = assertEqual { _0 = 1; _1 = [2 3 4 5]; } (nonempty.uncons (nonempty.make 1 [2 3 4 5]));
  snoc = assertEqual (nonempty.make 1 [2 3 4 5]) (nonempty.snoc (nonempty.make 1 [2 3 4]) 5);

  foldr = assertEqual 55 (nonempty.foldr builtins.add (nonempty.unsafeFromList (list.range 1 10)));
  foldl' = assertEqual 3628800 (nonempty.foldl' builtins.mul (nonempty.unsafeFromList (list.range 1 10)));
  foldMap = string.unlines [
    (assertEqual 1 (nonempty.foldMap std.semigroup.first id (nonempty.unsafeFromList (list.range 1 10))))
    (assertEqual 321 ((nonempty.foldMap std.semigroup.endo id (nonempty.make (x: builtins.mul x 3) [ (x: builtins.add x 7) (x: num.pow x 2) ])) 10))
  ];
  fold = string.unlines [
    (assertEqual 1 (nonempty.fold std.semigroup.first (nonempty.unsafeFromList (list.range 1 10))))
    (assertEqual 321 ((nonempty.fold std.semigroup.endo (nonempty.make (x: builtins.mul x 3) [ (x: builtins.add x 7) (x: num.pow x 2) ])) 10))
  ];
  sum = assertEqual 55 (nonempty.sum (nonempty.unsafeFromList (list.range 1 10)));
  product = assertEqual 3628800 (nonempty.product (nonempty.unsafeFromList (list.range 1 10)));
  any = string.unlines [
    (assertEqual true (nonempty.any num.even (nonempty.make 1 [2 3 4 5])))
    (assertEqual false (nonempty.any num.even (nonempty.make 1 [3 5])))
  ];
  all = string.unlines [
    (assertEqual true (nonempty.all num.even (nonempty.unsafeFromList (list.generate (i: builtins.mul i 2) 10))))
    (assertEqual false (nonempty.all num.even (nonempty.make 2 [4 5 8])))
  ];
  none = string.unlines [
    (assertEqual true (nonempty.none num.odd (nonempty.unsafeFromList (list.generate (i: builtins.mul i 2) 10))))
    (assertEqual false (nonempty.none num.odd (nonempty.make 2 [4 5 8])))
  ];
  count = assertEqual 11 (nonempty.count num.even (nonempty.unsafeFromList (list.generate id 21)));
  slice = string.unlines [
    (assertEqual [3 4] (nonempty.slice 2 2 (nonempty.make 1 [2 3 4 5])))
    (assertEqual [3 4 5] (nonempty.slice 2 30 (nonempty.make 1 [2 3 4 5])))
    (assertEqual [2 3 4 5] (nonempty.slice 1 null (nonempty.make 1 [2 3 4 5])))
  ];
  zipWith = assertEqual
    (nonempty.make "foo-0" ["foo-1" "foo-2"])
    (nonempty.zipWith (s: i: s + "-" + builtins.toString i) (nonempty.unsafeFromList (list.replicate 10 "foo")) (nonempty.unsafeFromList (list.range 0 2)));
  zip = assertEqual
    (nonempty.make { _0 = "foo"; _1 = 0; } [{ _0 = "foo"; _1 = 1; } { _0 = "foo"; _1 = 2; }])
    (nonempty.zip (nonempty.unsafeFromList (list.replicate 10 "foo")) (nonempty.unsafeFromList (list.range 0 2)));
  sequence = string.unlines [
    (let ls = nonempty.unsafeFromList (list.range 1 10); in assertEqual ls (nonempty.sequence nullable.applicative ls))
    (let ls = nonempty.unsafeFromList (list.range 1 10); in assertEqual null (nonempty.sequence nullable.applicative (nonempty.snoc ls null)))
  ];
  traverse = string.unlines [
    (let ls = nonempty.unsafeFromList (list.range 1 10); in assertEqual ls (nonempty.traverse nullable.applicative (x: if (num.even x || num.odd x) then x else null) ls))
  ];
  reverse = string.unlines [
    (assertEqual (nonempty.make 3 [2 1]) (nonempty.reverse (nonempty.make 1 [2 3])))
    (assertEqual (nonempty.make 1 []) (nonempty.reverse (nonempty.make 1 [])))
  ];
}
