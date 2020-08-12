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

  min = x: y:
    if x <= y
    then x
    else y;

  max = x: y:
    if x <= y
    then y
    else x;

  mod = base: int: base - (int * (builtins.div base int));

  even = x: mod x 2 == 0;

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
}
