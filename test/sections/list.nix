with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.list" {
  laws = string.unlines [
    (functor list.functor {
      typeName = "list";
      identity = {
        x = [1 2 3 4 5];
      };
      composition = {
        f = x: x ++ x;
        g = list.singleton;
        x = [1 2 3 4 5];
      };
    })
    (applicative list.applicative {
      typeName = "list";
      identity = {
        v = [1 2 3 4];
      };
      composition = {
        u = [
          (b: builtins.toString (b + 1))
          (b: builtins.toString (b * 2))
          (b: builtins.toString (5 * (b + 1)))
        ];
        v = [
          (a: a + 1)
          (a: a * 2)
          (b: 5 * (b + 1))
        ];
        w = [ 1 2 3 4 5];
      };
      homomorphism = {
        f = builtins.toString;
        x = 5;
      };
      interchange = {
        u = list.ifor
              ["foo" "bar" "baz"]
              (i: s: (u: builtins.toString u + "-" + s + "-" + builtins.toString i));
        y = 20.0;
      };
    })
    (monad list.monad {
      typeName = "list";
      leftIdentity = {
        f = x: [x x x];
        x = 10;
      };
      rightIdentity = {
        x = list.range 1 10;
      };
      associativity = {
        m = [1 2 3 4 5];
        f = x: list.singleton (x + 1);
        g = x: list.range x (x + 1);
      };
    })
    (semigroup list.semigroup {
      typeName = "list";
      associativity = {
        a = [1 2];
        b = ["foo" "bar"];
        c = [true false];
      };
    })
    (monoid list.monoid {
      typeName = "list";
      leftIdentity = {
        x = [1 2];
      };
      rightIdentity = {
        x = [1 2];
      };
    })
  ];

  match =
    let ls = ["foo" "baz" "bow" "bar" "bed"];
        go = xs0: list.match xs0 {
          nil = throw "std.list.match test reached end of list";
          cons = x: xs:
            if x == "bar"
            then x
            else go xs;
        };
    in assertEqual "bar" (go ls);

  empty = string.unlines [
    (assertEqual true (list.empty []))
    (assertEqual false (list.empty [null]))
  ];

  head = assertEqual 10 (list.head [10 20 30]);
  tail = assertEqual [20 30] (list.tail [10 20 30]);
  init = assertEqual [10 20] (list.init [10 20 30]);

  last = assertEqual 30 (list.last [10 20 30]);

  take = let xs = list.range 1 20; in string.unlines [
    (assertEqual [1 2 3 4] (list.take 4 xs))
    (assertEqual xs (list.take 100 xs))
  ];

  drop = let xs = list.range 1 20; in string.unlines [
    (assertEqual (list.range 5 20) (list.drop 4 xs))
    (assertEqual [] (list.drop 100 xs))
    (assertEqual xs (list.drop (-1) xs))
  ];

  takeEnd = let xs = list.range 1 20; in string.unlines [
    (assertEqual [17 18 19 20] (list.takeEnd 4 xs))
    (assertEqual xs (list.takeEnd 100 xs))
    (assertEqual [] (list.takeEnd (-1) xs))
  ];

  dropEnd = let xs = list.range 1 20; in string.unlines [
    (assertEqual (list.range 1 16) (list.dropEnd 4 xs))
    (assertEqual [] (list.dropEnd 100 xs))
    (assertEqual xs (list.dropEnd (-1) xs))
  ];
  length = assertEqual 20 (list.length (list.range 1 20));
  singleton = assertEqual [10] (list.singleton 10);
  map = assertEqual ["foo-0" "foo-1"] (list.map (i: "foo-" + builtins.toString i) [0 1]);
  for = assertEqual ["foo-0" "foo-1"] (list.for [0 1] (i: "foo-" + builtins.toString i));
  imap = assertEqual ["foo-0" "bar-1"] (list.imap (i: s: s + "-" + builtins.toString i) ["foo" "bar"]);
  modifyAt = string.unlines [
    (assertEqual [ 1 20 3 ] (list.modifyAt 1 (x: 10 * x) [ 1 2 3 ]))
    (assertEqual [ 1 2 3 ] (list.modifyAt (-3) (x: 10 * x) [ 1 2 3 ]))
  ];
  setAt = string.unlines [
    (assertEqual [ 1 20 3 ] (list.setAt 1 20 [ 1 2 3 ]))
    (assertEqual [ 1 2 3 ] (list.setAt (-3) 20 [ 1 2 3 ]))
  ];
  insertAt = string.unlines [
    (assertEqual [ 1 20 2 3 ] (list.insertAt 1 20 [ 1 2 3 ]))
    (assertEqual [ 20 1 2 3 ] (list.insertAt 0 20 [ 1 2 3 ]))
    (assertEqual [ 1 2 3 20 ] (list.insertAt 3 20 [ 1 2 3 ]))
  ];
  ifor = assertEqual ["foo-0" "bar-1"] (list.ifor ["foo" "bar"] (i: s: s + "-" + builtins.toString i));
  elemAt = assertEqual "barry" (list.elemAt ["bar" "ry" "barry"] 2);
  index = assertEqual "barry" (list.index ["bar" "ry" "barry"] 2);
  concat = assertEqual ["foo" "bar" "baz" "quux"] (list.concat [["foo"] ["bar"] ["baz" "quux"]]);
  filter = assertEqual ["foo" "fun" "friends"] (list.filter (string.hasPrefix "f") ["foo" "oof" "fun" "nuf" "friends" "sdneirf"]);
  elem = assertEqual builtins.true (list.elem "friend" ["texas" "friend" "amigo"]);
  notElem = assertEqual builtins.true (list.notElem "foo" ["texas" "friend" "amigo"]);
  generate = string.unlines [
    (assertEqual (list.range 0 4) (list.generate id 5))
  ];
  nil = assertEqual [] list.nil;
  cons = assertEqual [1 2 3 4 5] (list.cons 1 [2 3 4 5]);
  uncons = string.unlines [
    (assertEqual optional.nothing (list.uncons []))
    (assertEqual (optional.just { _0 = 1; _1 = [2 3]; }) (list.uncons [1 2 3]))
  ];
  snoc = assertEqual [1 2 3 4 5] (list.snoc [1 2 3 4] 5);

  foldr = assertEqual 55 (list.foldr builtins.add 0 (list.range 1 10));
  foldl' = assertEqual 3628800 (list.foldl' builtins.mul 1 (list.range 1 10));
  foldMap = string.unlines [
    (assertEqual (optional.just 1) (list.foldMap std.monoid.first optional.just (list.range 1 10)))
    (assertEqual 321 ((list.foldMap std.monoid.endo id [ (x: builtins.mul x 3) (x: builtins.add x 7) (x: num.pow x 2) ]) 10))
  ];
  fold = string.unlines [
    (assertEqual (optional.just 1) (list.fold std.monoid.first (list.map optional.just (list.range 1 10))))
    (assertEqual 321 ((list.fold std.monoid.endo [ (x: builtins.mul x 3) (x: builtins.add x 7) (x: num.pow x 2) ]) 10))
  ];
  sum = assertEqual 55 (list.sum (list.range 1 10));
  product = assertEqual 3628800 (list.product (list.range 1 10));
  concatMap = assertEqual (list.replicate 3 "foo" ++ list.replicate 3 "bar" ++ list.replicate 3 "baz") (list.concatMap (s: [s s s]) ["foo" "bar" "baz"]);
  any = string.unlines [
    (assertEqual true (list.any num.even [1 2 3 4 5]))
    (assertEqual false (list.any num.even [1 3 5]))
    (assertEqual false (list.any (const true) []))
    (assertEqual false (list.any (const false) []))
  ];
  all = string.unlines [
    (assertEqual true (list.all num.even (list.generate (i: builtins.mul i 2) 10)))
    (assertEqual false (list.all num.even [2 4 5 8]))
    (assertEqual true (list.all (const true) []))
    (assertEqual true (list.all (const false) []))
  ];
  none = string.unlines [
    (assertEqual true (list.none num.odd (list.generate (i: builtins.mul i 2) 10)))
    (assertEqual false (list.none num.odd [2 4 5 8]))
  ];
  count = assertEqual 11 (list.count num.even (list.generate id 21));
  optional = string.unlines [
    (assertEqual [] (list.optional false null))
    (assertEqual ["foo"] (list.optional true "foo"))
  ];
  optionals = string.unlines [
    (assertEqual [] (list.optionals false null))
    (assertEqual [1 2 3] (list.optionals true [1 2 3]))
  ];
  replicate = assertEqual [1 1 1 1 1 1] (list.replicate 6 1);
  slice = string.unlines [
    (assertEqual [3 4] (list.slice 2 2 [ 1 2 3 4 5 ]))
    (assertEqual [3 4 5] (list.slice 2 30 [ 1 2 3 4 5 ]))
    (assertEqual [2 3 4 5] (list.slice 1 null [ 1 2 3 4 5 ]))
  ];
  range = assertEqual [1 2 3 4 5] (list.range 1 5);
  partition = string.unlines [
    (assertEqual { _0 = [1 3 5 7]; _1 = [0 2 4 6 8]; } (list.partition num.odd (list.range 0 8)))
    (assertEqual { _0 = ["foo" "fum"]; _1 = ["haha"]; } (list.partition (string.hasPrefix "f") ["foo" "fum" "haha"]))
  ];
  zipWith = assertEqual
    ["foo-0" "foo-1" "foo-2"]
    (list.zipWith (s: i: s + "-" + builtins.toString i) (list.replicate 10 "foo") (list.range 0 2));
  zip = assertEqual
    [{ _0 = "foo"; _1 = 0; } { _0 = "foo"; _1 = 1; } { _0 = "foo"; _1 = 2; }]
    (list.zip (list.replicate 10 "foo") (list.range 0 2));
  sequence = string.unlines [
    (let ls = list.range 1 10; in assertEqual ls (list.sequence nullable.applicative ls))
    (let ls = list.range 1 10; in assertEqual null (list.sequence nullable.applicative (ls ++ [null])))
  ];
  traverse = string.unlines [
    (let ls = list.range 1 10; in assertEqual ls (list.traverse nullable.applicative (x: if (num.even x || num.odd x) then x else null) ls))
  ];
  reverse = string.unlines [
    (assertEqual [3 2 1] (list.reverse [1 2 3]))
    (assertEqual [] (list.reverse []))
  ];

  unfold = assertEqual [10 9 8 7 6 5 4 3 2 1]
    (list.unfold (n: if n == 0 then optional.nothing else optional.just { _0 = n; _1 = n - 1; }) 10);

  findIndex = string.unlines [
    (assertEqual (optional.just 1) (list.findIndex num.even [ 1 2 3 4 ]))
    (assertEqual optional.nothing (list.findIndex num.even [ 1 3 5 ]))
  ];

  findLastIndex = string.unlines [
    (assertEqual (optional.just 3) (list.findLastIndex num.even [ 1 2 3 4 ]))
    (assertEqual optional.nothing (list.findLastIndex num.even [ 1 3 5 ]))
  ];

  find = string.unlines [
    (assertEqual (optional.just 2) (list.find num.even [ 1 2 3 4 ]))
    (assertEqual optional.nothing (list.find num.even [ 1 3 5 ]))
  ];

  findLast = string.unlines [
    (assertEqual (optional.just 4) (list.findLast num.even [ 1 2 3 4 ]))
    (assertEqual optional.nothing (list.findLast num.even [ 1 3 5 ]))
  ];

  splitAt = assertEqual { _0 = [ 1 ]; _1 = [ 2 3 ]; } (list.splitAt 1 [ 1 2 3 ]);

  takeWhile = assertEqual [ 2 4 6 ] (list.takeWhile num.even [ 2 4 6 9 10 11 12 14 ]);

  dropWhile = assertEqual [ 9 10 11 12 14 ] (list.dropWhile num.even [ 2 4 6 9 10 11 12 14 ]);

  takeWhileEnd = assertEqual [ 12 14 ] (list.takeWhileEnd num.even [ 2 4 6 9 10 11 12 14 ]);

  dropWhileEnd = assertEqual [ 2 4 6 9 10 11 ] (list.dropWhileEnd num.even [ 2 4 6 9 10 11 12 14 ]);

  span = assertEqual { _0 = [ 2 4 6 ]; _1 = [ 9 10 11 12 14 ]; }
    (list.span num.even [ 2 4 6 9 10 11 12 14 ]);

  break = assertEqual { _0 = [ 2 4 6 ]; _1 = [ 9 10 11 12 14 ]; }
    (list.break num.odd [ 2 4 6 9 10 11 12 14 ]);
}
