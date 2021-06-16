with {
  list = import ./list.nix;
  string = import ./string.nix;
};

rec {
  inherit (builtins) add mul;

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

  mod = base: int: base - (int * (builtins.div base int));

  /* even :: integer -> bool
  */
  even = x: mod x 2 == 0;

  /* odd :: integer -> bool
  */
  odd = x: mod x 2 == 1;

  /* divMod :: Integral a => a -> a -> (a, a)
  */
  divMod = n: d:
    let qr = quotRem n d;
        q = qr._0;
        r = qr._1;
    in if signum r == negate (signum d)
       then { _0 = q - 1; _1 = r + d; }
       else qr;

  /* quotRem :: Integral a => a -> a -> (a, a)
  */
  quotRem = n: d: throw "implement quotRem";

  fac = n:
    if n < 0
    then throw "std.num.fac: argument is negative"
    else (if n == 0 then 1 else n * fac (n - 1));

  pow = base0: exponent0:
    let pow' = base: exponent: value:
        if exponent == 0
        then 1
        else if exponent <= 1
             then value
             else (pow' base (exponent - 1) (value * base));
    in pow' base0 exponent0 base0;

  pi = 3.141592653589793238;

  toFloat = x: x + 0.0;

  /* may god have mercy on my soul. */
  floor = f:
    let chars = string.toChars (builtins.toJSON f);
        searcher = n: c:
          if n.found
          then n
          else if c == "."
               then { index = n.index; found = true; }
               else { index = n.index + 1; found = false; };
        radix = (list.foldl' searcher { index = 0; found = false; } chars).index;
    in builtins.fromJSON (string.concat (list.take radix chars));

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
}
