with { std = import ./default.nix; };
with std;

with {
  inherit (import <nixpkgs> {}) stdenv;
};

let
  section = module: tests: ''
    echo "testing ${module}"
    ${string.concat
        (list.map
          (test: ''echo "...${test._0}"...; ${test._1}'')
            (set.toList tests))
     }
  '';

  assertEqual = x: y:
    if x == y
    then string.empty
    else ''
      ERR="
        assertEqual failed: x != y, where

          x = ${string.escape [''"''] (types.show x)}
          y = ${string.escape [''"''] (types.show y)}

      "
      printf "$ERR"
      exit 1
    '';

  lawCheck = { lawName, typeName ? null }: x: y:
    if x == y
    then ''
      printf "[${typeName}] ${lawName}: ✓"
      echo ""
    ''
    else ''
      ERR="
        law does not hold: x != y, where

          x = ${string.escape [''"''] (types.show x)}
          y = ${string.escape [''"''] (types.show y)}

      "
      printf "[${typeName}] ${lawName}: ✗"
      printf "$ERR"
      exit 1
    '';

  functor = functor:
            { typeName
            , identity
            , composition
            }:
    let functorIdentity = xs:
          lawCheck {
            lawName = "functor identity";
            inherit typeName;
          } (functor.map id xs) xs;
        functorComposition = f: g: xs:
          lawCheck {
            lawName = "functor composition";
            inherit typeName;
          } (functor.map (compose f g) xs)
            (functor.map f (functor.map g xs));
    in string.unlines [
         (functorIdentity identity.x)
         (functorComposition composition.f composition.g composition.x)
       ];

  applicative = applicative:
                { typeName
                , identity
                , composition
                , homomorphism
                , interchange
                }:
    let applicativeIdentity = v:
          lawCheck {
            lawName = "applicative identity";
            inherit typeName;
          } (applicative.ap (applicative.pure id) v) v;

        applicativeComposition = u: v: w:
          lawCheck {
            lawName = "applicative composition";
            inherit typeName;
          } (applicative.ap (applicative.ap ((applicative.ap (applicative.pure compose) u)) v) w)
            (applicative.ap u (applicative.ap v w));

        applicativeHomomorphism = f: x:
          lawCheck {
            lawName = "applicative homomorphism";
            inherit typeName;
          } (applicative.ap (applicative.pure f) (applicative.pure x))
            (applicative.pure (f x));

        applicativeInterchange = u: y:
          lawCheck {
            lawName = "applicative interchange";
            inherit typeName;
          } (applicative.ap u (applicative.pure y))
            (applicative.ap (applicative.pure (f: f y)) u);
    in string.unlines [
         (applicativeIdentity identity.v)
         (applicativeComposition composition.u composition.v composition.w)
         (applicativeHomomorphism homomorphism.f homomorphism.x)
         (applicativeInterchange interchange.u interchange.y)
       ];

  monad = monad:
          { typeName
          , leftIdentity
          , rightIdentity
          , associativity
          }:
    let monadLeftIdentity = f: x:
          lawCheck {
            lawName = "monad left identity";
            inherit typeName;
          } (monad.bind (monad.pure x) f) (f x);

        monadRightIdentity = x:
          lawCheck {
            lawName = "monad right identity";
            inherit typeName;
          } (monad.bind x monad.pure) x;

        monadAssociativity = m: f: g:
          lawCheck {
            lawName = "monad associativity";
            inherit typeName;
          } (monad.bind (monad.bind m f) g)
            (monad.bind m (x: monad.bind (f x) g));
    in string.unlines [
         (monadLeftIdentity leftIdentity.f leftIdentity.x)
         (monadRightIdentity rightIdentity.x)
         (monadAssociativity associativity.m associativity.f associativity.g)
       ];

  semigroup = semigroup: { typeName, associativity }:
    let semigroupAssociativity = a: b: c:
          lawCheck {
            lawName = "semigroup associativity";
            inherit typeName;
          } (semigroup.append a (semigroup.append b c))
            (semigroup.append (semigroup.append a b) c);
    in semigroupAssociativity associativity.a associativity.b associativity.c;

  monoid = monoid: { typeName, leftIdentity, rightIdentity }:
    let monoidLeftIdentity = x:
          lawCheck {
            lawName = "monoid left identity";
            inherit typeName;
          } (monoid.append monoid.empty x) x;
        monoidRightIdentity = x:
          lawCheck {
            lawName = "monoid right identity";
            inherit typeName;
          } (monoid.append x monoid.empty) x;
    in string.unlines [
         (monoidLeftIdentity leftIdentity.x)
         (monoidRightIdentity rightIdentity.x)
       ];

  sections = {
    bool = section "std.bool" {
      true = assertEqual builtins.true bool.true;
      false = assertEqual builtins.false bool.false;
      not = string.unlines [
        (assertEqual (bool.not false) true)
        (assertEqual (bool.not true) false)
      ];
      ifThenElse = string.unlines [
        (assertEqual (ifThenElse true "left" "right") "left")
        (assertEqual (ifThenElse false "left" "right") "right")
      ];
    };
    list = section "std.list" {
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

      insertAt = string.unlines [
        (assertEqual [ 1 20 3 ] (list.insertAt 1 20 [ 1 2 3 ]))
        (assertEqual [ 1 2 3 ] (list.insertAt (-3) 20 [ 1 2 3 ]))
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
        (assertEqual null ((list.uncons [])._0.value))
        (assertEqual [1 2 3 4 5] (list.snoc [1 2 3 4] 5))
      ];
      snoc = assertEqual [1 2 3 4 5] (list.snoc [1 2 3 4] 5);

      foldr = assertEqual 55 (list.foldr builtins.add 0 (list.range 1 10));
      foldl' = assertEqual 3628800 (list.foldl' builtins.mul 1 (list.range 1 10));
      foldMap = string.unlines [
        (assertEqual 1 (list.foldMap std.monoid.first id (list.range 1 10)))
        (assertEqual 321 ((list.foldMap std.monoid.endo id [ (x: builtins.mul x 3) (x: builtins.add x 7) (x: num.pow x 2) ]) 10))
      ];
      fold = string.unlines [
        (assertEqual 1 (list.fold std.monoid.first (list.range 1 10)))
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
        (assertEqual [2 3 4 5] (list.slice 1 (-1) [ 1 2 3 4 5 ]))
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
        (assertEqual 1 (list.findIndex num.even [ 1 2 3 4 ]).value)
        (assertEqual null (list.findIndex num.even [ 1 3 5 ]).value)
      ];

      findLastIndex = string.unlines [
        (assertEqual 3 (list.findLastIndex num.even [ 1 2 3 4 ]).value)
        (assertEqual null (list.findLastIndex num.even [ 1 3 5 ]).value)
      ];

      find = string.unlines [
        (assertEqual 2 (list.find num.even [ 1 2 3 4 ]).value)
        (assertEqual null (list.find num.even [ 1 3 5 ]).value)
      ];

      findLast = string.unlines [
        (assertEqual 4 (list.findLast num.even [ 1 2 3 4 ]).value)
        (assertEqual null (list.findLast num.even [ 1 3 5 ]).value)
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
    };

    optional = section "std.optional" {
      laws = string.unlines [
        (functor optional.functor {
          typeName = "optional";
          identity = {
            x = optional.just 5;
          };
          composition = {
            f = optional.monad.join;
            g = optional.just;
            x = optional.just "foo";
          };
        })
        (applicative optional.applicative {
          typeName = "optional";
          identity = {
            v = optional.nothing;
          };
          composition = {
            u = optional.just (b: builtins.toString (b + 1));
            v = optional.just (a: a + 1);
            w = optional.just 5;
          };
          homomorphism = {
            f = builtins.toString;
            x = 5;
          };
          interchange = {
            u = optional.just (x: x + "-" + x);
            y = "foo";
          };
        })
        (monad optional.monad {
          typeName = "optional";
          leftIdentity = {
            f = x: optional.just (x + x);
            x = 5;
          };
          rightIdentity = {
            x = optional.just 55;
          };
          associativity = {
            m = optional.just optional.nothing;
            f = x: optional.match x {
              nothing = optional.just (optional.just 5);
              just = k: optional.just (optional.just (k + 1));
            };
            g = x: optional.match x {
              nothing = optional.just (optional.just 1);
              just = k: optional.just (optional.just (k + 5));
            };
          };
        })
        (semigroup (optional.semigroup list.semigroup) {
          typeName = "optional";
          associativity = {
            a = optional.just [1 2 3 4];
            b = optional.just [5 6 7 8];
            c = optional.just [9 10];
          };
        })
        (monoid (optional.monoid list.monoid) {
          typeName = "optional";
          leftIdentity = {
            x = optional.just [1 2 3 4 5];
          };
          rightIdentity = {
            x = optional.just ["one" "two" "three" "four" "five"];
          };
        })
      ];

      match = assertEqual "foobar"
        (optional.match (optional.just "foobar") {
          nothing = "baz";
          just = function.id;
        });
    };

    string = section "std.string" {
      laws = string.unlines [
        (semigroup string.semigroup {
          typeName = "string";
          associativity = {
            a = "foo";
            b = "bar";
            c = "baz";
          };
        })
        (monoid string.monoid {
          typeName = "string";
          leftIdentity = {
            x = "foo";
          };
          rightIdentity = {
            x = "bar";
          };
        })
      ];
      substring = string.unlines [
        (assertEqual (string.substring 2 3 "foobar") "oba")
        (assertEqual (string.substring 4 7 "foobar") "ar")
        (assertEqual (string.substring 10 5 "foobar") string.empty)
        (assertEqual (string.substring 1 (-20) "foobar") "oobar")
      ];
      index = assertEqual (string.index "foobar" 3) "b";
      length = assertEqual (string.length "foo") 3;
      empty = string.unlines [
        (assertEqual (string.isEmpty "a") false)
        (assertEqual (string.isEmpty string.empty) true)
      ];
      replace = assertEqual (string.replace ["o" "a"] ["u " "e "] "foobar") "fu u be r";
      concat = assertEqual (string.concat ["foo" "bar"]) "foobar";
      concatSep = assertEqual (string.concatSep ", " ["1" "2" "3"]) "1, 2, 3";
      concatMap = assertEqual (string.concatMap builtins.toJSON [ 1 2 3 ]) "123";
      concatMapSep = assertEqual (string.concatMapSep ", " builtins.toJSON [ 1 2 3 ]) "1, 2, 3";
      concatImap = assertEqual (string.concatImap (i: x: x + builtins.toJSON i) [ "foo" "bar" "baz" ]) "foo0bar1baz2";
      concatImapSep = assertEqual (string.concatImapSep "\n" (i: x: builtins.toJSON (i + 1) + ": " + x) [ "foo" "bar" "baz" ]) "1: foo\n2: bar\n3: baz";
      toChars = assertEqual (string.toChars "foo") ["f" "o" "o"];
      map = assertEqual (string.map (x: x + " ") "foo") "f o o ";
      imap = assertEqual (string.imap (i: x: builtins.toJSON i + x) "foo") "0f1o2o";
      filter = assertEqual (string.filter (x: x != " ") "foo bar baz") "foobarbaz";
      findIndex = assertEqual (string.findIndex (x: x == " ") "foo bar baz").value 3;
      findLastIndex = assertEqual (string.findLastIndex (x: x == " ") "foo bar baz").value 7;
      find = string.unlines [
        (assertEqual (string.find (x: x == " ") "foo bar baz").value " ")
        (assertEqual (string.find (x: x == "q") "foo bar baz").value null)
      ];
      findLast = string.unlines [
        (assertEqual (string.find (x: x == " ") "foo bar baz").value " ")
        (assertEqual (string.find (x: x == "q") "foo bar baz").value null)
      ];
      escape = assertEqual (string.escape ["$"] "foo$bar") "foo\\$bar";
      escapeShellArg = assertEqual (string.escapeShellArg "foo 'bar' baz") "'foo '\\''bar'\\'' baz'";
      escapeNixString = assertEqual (string.escapeNixString "foo$bar") ''"foo\$bar"'';
      hasPrefix = string.unlines [
        (assertEqual (string.hasPrefix "foo" "foobar") true)
        (assertEqual (string.hasPrefix "foo" "barfoo") false)
        (assertEqual (string.hasPrefix "foo" string.empty) false)
      ];
      hasSuffix = string.unlines [
        (assertEqual (string.hasSuffix "foo" "barfoo") true)
        (assertEqual (string.hasSuffix "foo" "foobar") false)
        (assertEqual (string.hasSuffix "foo" string.empty) false)
      ];
      hasInfix = string.unlines [
        (assertEqual (string.hasInfix "bar" "foobarbaz") true)
        (assertEqual (string.hasInfix "foo" "foobar") true)
        (assertEqual (string.hasInfix "bar" "foobar") true)
      ];
      removePrefix = string.unlines [
        (assertEqual (string.removePrefix "/" "/foo") "foo")
        (assertEqual (string.removePrefix "/" "foo") "foo")
      ];
      removeSuffix = string.unlines [
        (assertEqual (string.removeSuffix ".nix" "foo.nix") "foo")
        (assertEqual (string.removeSuffix ".nix" "foo") "foo")
      ];
      count = assertEqual (string.count "." ".a.b.c.d.") 5;
      optional = string.unlines [
        (assertEqual (string.optional true "foo") "foo")
        (assertEqual (string.optional false "foo") string.empty)
      ];
      head = assertEqual (string.head "bar") "b";
      tail = assertEqual (string.tail "bar") "ar";
      init = assertEqual (string.init "bar") "ba";
      last = assertEqual (string.last "bar") "r";
      take = string.unlines [
        (assertEqual (string.take 3 "foobar") "foo")
        (assertEqual (string.take 7 "foobar") "foobar")
        (assertEqual (string.take (-1) "foobar") string.empty)
      ];
      drop = string.unlines [
        (assertEqual (string.drop 3 "foobar") "bar")
        (assertEqual (string.drop 7 "foobar") string.empty)
        (assertEqual (string.drop (-1) "foobar") "foobar")
      ];
      takeEnd = string.unlines [
        (assertEqual (string.takeEnd 3 "foobar") "bar")
        (assertEqual (string.takeEnd 7 "foobar") "foobar")
        (assertEqual (string.takeEnd (-1) "foobar") string.empty)
      ];
      dropEnd = string.unlines [
        (assertEqual (string.dropEnd 3 "foobar") "foo")
        (assertEqual (string.dropEnd 7 "foobar") string.empty)
        (assertEqual (string.dropEnd (-1) "foobar") "foobar")
      ];
      takeWhile = assertEqual (string.takeWhile (x: x != " ") "foo bar baz") "foo";
      dropWhile = assertEqual (string.dropWhile (x: x != " ") "foo bar baz") " bar baz";
      takeWhileEnd = assertEqual (string.takeWhileEnd (x: x != " ") "foo bar baz") "baz";
      dropWhileEnd = assertEqual (string.dropWhileEnd (x: x != " ") "foo bar baz") "foo bar ";
      splitAt = assertEqual (string.splitAt 3 "foobar") { _0 = "foo"; _1 = "bar"; };
      span = assertEqual (string.span (x: x != " ") "foo bar baz") { _0 = "foo"; _1 = " bar baz"; };
      break = assertEqual (string.break (x: x == " ") "foo bar baz") { _0 = "foo"; _1 = " bar baz"; };
      reverse = string.unlines [
        (assertEqual (string.reverse "foobar") "raboof")
        (assertEqual (string.reverse string.empty) string.empty)
      ];
      replicate = string.unlines [
        (assertEqual (string.replicate 3 "foo") "foofoofoo")
        (assertEqual (string.replicate 0 "bar") string.empty)
      ];
      lines = string.unlines [
        (assertEqual (string.lines "foo\nbar\n") [ "foo" "bar" ])
        (assertEqual (string.lines "foo\nbar") [ "foo" "bar" ])
        (assertEqual (string.lines "\n") [ string.empty ])
        (assertEqual (string.lines string.empty) [])
      ];
      unlines = string.unlines [
        (assertEqual (string.unlines [ "foo" "bar" ]) "foo\nbar\n")
        (assertEqual (string.unlines []) string.empty)
      ];
      words = string.unlines [
        (assertEqual (string.words "foo \t bar   ") [ "foo" "bar" ])
        (assertEqual (string.words " ") [])
        (assertEqual (string.words string.empty) [])
      ];
      unwords = assertEqual (string.unwords [ "foo" "bar" ]) "foo bar";
      intercalate = assertEqual (string.intercalate ", " ["1" "2" "3"]) "1, 2, 3";
      toLower = assertEqual (string.toLower "FOO bar") "foo bar";
      toUpper = assertEqual (string.toUpper "FOO bar") "FOO BAR";
      strip = string.unlines [
        (assertEqual (string.strip "   \t\t  foo   \t") "foo")
        (assertEqual (string.strip "   \t\t   \t") string.empty)
      ];
      stripStart = assertEqual (string.stripStart "   \t\t  foo   \t") "foo   \t";
      stripEnd = assertEqual (string.stripEnd "   \t\t  foo   \t") "   \t\t  foo";
      justifyLeft = string.unlines [
        (assertEqual (string.justifyLeft 7 "x" "foo") "fooxxxx")
        (assertEqual (string.justifyLeft 2 "x" "foo") "foo")
        (assertEqual (string.justifyLeft 9 "xyz" "foo") "fooxyzxyz")
        (assertEqual (string.justifyLeft 7 "xyz" "foo") "fooxyzx")
      ];
      justifyRight = string.unlines [
        (assertEqual (string.justifyRight 7 "x" "foo") "xxxxfoo")
        (assertEqual (string.justifyRight 2 "x" "foo") "foo")
        (assertEqual (string.justifyRight 9 "xyz" "foo") "xyzxyzfoo")
        (assertEqual (string.justifyRight 7 "xyz" "foo") "xyzxfoo")
      ];
      justifyCenter = string.unlines [
        (assertEqual (string.justifyCenter 7 "x" "foo") "xxfooxx")
        (assertEqual (string.justifyCenter 2 "x" "foo") "foo")
        (assertEqual (string.justifyCenter 8 "xyz" "foo") "xyfooxyz")
      ];
    };

    regex = section "std.regex" {
      escape = assertEqual (regex.escape ''.[]{}()\*+?|^$'') ''\.\[]\{\}\(\)\\\*\+\?\|\^\$'';

      capture = assertEqual (regex.capture "foo") "(foo)";

      match = string.unlines [
        (assertEqual
          (regex.match "([[:alpha:]]+)([[:digit:]]+)" "foo123")
          ["foo" "123"])
        (assertEqual
          (regex.match "([[:alpha:]]+)([[:digit:]]+)" "foobar")
          null)
      ];

      allMatches = assertEqual (regex.allMatches "[[:digit:]]+" "foo 123 bar 456") ["123" "456"];

      firstMatch = string.unlines [
        (assertEqual (regex.firstMatch "[aeiou]" "foobar") "o")
        (assertEqual (regex.firstMatch "[aeiou]" "xyzzyx") null)
      ];

      lastMatch = string.unlines [
        (assertEqual (regex.lastMatch "[aeiou]" "foobar") "a")
        (assertEqual (regex.lastMatch "[aeiou]" "xyzzyx") null)
      ];

      split = assertEqual (regex.split "(,)" "1,2,3") ["1" [","] "2" [","] "3"];

      splitOn = assertEqual (regex.splitOn "(,)" "1,2,3") ["1" "2" "3"];

      substituteWith = assertEqual (regex.substituteWith "([[:digit:]])" (g: builtins.toJSON (builtins.fromJSON (builtins.head g) + 1)) "123") "234";

      substitute = assertEqual (regex.substitute "[aeiou]" "\\0\\0" "foobar") "foooobaar";
    };

    fixpoints = section "std.fixpoints" {
      fix = string.unlines [
        (assertEqual 0 (fixpoints.fix (const 0)))
        (assertEqual 120 (fixpoints.fix (r: n: if n == 0 then 1 else builtins.mul n (r (n - 1))) 5))
      ];
      until = assertEqual 400 (fixpoints.until (x: num.mod x 20 == 0) (compose (builtins.add 1) (builtins.mul 7)) 1);
    };
  };
in
stdenv.mkDerivation {
  pname = "nix-std-test";
  version = import ./version.nix;

  src = ./.;

  doCheck = true;
  phases = [ "unpackPhase" "checkPhase" "installPhase" ];

  checkPhase = string.unlines (builtins.attrValues sections);

  installPhase = "touch $out";
}
