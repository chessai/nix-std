with {
  list = import ./list.nix;
};

rec {
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

  toFloat = x:
    if builtins.isFloat x
    then x
    else builtins.fromJSON "${builtins.toString x}.0";
}
