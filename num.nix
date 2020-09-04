with {
  list = import ./list.nix;
  string = import ./string.nix;
};

let
  jsonIntRE = ''-?(0|[1-9][[:digit:]]*)'';
  jsonNumberRE =
    let exponent = ''[eE]-?[[:digit:]]+'';
    in ''(${jsonIntRE}(\.[[:digit:]]+)?)(${exponent})?'';
in rec {
  inherit (builtins) add mul bitAnd bitOr bitXor;

  /* bitNot :: int -> int
  */
  bitNot = bitXor (-1);

  /* negate :: Num a => a -> a
  */
  negate = x: 0 - x;

  /* abs :: Num a => a -> a
  */
  abs = x:
    if x >= 0
    then x
    else negate x;

  /* signum :: Num a => a -> a
  */
  signum = x:
    if x > 0
    then 1
    else (if x < 0 then (-1) else 0);

  /* min :: number -> number -> number
  */
  min = x: y:
    if x <= y
    then x
    else y;

  /* max :: number -> number -> number
  */
  max = x: y:
    if x <= y
    then y
    else x;

  /* compare :: number -> number -> int

     Compares two numbers and returns -1 if the first is less than the second, 0
     if they are equal, or 1 if the first is greater than the second.
  */
  compare = x: y:
    if x < y
      then -1
    else if x > y
      then 1
    else 0;

  /* quot :: integer -> integer -> integer

     Integer division, truncated towards 0. This is an alias for 'builtins.div'.
  */
  quot = builtins.div;

  /* rem :: integer -> integer -> integer

     Integer remainder. For integers m and n, this has the property that
     "n * (quot m n) + rem m n = m".
  */
  rem = base: int: base - (int * (quot base int));

  /* div :: integer -> integer -> integer

     Integer division, truncated towards negative infinity. Despite the name,
     note that this is not the same as 'builtins.div', which truncates towards 0.
  */
  div = base: int:
    let q = quot base int;
    in if (base < 0) != (int < 0)
      then q - 1
      else q;

  /* mod :: integer -> integer -> integer

     Integer modulus. For integers m and n, this has the property that
     "n * (div m n) + mod m n = m".
  */
  mod = base: int: base - (int * (div base int));

  /* quotRem :: Integral a => a -> a -> (a, a)
  */
  quotRem = n: d: { _0 = quot n d; _1 = rem n d; };

  /* divMod :: Integral a => a -> a -> (a, a)
  */
  divMod = n: d: { _0 = div n d; _1 = mod n d; };

  /* even :: integer -> bool
  */
  even = x: rem x 2 == 0;

  /* odd :: integer -> bool
  */
  odd = x: rem x 2 != 0;

  /* fac :: integer -> integer

     Integer factorial.
  */
  fac = n:
    if n < 0
    then throw "std.num.fac: argument is negative"
    else (if n == 0 then 1 else n * fac (n - 1));

  /* pow :: number -> integer -> number

     Integer exponentiation. Note that this only handles positive integer exponents.
  */
  pow = base0: exponent0:
    let pow' = base: exponent: value:
        if exponent == 0
          then 1
        else if exponent <= 1
          then value
        else pow' base (exponent - 1) (value * base);
    in if base0 == 0 || base0 == 1 then 1 else pow' base0 exponent0 base0;

  pi = 3.141592653589793238;

  /* toFloat :: int -> float

     Converts an integer to a floating-point number.
  */
  toFloat = x: x + 0.0;

  sin = t:
    let x = toFloat t;
        _3fac = 6.0;
        _5fac = 120.0;
        _7fac = 5040.0;
        _9fac = 362880.0;
        _11fac = 39916800.0;
        _13fac = 6227020800.0;
        _15fac = 1307674368000.0;
    in x
       - pow x 3 / _3fac
       + pow x 5 / _5fac
       - pow x 7 / _7fac
       + pow x 9 / _9fac
       - pow x 11 / _11fac
       + pow x 13 / _13fac
       - pow x 15 / _15fac;

  cos = t:
    let x = toFloat t;
        _2fac = 2.0;
        _4fac = 24.0;
        _6fac = 720.0;
        _8fac = 40320.0;
        _10fac = 3628800.0;
        _12fac = 479001600.0;
        _14fac = 87178291200.0;
        _16fac = 20922789888000.0;
    in 1.0
       - pow x 2 / _2fac
       + pow x 4 / _4fac
       - pow x 6 / _6fac
       + pow x 8 / _8fac
       - pow x 10 / _10fac
       + pow x 12 / _12fac
       - pow x 14 / _14fac
       + pow x 16 / _16fac;

  /*
  type Complex = { realPart :: float, imagPart :: float }
  */
  complex = {
    /* conjugate :: Complex -> Complex

       The conjugate of a complex number.
    */
    conjugate = c: { realPart = c.realPart; imagPart = negate c.imagPart; };
    /* mkPolar :: float -> float -> Complex

    Form a complex number from polar components of magnitude and phase
    */
    mkPolar = r: theta: { realPart = r * cos theta; imagPart = r * sin theta; };

    /* cis :: float -> Complex

    @cis t@ is a complex value with magnitude 1 and phase t (modulo 2pi)
    */
    cis = theta: { realPart = cos theta; imagPart = sin theta; };

    # TODO: polar, magnitude, phase
  };

  /* truncate :: float -> int

     Truncate a float to an int, rounding towards 0.
  */
  # may god have mercy on my soul.
  truncate = f:
    let chars = builtins.toJSON f;
    in builtins.fromJSON (string.takeWhile (c: c != ".") chars);

  /* floor :: float -> int

     Floor a floating point number, rounding towards negative infinity.
  */
  floor = builtins.floor or (f: truncate (if f < 0 then f - 1 else f));

  /* ceil :: float -> int

     Ceiling a floating point number, rounding towards positive infinity.
  */
  ceil = builtins.ceil or (f: truncate (if f > 0 then f + 1 else f));

  /* round :: float -> int

     Round a floating-point number to the nearest integer, biased away from 0.
  */
  round = f: signum f * floor (abs f + 0.5);

  /* tryParseInt :: string -> maybe int

     Attempt to parse a string into an int. If it fails and the string is still
     parseable a valid JSON value, return null.
  */
  tryParseInt = x:
    let
      # fromJSON aborts on invalid JSON values; check that it matches first
      matches = builtins.match jsonIntRE x != null;
      res = builtins.fromJSON x;
    in if matches && builtins.isInt res
      then res
      else null;

  /* @partial
     parseInt :: string -> int

     Attempt to parse a string into an int. If parsing fails, throw an
     exception.
  */
  parseInt = x:
    let res = tryParseInt x;
    in if res == null
      then throw "std.num.parseInt: failed to parse"
      else res;

  /* tryParseFloat :: string -> maybe float

     Attempt to parse a string into a float. If it fails and the string is still
     parseable a valid JSON value, return null.
  */
  tryParseFloat = x:
    let
      # fromJSON aborts on invalid JSON values; check that it matches first
      matches = builtins.match jsonNumberRE x != null;
      res = builtins.fromJSON x;
    in if matches && (builtins.isFloat res || builtins.isInt res)
      then res
      else null;

  /* @partial
     parseFloat :: string -> float

     Attempt to parse a string into a float. If parsing fails, throw an
     exception.
  */
  parseFloat = x:
    let res = tryParseFloat x;
    in if res == null
      then throw "std.num.parseFloat: failed to parse"
      else res;

  /* toBaseDigits :: int -> int -> [int]

     Convert an int to a list of digits in the given base. The most significant
     digit is the first element of the list.

     Note: this only works on positive numbers.
  */
  toBaseDigits = radix: x:
    if x < 0
      then throw "std.num.toBaseDigits: argument is negative"
    else if radix == 1
      then list.replicate x 1
    else
      let
        go = xs: n:
          if n < radix
          then list.cons n xs
          else
            let qr = quotRem n radix;
            in go (list.cons (qr._1) xs) qr._0;
      in go [] x;

  /* fromBaseDigits :: int -> [int] -> int

     Convert a list of digits in the given base into an int. The most
     significant digit is the first element of the list.
  */
  fromBaseDigits = radix: list.foldl' (acc: n: acc * radix + n) 0;

  /* toHexString :: int -> string
  */
  toHexString = x:
    let toHexDigit = string.index "0123456789ABCDEF";
    in string.concatMap toHexDigit (toBaseDigits 16 x);

  /* gcd :: int -> int -> int

     Computes the greatest common divisor of two integers.
  */
  gcd = x: y:
    let gcd' = a: b: if b == 0 then a else gcd' b (rem a b);
    in gcd' (abs x) (abs y);

  /* lcm :: int -> int -> int

     Computes the least common multiple of two integers.
  */
  lcm = x: y:
    if x == 0 || y == 0
    then 0
    else abs (quot x (gcd x y) * y);
}
