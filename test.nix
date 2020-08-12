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

          x = ${types.show x}
          y = ${types.show y}

      "
      printf "$ERR"
      exit 1
    '';

  functorIdentity = functor: xs:
    assertEqual
      (functor.map function.identity xs)
      xs;

  functorComposition = functor: f: g: xs:
    assertEqual
      (functor.map (compose f g) xs)
      (functor.map f (functor.map g xs));

  applicativeIdentity = applicative: v:
    assertEqual
      (applicative.ap (applicative.pure identity) v)
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
        (assertEqual (list.range 0 4) (list.generate identity 5))
      ];

      nil = assertEqual [] list.nil;

      cons = assertEqual [1 2 3 4 5] (list.cons 1 [2 3 4 5]);

      uncons = string.unlines [
        (assertEqual null ((list.uncons [])._0))
        (assertEqual [1 2 3 4 5] (list.snoc [1 2 3 4] 5))
      ];

      foldr = assertEqual 55 (list.foldr builtins.add 0 (list.range 1 10));

      foldl' = assertEqual 3628800 (list.foldl' builtins.mul 1 (list.range 1 10));

      foldMap =
        let first = {
              append = x: _: x;
              empty = null;
            };
            endo = {
              append = compose;
              empty = identity;
            };
        in string.unlines [
             (assertEqual 1 (list.foldMap first identity (list.range 1 10)))
             (assertEqual 321 ((list.foldMap endo identity [ (x: builtins.mul x 3) (x: builtins.add x 7) (x: num.pow x 2) ]) 10))
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

      count = assertEqual 11 (list.count num.even (list.generate identity 21));

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

      zipWith = assertEqual ["foo-0" "foo-1" "foo-2"] (list.zipWith (s: i: s + "-" + builtins.toString i) (list.replicate 10 "foo") (list.range 0 2));

      zip = assertEqual [ { _0 = "foo"; _1 = 0; } { _0 = "foo"; _1 = 1; } { _0 = "foo"; _1 = 2; } ] (list.zip (list.replicate 10 "foo") (list.range 0 2));

      traverse =
        let maybe = rec {
              map = f: x:
                if x == null
                then null
                else f x;

              pure = identity;

              ap = lift2 identity;

              lift2 = f: x: y:
                if x == null
                then null
                else if y == null
                     then null
                     else f x y;
            };
        in string.unlines [
             (let ls = list.range 1 10; in assertEqual ls (list.traverse maybe (x: if (num.even x || num.odd x) then x else null) ls))
           ];
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
