with (import ./default.nix);

with {
  inherit (import <nixpkgs> {}) stdenv;
};

let
  section = module: tests: ''
    echo "testing ${module}"
    ${string.unlines
        (list.map
          (test: ''echo "...${test._0}"...; ${test._1}'')
            (set.toList tests))
     }
  '';

  assertEqual = x: y:
    if x == y
    then ""
    else ''
      ERR="
        assertEqual failed: x != y, where

          x = ${string.escape [''"''] (types.show x)}
          y = ${string.escape [''"''] (types.show y)}

      "
      printf "$ERR"
      exit 1
    '';

  functorIdentity = functor: xs:
    assertEqual
      (functor.map id xs)
      xs;

  functorComposition = functor: f: g: xs:
    assertEqual
      (functor.map (compose f g) xs)
      (functor.map f (functor.map g xs));

  applicativeIdentity = applicative: v:
    assertEqual
      (applicative.ap (applicative.pure id) v)
      v;

  /* applicativeComposition :: (Applicative f)
       => f (b -> c)
       -> f (a -> b)
       -> f a
       -> Test
  */
  applicativeComposition = applicative: u: v: w:
    assertEqual
      (applicative.ap (applicative.ap ((applicative.ap (applicative.pure compose) u)) v) w)
      (applicative.ap u (applicative.ap v w));

  applicativeHomomorphism = applicative: f: x:
    assertEqual
      (applicative.ap (applicative.pure f) (applicative.pure x))
      (applicative.pure (f x));

  applicativeInterchange = applicative: u: y:
    assertEqual
      (applicative.ap u (applicative.pure y))
      (applicative.ap (applicative.pure (f: f y)) u);

  monadLeftIdentity = monad: f: x:
    assertEqual
      (monad.bind (monad.pure x) f)
      (f x);

  monadRightIdentity = monad: x:
    assertEqual
      (monad.bind x monad.pure)
      x;

  monadAssociativity = monad: m: f: g:
    assertEqual
      (monad.bind (monad.bind m f) g)
      (monad.bind m (x: monad.bind (f x) g));

  semigroupAssociativity = semigroup: a: b: c:
    assertEqual
      (semigroup.append a (semigroup.append b c))
      (semigroup.append (semigroup.append a b) c);

  monoidLeftIdentity = monoid: x:
    assertEqual
      (monoid.append monoid.empty x)
      x;

  monoidRightIdentity = monoid: x:
    assertEqual
      (monoid.append x monoid.empty)
      x;

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
      functor-identity = functorIdentity list.functor [1 2 3 4 5];
      functor-composition = functorComposition list.functor (x: x ++ x) list.singleton [1 2 3 4 5];
      applicative-identity = applicativeIdentity list.applicative [1 2 3 4];
      applicative-composition = applicativeComposition
        list.applicative
        [ (b: builtins.toString (b + 1)) (b: builtins.toString (b * 2)) (b: builtins.toString (5 * (b + 1))) ]
        [ (a: a + 1) (a: a * 2) (b: 5 * (b + 1)) ]
        [ 1 2 3 4 5 ];
      applicative-homomorphism = applicativeHomomorphism list.applicative builtins.toString 5;
      applicative-interchange = applicativeInterchange list.applicative
        (list.ifor ["foo" "bar" "baz"] (i: s: (u: builtins.toString u + "-" + s + "-" + builtins.toString i)))
        20.0;
      monad-left-identity = monadLeftIdentity list.monad (x: [x x x]) 10;
      monad-right-identity = monadRightIdentity list.monad (list.range 1 10);
      monad-associativity = monadAssociativity list.monad [1 2 3 4 5] (x: list.singleton (x + 1)) (x: list.range x (x + 1));
      semigroup-associativity = semigroupAssociativity list.semigroup [1 2] ["foo" "bar"] [true false];
      monoid-left-identity = monoidLeftIdentity list.monoid [1 2];
      monoid-right-identity = monoidRightIdentity list.monoid [1 2];
      match =
        let ls = ["foo" "baz" "bow" "bar" "bed"];
            go = xs0: list.match xs0 {
              nil = "failure";
              cons = x: xs:
                if x == "bar"
                then x
                else go xs;
            };
        in assertEqual "bar" (go ls);

      head = assertEqual 10 (list.head [10 20 30]);

      tail = assertEqual [20 30] (list.tail [10 20 30]);

      take = assertEqual [1 2 3 4] (list.take 4 (list.range 1 20));

      length = assertEqual 20 (list.length (list.range 1 20));

      singleton = assertEqual [10] (list.singleton 10);

      map = assertEqual ["foo-0" "foo-1"] (list.map (i: "foo-" + builtins.toString i) [0 1]);

      for = assertEqual ["foo-0" "foo-1"] (list.for [0 1] (i: "foo-" + builtins.toString i));

      imap = assertEqual ["foo-0" "bar-1"] (list.imap (i: s: s + "-" + builtins.toString i) ["foo" "bar"]);

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
        (assertEqual null ((list.uncons [])._0))
        (assertEqual [1 2 3 4 5] (list.snoc [1 2 3 4] 5))
      ];

      foldr = assertEqual 55 (list.foldr builtins.add 0 (list.range 1 10));

      foldl' = assertEqual 3628800 (list.foldl' builtins.mul 1 (list.range 1 10));

      foldMap = string.unlines [
        (assertEqual 1 (list.foldMap monoid.first id (list.range 1 10)))
        (assertEqual 321 ((list.foldMap monoid.endo id [ (x: builtins.mul x 3) (x: builtins.add x 7) (x: num.pow x 2) ]) 10))
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
        (let ls = list.range 1 10; in assertEqual ls (list.traverse maybe.applicative (x: if (num.even x || num.odd x) then x else null) ls))
      ];

      reverse = string.unlines [
        (assertEqual (list.reverse [1 2 3]) [3 2 1])
        (assertEqual (list.reverse []) [])
      ];
    };

    string = section "std.string" {
      semigroup-associativity = semigroupAssociativity string.semigroup "foo" "bar" "baz";
      monoid-left-identity = monoidLeftIdentity string.monoid "foo";
      monoid-right-identity = monoidRightIdentity string.monoid "foo";
      substring = string.unlines [
        (assertEqual (string.substring 2 3 "foobar") "oba")
        (assertEqual (string.substring 4 7 "foobar") "ar")
        (assertEqual (string.substring 10 5 "foobar") "")
        (assertEqual (string.substring 1 (-20) "foobar") "oobar")
      ];
      index = assertEqual (string.index 3 "foobar") "b";
      length = assertEqual (string.length "foo") 3;
      empty = string.unlines [
        (assertEqual (string.empty "a") false)
        (assertEqual (string.empty "") true)
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
      findIndex = assertEqual (string.findIndex (x: x == " ") "foo bar baz") 3;
      findLastIndex = assertEqual (string.findLastIndex (x: x == " ") "foo bar baz") 7;
      find = assertEqual (string.find (x: x == " ") "foo bar baz") " ";
      findLast = assertEqual (string.find (x: x == " ") "foo bar baz") " ";
      escape = assertEqual (string.escape ["$"] "foo$bar") "foo\\$bar";
      escapeShellArg = assertEqual (string.escapeShellArg "foo 'bar' baz") "'foo '\\''bar'\\'' baz'";
      escapeNixString = assertEqual (string.escapeNixString "foo$bar") ''"foo\$bar"'';
      hasPrefix = string.unlines [
        (assertEqual (string.hasPrefix "foo" "foobar") true)
        (assertEqual (string.hasPrefix "foo" "barfoo") false)
        (assertEqual (string.hasPrefix "foo" "") false)
      ];
      hasSuffix = string.unlines [
        (assertEqual (string.hasSuffix "foo" "barfoo") true)
        (assertEqual (string.hasSuffix "foo" "foobar") false)
        (assertEqual (string.hasSuffix "foo" "") false)
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
        (assertEqual (string.optional false "foo") "")
      ];
      head = assertEqual (string.head "bar") "b";
      tail = assertEqual (string.tail "bar") "ar";
      init = assertEqual (string.init "bar") "ba";
      last = assertEqual (string.last "bar") "r";
      take = string.unlines [
        (assertEqual (string.take 3 "foobar") "foo")
        (assertEqual (string.take 7 "foobar") "foobar")
        (assertEqual (string.take (-1) "foobar") "")
      ];
      drop = string.unlines [
        (assertEqual (string.drop 3 "foobar") "bar")
        (assertEqual (string.drop 7 "foobar") "")
        (assertEqual (string.drop (-1) "foobar") "foobar")
      ];
      takeEnd = string.unlines [
        (assertEqual (string.takeEnd 3 "foobar") "bar")
        (assertEqual (string.takeEnd 7 "foobar") "foobar")
        (assertEqual (string.takeEnd (-1) "foobar") "")
      ];
      dropEnd = string.unlines [
        (assertEqual (string.dropEnd 3 "foobar") "foo")
        (assertEqual (string.dropEnd 7 "foobar") "")
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
        (assertEqual (string.reverse "") "")
      ];
      replicate = string.unlines [
        (assertEqual (string.replicate 3 "foo") "foofoofoo")
        (assertEqual (string.replicate 0 "bar") "")
      ];
      lines = string.unlines [
        (assertEqual (string.lines "foo\nbar\n") [ "foo" "bar" ])
        (assertEqual (string.lines "foo\nbar") [ "foo" "bar" ])
        (assertEqual (string.lines "\n") [ "" ])
        (assertEqual (string.lines "") [])
      ];
      unlines = string.unlines [
        (assertEqual (string.unlines [ "foo" "bar" ]) "foo\nbar\n")
        (assertEqual (string.unlines []) "")
      ];
      words = string.unlines [
        (assertEqual (string.words "foo \t bar   ") [ "foo" "bar" ])
        (assertEqual (string.words " ") [])
        (assertEqual (string.words "") [])
      ];
      unwords = assertEqual (string.unwords [ "foo" "bar" ]) "foo bar";
      intercalate = assertEqual (string.intercalate ", " ["1" "2" "3"]) "1, 2, 3";
      toLower = assertEqual (string.toLower "FOO bar") "foo bar";
      toUpper = assertEqual (string.toUpper "FOO bar") "FOO BAR";
      strip = string.unlines [
        (assertEqual (string.strip "   \t\t  foo   \t") "foo")
        (assertEqual (string.strip "   \t\t   \t") "")
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

      splitOn = assertEqual (regex.splitOn "(,)" "1,2,3") ["1" "2""3"];

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
