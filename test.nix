{ system ? builtins.currentSystem
}:

with { std = import ./default.nix; };
with std;

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
    num = section "std.num" {
      negate = assertEqual (num.negate 5) (-5);
      abs = string.unlines [
        (assertEqual (num.abs (-5)) 5)
        (assertEqual (num.abs 5) 5)
      ];
      signum = string.unlines [
        (assertEqual (num.signum 5) 1)
        (assertEqual (num.signum 0) 0)
        (assertEqual (num.signum (-5)) (-1))
      ];
      min = string.unlines [
        (assertEqual (num.min (-3) 5) (-3))
        (assertEqual (num.min 5 (-3)) (-3))
      ];
      max = string.unlines [
        (assertEqual (num.max (-3) 5) 5)
        (assertEqual (num.max 5 (-3)) 5)
      ];
      compare = string.unlines [
        (assertEqual (num.compare (-3) 5) "LT")
        (assertEqual (num.compare 5 5) "EQ")
        (assertEqual (num.compare 5 (-3)) "GT")
        (assertEqual (num.compare num.minInt num.maxInt) "LT")
        (assertEqual (num.compare num.minInt num.minInt) "EQ")
        (assertEqual (num.compare num.maxInt num.minInt) "GT")
      ];
      quot = string.unlines [
        (assertEqual (num.quot 18 7) 2)
        (assertEqual (num.quot 18 (-7)) (-2))
        (assertEqual (num.quot (-18) 7) (-2))
        (assertEqual (num.quot (-18) (-7)) 2)
      ];
      rem = string.unlines [
        (assertEqual (num.rem 18 7) 4)
        (assertEqual (num.rem 18 (-7)) 4)
        (assertEqual (num.rem (-18) 7) (-4))
        (assertEqual (num.rem (-18) (-7)) (-4))
      ];
      div = string.unlines [
        (assertEqual (num.div 18 7) 2)
        (assertEqual (num.div 18 (-7)) (-3))
        (assertEqual (num.div (-18) 7) (-3))
        (assertEqual (num.div (-18) (-7)) 2)
      ];
      mod = string.unlines [
        (assertEqual (num.mod 18 7) 4)
        (assertEqual (num.mod 18 (-7)) (-3))
        (assertEqual (num.mod (-18) 7) 3)
        (assertEqual (num.mod (-18) (-7)) (-4))
      ];
      quotRem = assertEqual (num.quotRem (-18) 7) { _0 = (-2); _1 = (-4); };
      divMod = assertEqual (num.divMod (-18) 7) { _0 = (-3); _1 = 3; };
      even = string.unlines [
        (assertEqual (num.even (-1)) false)
        (assertEqual (num.even 0) true)
        (assertEqual (num.even 1) false)
      ];
      odd = string.unlines [
        (assertEqual (num.odd (-1)) true)
        (assertEqual (num.odd 0) false)
        (assertEqual (num.odd 1) true)
      ];
      fac = string.unlines [
        (assertEqual (num.fac 0) 1)
        (assertEqual (num.fac 5) 120)
      ];
      pow = string.unlines [
        (assertEqual (num.pow 0 10) 1)
        (assertEqual (num.pow 1 10) 1)
        (assertEqual (num.pow 10 0) 1)
        (assertEqual (num.pow 10 1) 10)
        (assertEqual (num.pow 10 3) 1000)
      ];
      toFloat = assertEqual (num.toFloat 5) 5.0;
      truncate = string.unlines [
        (assertEqual (num.truncate 1.5) 1)
        (assertEqual (num.truncate (-1.5)) (-1))
      ];
      floor = string.unlines [
        (assertEqual (num.floor 1.5) 1)
        (assertEqual (num.floor (-1.5)) (-2))
      ];
      ceil = string.unlines [
        (assertEqual (num.ceil 1.5) 2)
        (assertEqual (num.ceil (-1.5)) (-1))
      ];
      round = string.unlines [
        (assertEqual (num.round 1.5) 2)
        (assertEqual (num.round 1.3) 1)
        (assertEqual (num.round 1.0) 1)
        (assertEqual (num.round (-1.5)) (-2))
        (assertEqual (num.round (-1.3)) (-1))
        (assertEqual (num.round (-1.0)) (-1))
      ];
      tryParseInt = string.unlines [
        (assertEqual (num.tryParseInt "foo") optional.nothing)
        (assertEqual (num.tryParseInt "1.0") optional.nothing)
        (assertEqual (num.tryParseInt "0") (optional.just 0))
        (assertEqual (num.tryParseInt "05") optional.nothing)
        (assertEqual (num.tryParseInt "-5") (optional.just (-5)))
        (assertEqual (num.tryParseInt "") optional.nothing)
        (assertEqual (num.tryParseInt "-") optional.nothing)
      ];
      parseInt = assertEqual (num.parseInt "-5") (-5);
      tryParseFloat = string.unlines [
        (assertEqual (num.tryParseFloat "foo") optional.nothing)
        (assertEqual (num.tryParseFloat "-1.80") (optional.just (-1.8)))
        (assertEqual (num.tryParseFloat "0.0") (optional.just 0.0))
        (assertEqual (num.tryParseFloat "0") (optional.just 0.0))
        (assertEqual (num.tryParseFloat "0.") optional.nothing)
        (assertEqual (num.tryParseFloat ".0") optional.nothing)
        (assertEqual (num.tryParseFloat ".") optional.nothing)
        (assertEqual (num.tryParseFloat "-01.05e-2") optional.nothing)
        (assertEqual (num.tryParseFloat "-1.05e-2") (optional.just ((-1.05) / 100)))
      ];
      parseFloat = assertEqual (num.parseFloat "-1.80") (-1.8);
      toBaseDigits = string.unlines [
        (assertEqual (num.toBaseDigits 16 4660) [ 1 2 3 4 ])
        (assertEqual (num.toBaseDigits 2 85) [ 1 0 1 0 1 0 1 ])
        (assertEqual (num.toBaseDigits 20 0) [ 0 ])
      ];
      fromBaseDigits = string.unlines [
        (assertEqual (num.fromBaseDigits 2 [ 1 0 1 0 1 0 1 ]) 85)
        (assertEqual (num.fromBaseDigits 16 [ 1 2 3 4 ]) 4660)
      ];
      toHexString = string.unlines [
        (assertEqual (num.toHexString 0) "0")
        (assertEqual (num.toHexString 4660) "1234")
        (assertEqual (num.toHexString 11259375) "abcdef")
      ];
      gcd = string.unlines [
        (assertEqual (num.gcd 0 0) 0)
        (assertEqual (num.gcd 1 1) 1)
        (assertEqual (num.gcd (-17289472) 198264) 8)
      ];
      lcm = string.unlines [
        (assertEqual (num.lcm 0 0) 0)
        (assertEqual (num.lcm 1 0) 0)
        (assertEqual (num.lcm 1 1) 1)
        (assertEqual (num.lcm 127 (-928)) 117856)
      ];
    };
    bits = section "std.num.bits" {
      bitSize = string.unlines [
        (assertEqual num.maxInt (num.pow 2 (num.bits.bitSize - 1) - 1))
        (assertEqual num.minInt (- num.pow 2 (num.bits.bitSize - 1)))
      ];
      bitAnd = string.unlines [
        (assertEqual (num.bits.bitAnd 5 3) 1)
        (assertEqual (num.bits.bitAnd (-1) 6148914691236517205) 6148914691236517205)
        (assertEqual (num.bits.bitAnd (-6148914691236517206) 6148914691236517205) 0)
      ];
      bitOr = string.unlines [
        (assertEqual (num.bits.bitOr 5 3) 7)
        (assertEqual (num.bits.bitOr (-1) 6148914691236517205) (-1))
        (assertEqual (num.bits.bitOr (-6148914691236517206) 6148914691236517205) (-1))
      ];
      bitXor = string.unlines [
        (assertEqual (num.bits.bitXor 5 3) 6)
        (assertEqual (num.bits.bitXor (-1) 6148914691236517205) (-6148914691236517206))
        (assertEqual (num.bits.bitXor (-6148914691236517206) 6148914691236517205) (-1))
      ];
      bitNot = string.unlines [
        (assertEqual (num.bits.bitNot 0) (-1))
        (assertEqual (num.bits.bitNot (-1)) 0)
        (assertEqual (num.bits.bitNot (-6148914691236517206)) 6148914691236517205)
      ];
      bit =
        let
          case = n:
            let
              # Manually compute 2^n
              go = acc: m:
                if m == 0
                then acc
                else let r = 2 * acc; in builtins.seq r (go r (m - 1));
            in assertEqual (num.bits.bit n) (go 1 n);
        in string.unlines (list.map case (list.range 0 (num.bits.bitSize - 1)));
      set =
        let
          case = n: string.unlines [
            # Sets cleared bit
            (assertEqual (num.bits.set 0 n) (num.bits.bit n))
            # Idempotence on set bit
            (assertEqual (num.bits.set (num.bits.set 0 n) n) (num.bits.set 0 n))
          ];
        in string.unlines (list.map case (list.range 0 (num.bits.bitSize - 1)));
      clear =
        let
          case = n: string.unlines [
            # Clears set bit
            (assertEqual (num.bits.clear (-1) n) (num.bits.bitNot (num.bits.bit n)))
            # Idempotence on cleared bit
            (assertEqual (num.bits.clear (-1) n) (num.bits.clear (num.bits.clear (-1) n) n))
          ];
        in string.unlines (list.map case (list.range 0 (num.bits.bitSize - 1)));
      toggle =
        let
          case = n: string.unlines [
            # Clears set bit
            (assertEqual (num.bits.toggle (-1) n) (num.bits.bitNot (num.bits.bit n)))
            # Sets cleared bit
            (assertEqual (num.bits.toggle 0 n) (num.bits.bit n))
          ];
        in string.unlines (list.map case (list.range 0 (num.bits.bitSize - 1)));
      test =
        let
          case = n: string.unlines [
            # Set bit
            (assertEqual (num.bits.test (num.bits.bit n) n) true)
            # Cleared bit
            (assertEqual (num.bits.test 0 n) false)
          ];
        in string.unlines (list.map case (list.range 0 (num.bits.bitSize - 1)));
      shiftL = string.unlines [
        (assertEqual (num.bits.shiftL 5 3) 40)
        (assertEqual (num.bits.shiftL 0 5) 0)
        (assertEqual (num.bits.shiftL (-1) 3) (-8))
        (assertEqual (num.bits.shiftL (-1) 0) (-1))
        (assertEqual (num.bits.shiftL (-1) num.bits.bitSize) (0))
        (assertEqual (num.bits.shiftL (num.bits.bit (num.bits.bitSize - 1)) 1) 0)
        (assertEqual (num.bits.shiftL (-1) (-1)) (-1))
        (assertEqual (num.bits.shiftL (-1) (-num.bits.bitSize)) (-1))
      ];
      shiftLU = string.unlines [
        (assertEqual (num.bits.shiftLU 5 3) 40)
        (assertEqual (num.bits.shiftLU 0 5) 0)
        (assertEqual (num.bits.shiftLU (-1) 3) (-8))
        (assertEqual (num.bits.shiftLU (-1) 0) (-1))
        (assertEqual (num.bits.shiftLU (-1) num.bits.bitSize) (0))
        (assertEqual (num.bits.shiftLU (num.bits.bit (num.bits.bitSize - 1)) 1) 0)
        (assertEqual (num.bits.shiftLU (-1) (-1)) num.maxInt)
        (assertEqual (num.bits.shiftLU (-1) (-num.bits.bitSize)) 0)
      ];
      shiftR = string.unlines [
        (assertEqual (num.bits.shiftR 5 3) 0)
        (assertEqual (num.bits.shiftR 0 5) 0)
        (assertEqual (num.bits.shiftR (-30) 2) (-8))
        (assertEqual (num.bits.shiftR (-1) 3) (-1))
        (assertEqual (num.bits.shiftR (-1) 0) (-1))
        (assertEqual (num.bits.shiftR (-1) num.bits.bitSize) (-1))
        (assertEqual (num.bits.shiftR (-1) (-1)) (-2))
        (assertEqual (num.bits.shiftR (-1) (-num.bits.bitSize)) 0)
      ];
      shiftRU = string.unlines [
        (assertEqual (num.bits.shiftRU 5 3) 0)
        (assertEqual (num.bits.shiftRU 0 5) 0)
        (assertEqual (num.bits.shiftRU (-30) 2) 4611686018427387896)
        (assertEqual (num.bits.shiftRU (-1) 3) 2305843009213693951)
        (assertEqual (num.bits.shiftRU (-1) 0) (-1))
        (assertEqual (num.bits.shiftRU (-1) num.bits.bitSize) 0)
        (assertEqual (num.bits.shiftRU (-1) (-1)) (-2))
        (assertEqual (num.bits.shiftRU (-1) (-num.bits.bitSize)) 0)
      ];
      rotateL = string.unlines [
        (assertEqual (num.bits.rotateL 5 3) 40)
        (assertEqual (num.bits.rotateL 0 5) 0)
        (assertEqual (num.bits.rotateL (-1) 3) (-1))
        (assertEqual (num.bits.rotateL (-1) 0) (-1))
        (assertEqual (num.bits.rotateL (-1) (num.bits.bitSize + 5)) (-1))
        (assertEqual (num.bits.rotateL 15 num.bits.bitSize) 15)
        (assertEqual (num.bits.rotateL (num.bits.bit (num.bits.bitSize - 1)) 1) 1)
        (assertEqual (num.bits.rotateL (-1) (-1)) (-1))
        (assertEqual (num.bits.rotateL 15 (-2)) (-4611686018427387901))
        (assertEqual (num.bits.rotateL 15 (-num.bits.bitSize)) 15)
      ];
      rotateR = string.unlines [
        (assertEqual (num.bits.rotateR 25 3) 2305843009213693955)
        (assertEqual (num.bits.rotateR 0 5) 0)
        (assertEqual (num.bits.rotateR (-1) 3) (-1))
        (assertEqual (num.bits.rotateR (-1) 0) (-1))
        (assertEqual (num.bits.rotateR (-1) (num.bits.bitSize + 5)) (-1))
        (assertEqual (num.bits.rotateR 15 num.bits.bitSize) 15)
        (assertEqual (num.bits.rotateR 1 1) (num.bits.bit (num.bits.bitSize - 1)))
        (assertEqual (num.bits.rotateR (-1) (-1)) (-1))
        (assertEqual (num.bits.rotateR 15 (-2)) 60)
        (assertEqual (num.bits.rotateR 15 (-num.bits.bitSize)) 15)
      ];
      popCount = string.unlines [
        (assertEqual (num.bits.popCount 0) 0)
        (assertEqual (num.bits.popCount (-1)) num.bits.bitSize)
        (assertEqual (num.bits.popCount 6148914691236517205) (num.bits.bitSize / 2))
        (assertEqual (num.bits.popCount (-6148914691236517206)) (num.bits.bitSize / 2))
        (assertEqual (num.bits.popCount 3689348814741910323) (num.bits.bitSize / 2))
      ];
      bitScanForward =
        let
          case = n: assertEqual (num.bits.bitScanForward (num.bits.bit n)) n;
          singleBitTests = string.unlines (list.map case (list.range 0 num.bits.bitSize));
        in string.unlines [
          singleBitTests
          (assertEqual (num.bits.bitScanForward 5) 0)
          (assertEqual (num.bits.bitScanForward (num.bits.bitOr (num.bits.bit (num.bits.bitSize - 1)) 1)) 0)
          (assertEqual (num.bits.bitScanForward (-1)) 0)
        ];
      countTrailingZeros =
        let
          case = n: assertEqual (num.bits.countTrailingZeros (num.bits.bit n)) n;
        in string.unlines (list.map case (list.range 0 num.bits.bitSize));
      bitScanReverse =
        let
          case = n: assertEqual (num.bits.bitScanReverse (num.bits.bit n)) n;
          singleBitTests = string.unlines (list.map case (list.range 0 num.bits.bitSize));
        in string.unlines [
          singleBitTests
          (assertEqual (num.bits.bitScanReverse 5) 2)
          (assertEqual (num.bits.bitScanReverse (num.bits.bitOr (num.bits.bit (num.bits.bitSize - 1)) 1)) (num.bits.bitSize - 1))
          (assertEqual (num.bits.bitScanReverse (-1)) (num.bits.bitSize - 1))
        ];
      countLeadingZeros =
        let
          case = n:
            assertEqual
              (num.bits.countLeadingZeros (num.bits.bit n))
              (if n == 64 then 64 else num.bits.bitSize - n - 1);
        in string.unlines (list.map case (list.range 0 num.bits.bitSize));
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
    };

    nonempty = section "std.nonempty" {
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
      elemAt = assertEqual "barry" (nonempty.elemAt (nonempty.make "bar" ["ry" "barry"]) 2);
      index = assertEqual "barry" (nonempty.index (nonempty.make "bar" ["ry" "barry"]) 2);
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

      isJust = string.unlines [
        (assertEqual true (optional.isJust (optional.just 5)))
        (assertEqual true (optional.isJust (optional.just null)))
        (assertEqual false (optional.isJust optional.nothing))
      ];

      isNothing = string.unlines [
        (assertEqual false (optional.isNothing (optional.just 5)))
        (assertEqual false (optional.isNothing (optional.just null)))
        (assertEqual true (optional.isNothing optional.nothing))
      ];
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
      findIndex = assertEqual (string.findIndex (x: x == " ") "foo bar baz") (optional.just 3);
      findLastIndex = assertEqual (string.findLastIndex (x: x == " ") "foo bar baz") (optional.just 7);
      find = string.unlines [
        (assertEqual (string.find (x: x == " ") "foo bar baz") (optional.just " "))
        (assertEqual (string.find (x: x == "q") "foo bar baz") optional.nothing)
      ];
      findLast = string.unlines [
        (assertEqual (string.find (x: x == " ") "foo bar baz") (optional.just " "))
        (assertEqual (string.find (x: x == "q") "foo bar baz") optional.nothing)
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
          (optional.just ["foo" "123"]))
        (assertEqual
          (regex.match "([[:alpha:]]+)([[:digit:]]+)" "foobar")
          optional.nothing)
      ];

      allMatches = assertEqual (regex.allMatches "[[:digit:]]+" "foo 123 bar 456") ["123" "456"];

      firstMatch = string.unlines [
        (assertEqual (regex.firstMatch "[aeiou]" "foobar") (optional.just "o"))
        (assertEqual (regex.firstMatch "[aeiou]" "xyzzyx") optional.nothing)
      ];

      lastMatch = string.unlines [
        (assertEqual (regex.lastMatch "[aeiou]" "foobar") (optional.just "a"))
        (assertEqual (regex.lastMatch "[aeiou]" "xyzzyx") optional.nothing)
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

    serde = section "std.serde" {
      toTOML =
        let
          checkRoundtrip = data:
            assertEqual true (builtins.fromTOML (serde.toTOML data) == data);
        in
        string.unlines [
          # basic k = v notation
          (checkRoundtrip { foo = 1; })
          # inline JSON-like literals
          (checkRoundtrip { foo = [1 2 3]; })
          # basic table
          (checkRoundtrip { foo.bar = 1; })
          # nested tables with dots
          (checkRoundtrip { foo.bar.baz = 1; })
          # properly escapes invalid identifiers
          (checkRoundtrip { foo."bar.baz-quux".xyzzy = 1; })
          # double-bracket list notation for lists of dictionaries
          (checkRoundtrip { foo = [{ bar = 1; } { bar = [{ quux = 2; }]; }]; })
          # mixing dot notation and list notation
          (checkRoundtrip { foo.bar.baz = [{ bar = 1; } { bar = [{ quux = 2; }]; }]; })
        ];
    };
  };
in
builtins.derivation {
  name = "nix-std-test-${import ./version.nix}";
  inherit system;
  builder = "/bin/sh";
  args = [
    "-c"
    (string.unlines (builtins.attrValues sections) + ''
      echo > "$out"
    '')
  ];
}
