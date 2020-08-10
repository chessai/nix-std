with (import ./default.nix);

with {
  inherit (import <nixpkgs> {}) stdenv;
};

let
  section = module: tests: ''
    echo "testing ${module}"
    ${string.concatSep "\n"
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
      not = string.concatSep "\n" [
        (assertEqual (bool.not false) true)
        (assertEqual (bool.not true) false)
      ];
      ifThenElse = string.concatSep "\n" [
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

    };
  };
in
stdenv.mkDerivation {
  pname = "nix-std-test";
  version = import ./version.nix;

  src = ./.;

  doCheck = true;
  phases = [ "unpackPhase" "checkPhase" "installPhase" ];

  checkPhase = string.concatSep "\n" (builtins.attrValues sections);

  installPhase = "touch $out";
}
