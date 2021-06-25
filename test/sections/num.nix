with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.num" {
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
    (assertEqual (num.truncate 20.1) 20)
    (assertEqual (num.truncate 5.0) 5)
    (assertEqual (num.truncate (-5.0)) (-5))
    (assertEqual (num.truncate (-1.5)) (-1))
    (assertEqual (num.truncate (-20.1)) (-20))
    (assertEqual (num.truncate 0) 0)
    (assertEqual (num.truncate 0.0) 0)
    (assertEqual (num.truncate 1.0e6) 1000000)
    (assertEqual (num.truncate (-1.0e6)) (-1000000))
    (assertEqual (num.truncate 1.1e6) 1100000)
    (assertEqual (num.truncate (-1.1e6)) (-1100000))
    # num.truncate (num.toFloat num.maxInt) would overflow, but it should
    # succeed on an integer regardless
    (assertEqual (num.truncate num.maxInt) num.maxInt)
    (assertEqual (num.truncate num.minInt) num.minInt)
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
}
