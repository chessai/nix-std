with rec {
  list = import ./list.nix;
  string = import ./string.nix;
  optional = import ./optional.nix;

  tuple = import ./tuple.nix;
  inherit (tuple) tuple2;
};

let
  jsonIntRE = ''-?(0|[1-9][[:digit:]]*)'';
  jsonNumberRE =
    let exponent = ''[eE]-?[[:digit:]]+'';
    in ''(${jsonIntRE}(\.[[:digit:]]+)?)(${exponent})?'';
in rec {
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

  /* compare :: number -> number -> "LT" | "EQ" | "GT"

     Compares two numbers and returns `"LT"` if the first is less than the
     second, `"EQ"` if they are equal, or `"GT"` if the first is greater than
     the second.
  */
  compare = x: y:
    if x < y
      then "LT"
    else if x > y
      then "GT"
    else "EQ";

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
  quotRem = n: d: tuple2 (quot n d) (rem n d);

  /* divMod :: Integral a => a -> a -> (a, a)
  */
  divMod = n: d: tuple2 (div n d) (mod n d);

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
    let pow' = x: exponent: res:
        if exponent == 0
          then res
        else if bits.test exponent 0
          then pow' x (bits.clear exponent 0) (res * x)
        else pow' (x * x) (bits.shiftRU exponent 1) res;
    in if base0 == 0 || base0 == 1 then 1 else pow' base0 exponent0 1;

  pi = 3.141592653589793238;

  /* toFloat :: number -> float

     Converts an integer to a floating-point number.
  */
  toFloat = x: x + 0.0;

  sin = t:
    let
      # divide the domain into slices of size pi/2; t \in s * [0, pi/2)
      s = floor (t * 2.0 / pi);

      # t, wrapped to the range [0, pi/2)
      t' = t - s * 0.5 * pi;

      # reconstruction of sin(t) from sin(t') depends on the range of t:
      # - k * [ 0,     pi/2  ) -> sin(t) = sin(t')
      # - k * [ pi/2,  pi    ) -> sin(t) = sin(pi/2 - t')
      # - k * [ pi,    3pi/2 ) -> sin(t) = -sin(t')
      # - k * [ 3pi/2, 2pi   ) -> sin(t) = -sin(pi/2 - t')
      quadrant = mod s 4;
      multiplier = if quadrant == 0 || quadrant == 1 then 1 else -1;
      x = if quadrant == 1 || quadrant == 3 then (pi * 0.5 - t') else t';

      # taylor series approximation
      x2 = x * x;
      x3 = x2 * x;
      x5 = x2 * x3;
      x7 = x2 * x5;
      x9 = x2 * x7;
      x11 = x2 * x9;
      x13 = x2 * x11;
      x15 = x2 * x13;
    in
      multiplier *
        (x
         - x3 / 6.0
         + x5 / 120.0
         - x7 / 5040.0
         + x9 / 362880.0
         - x11 / 39916800.0
         + x13 / 6227020800.0
         - x15 / 1307674368000.0);

  cos = t:
    let
      # divide the domain into slices of size pi/2; t \in s * [0, pi/2)
      s = floor (t * 2.0 / pi);

      # t, wrapped to the range [0, pi/2)
      t' = t - s * 0.5 * pi;

      # reconstruction of cos(t) from cos(t') depends on the range of t:
      # - k * [ 0,     pi/2  ) -> cos(t) = cos(t')
      # - k * [ pi/2,  pi    ) -> cos(t) = -cos(pi/2 - t')
      # - k * [ pi,    3pi/2 ) -> cos(t) = -cos(t')
      # - k * [ 3pi/2, 2pi   ) -> cos(t) = cos(pi/2 - t')
      quadrant = mod s 4;
      multiplier = if quadrant == 0 || quadrant == 3 then 1 else -1;
      x = if quadrant == 1 || quadrant == 3 then (pi * 0.5 - t') else t';

      # taylor series approximation
      x2 = x * x;
      x4 = x2 * x2;
      x6 = x2 * x4;
      x8 = x2 * x6;
      x10 = x2 * x8;
      x12 = x2 * x10;
      x14 = x2 * x12;
      x16 = x2 * x14;
    in
      multiplier *
        (1.0
         - x2 / 2.0
         + x4 / 24.0
         - x6 / 720.0
         + x8 / 40320.0
         - x10 / 3628800.0
         + x12 / 479001600.0
         - x14 / 87178291200.0
         + x16 / 20922789888000.0);

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
  truncate =
    if builtins ? floor
    then
      f:
        if builtins.isInt f then
          f
        else if f <= (toFloat minInt) || f >= (toFloat maxInt) then
          builtins.throw "std.num.truncate: integer overflow"
        else if f >= 0 then
          builtins.floor f
        else
          let
            p = builtins.floor f;
          in if p < f
            then p + 1
            else p
    else
      f:
        let
          # truncate float in range [0.0,2.0)
          truncate1 = x: if x < 1.0 then 0 else 1;
          go = x:
            if x < 1.0 then
              0
            else
              let y = 2 * go (x / 2);
              in y + truncate1 (x - y);
        in
          if builtins.isInt f then
            f
          else if f <= (toFloat minInt) || f >= (toFloat maxInt) then
            builtins.throw "std.num.truncate: integer overflow"
          else if f < 0.0 then
            -go (-f)
          else
            go f;

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

  /* tryParseInt :: string -> optional int

     Attempt to parse a string into an int. Returns `optional.nothing` on an
     unsuccessful parse.
  */
  tryParseInt = x:
    let
      # fromJSON aborts on invalid JSON values; check that it matches first
      matches = builtins.match jsonIntRE x != null;
      res = builtins.fromJSON x;
    in if matches && builtins.isInt res
      then optional.just res
      else optional.nothing;

  /* @partial
     parseInt :: string -> int

     Attempt to parse a string into an int. If parsing fails, throw an
     exception.
  */
  parseInt = x: optional.match (tryParseInt x) {
    nothing = throw "std.num.parseInt: failed to parse";
    just = res: res;
  };

  /* tryParseFloat :: string -> optional float

     Attempt to parse a string into a float. Returns `optional.nothing` on an
     unsuccessful parse.
  */
  tryParseFloat = x:
    let
      # fromJSON aborts on invalid JSON values; check that it matches first
      matches = builtins.match jsonNumberRE x != null;
      res = builtins.fromJSON x;
    in if matches && (builtins.isFloat res || builtins.isInt res)
      then optional.just res
      else optional.nothing;

  /* @partial
     parseFloat :: string -> float

     Attempt to parse a string into a float. If parsing fails, throw an
     exception.
  */
  parseFloat = x: optional.match (tryParseFloat x) {
    nothing = throw "std.num.parseFloat: failed to parse";
    just = res: res;
  };

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
    let toHexDigit = string.unsafeIndex "0123456789abcdef";
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

  /* clamp :: num -> num -> num

     Clamp the value of the third argument to be between the first two
     arguments, so that the result is lower-bounded by the first argument and
     upper-bounded by the second.
  */
  clamp = lo: hi: x: min (max lo x) hi;

  /* maxInt :: int

     The highest representable positive integer.
  */
  maxInt = 9223372036854775807; # 2^63 - 1

  /* minInt :: int

     The lowest representable negative integer.
  */
  minInt = maxInt + 1; # relies on 2's complement representation

  bits =
    let
      # table of (bit n) for 0 <= n <= (sizeof(int) - 1)
      powtab = [
        1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536
        131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432
        67108864 134217728 268435456 536870912 1073741824 2147483648 4294967296
        8589934592 17179869184 34359738368 68719476736 137438953472 274877906944
        549755813888 1099511627776 2199023255552 4398046511104 8796093022208
        17592186044416 35184372088832 70368744177664 140737488355328
        281474976710656 562949953421312 1125899906842624 2251799813685248
        4503599627370496 9007199254740992 18014398509481984 36028797018963968
        72057594037927936 144115188075855872 288230376151711744
        576460752303423488 1152921504606846976 2305843009213693952
        4611686018427387904 (9223372036854775807 + 1)
      ];
      # De Bruijn multiplication lookup table, used for bitScanReverse
      debruijn = [
        0 47 1 56 48 27 2 60
        57 49 41 37 28 16 3 61
        54 58 35 52 50 42 21 44
        38 32 29 23 17 11 4 62
        46 55 26 59 40 36 15 53
        34 51 20 43 31 22 10 45
        25 39 14 33 19 30 9 24
        13 18 8 12 7 6 5 63
      ];
    in rec {
      /* bitSize :: int

         The number of bits used to represent an integer in Nix.
      */
      bitSize = 64;

      /* bitAnd :: int -> int -> int

         Computes the bitwise AND of the 2's complement binary representations
         of the given numbers.
      */
      bitAnd = builtins.bitAnd;

      /* bitOr :: int -> int -> int

         Computes the bitwise OR of the 2's complement binary representations of
         the given numbers.
      */
      bitOr = builtins.bitOr;

      /* bitXor :: int -> int -> int

         Computes the bitwise XOR (exclusive OR) of the 2's complement binary
         representations of the given numbers.
      */
      bitXor = builtins.bitXor;

      /* bitNot :: int -> int

         Computes the bitwise NOT (complement) of the 2's complement binary
         representation of the given number.
      */
      bitNot = builtins.bitXor (-1); # -1 is all 1's in 2's complement

      /* bit :: int -> bool

         Gives the number whose 2's complement binary representation contains a
         single bit set at the given index, in which index 0 corresponds to the
         least-significant bit.
      */
      bit = n: shiftL 1 n;

      /* set :: int -> int -> bool

         Sets the bit in the provided number at the provided index in its 2's
         complement binary representation, in which index 0 corresponds to the
         least-significant bit.
      */
      set = x: n: bitOr x (bit n);

      /* clear :: int -> int -> bool

         Clears the bit in the provided number at the provided index in its 2's
         complement binary representation, in which index 0 corresponds to the
         least-significant bit. "Clear" means the bit is unset; an unset bit
         will remain unset, and a set bit will be unset.
      */
      clear = x: n: bitAnd x (bitNot (bit n));

      /* toggle :: int -> int -> bool

         Toggles the bit in the provided number at the provided index in its 2's
         complement binary representation, in which index 0 corresponds to the
         least-significant bit. "Toggle" means the bit is inverted; an unset bit
         will be set, and a set bit will be unset.
      */
      toggle = x: n: bitXor x (bit n);

      /* test :: int -> int -> bool

         Tests the given number to see if the bit at the provided index in its
         2's complement binary representation, in which index 0 corresponds to
         the least-significant bit, is set.
      */
      test = x: n: bitAnd x (bit n) != 0;

      /* shiftL :: int -> int -> int

         Perform a left shift of the bits in the 2's complement binary
         representation of the given number by the provided number of places.

         If the number of places is larger than the bitsize, the result will
         always be 0.

         If the number of places is negative, a signed right shift will be
         performed.
      */
      shiftL = x: n:
        if n == 0
          then x
        else if n < 0
          then shiftR x (-n)
        else if n >= bitSize
          then 0
        else x * builtins.elemAt powtab n;

      /* shiftLU :: int -> int -> int

         Perform a left shift of the bits in the 2's complement binary
         representation of the given number by the provided number of places.
         For positive shift values, this is equivalent to `shiftL`.

         If the number of places is larger than the bitsize, the result will
         always be 0.

         If the number of places is negative, an unsigned right shift will be
         performed.
      */
      shiftLU = x: n:
        if n == 0
          then x
        else if n < 0
          then shiftRU x (-n)
        else if n >= bitSize
          then 0
        else x * builtins.elemAt powtab n;

      /* shiftR :: int -> int -> int

         Perform a signed (arithmetic) right shift of the bits in the 2's
         complement binary representation of the given number by the provided
         number of places. It is unsigned in that the new bits filled in on the
         left will always match the sign bit before shifting, preserving the
         sign of the number.

         If the number of places is larger than the bitsize, the result will
         always be 0 if the input was positive, or -1 otherwise.
      */
      shiftR = x: n:
        if n == 0
          then x
        else if n < 0
          then shiftL x (-n)
        else if n >= bitSize
          then (if x < 0 then -1 else 0)
        else if x < 0
          then ((x + minInt) / (builtins.elemAt powtab n)) - builtins.elemAt powtab (63 - n)
        else x / builtins.elemAt powtab n;

      /* shiftRU :: int -> int -> int

         Perform an unsigned (logical) right shift of the bits in the 2's
         complement binary representation of the given number by the provided
         number of places. It is unsigned in that the new bits filled in on the
         left will always be 0.

         If the number of places is larger than the bitsize, the result will
         always be 0.
      */
      shiftRU = x: n:
        if n == 0
          then x
        else if n < 0
          then shiftL x (-n)
        else if n >= bitSize
          then 0
        else if x < 0
          then ((x + minInt) / (builtins.elemAt powtab n)) + builtins.elemAt powtab (63 - n)
        else x / builtins.elemAt powtab n;

      /* rotateL :: int -> int -> int

         Perform a left rotation of the bits in the 2's complement binary
         representation of the given number by the provided number of places.
      */
      rotateL = x: n:
        let n' = mod n bitSize;
        in bitOr (shiftL x n') (shiftRU x (bitSize - n'));

      /* rotateR :: int -> int -> int

         Perform a right rotation of the bits in the 2's complement binary
         representation of the given number by the provided number of places.
      */
      rotateR = x: n:
        let n' = mod n bitSize;
        in bitOr (shiftRU x n') (shiftL x (bitSize - n'));

      /* popCount :: int -> int

         Counts the number of set bits in the 2's complement binary
         representation of the given integer.
      */
      popCount = x0:
        # NOTE: this is hardcoded based on 'bitSize'.
        #
        # We divide-and-conquer, starting by counting the number of set bits in
        # every pair of bits, then adding every pair of pairs, and so on.
        # The constants follow the following pattern:
        # - 0x5555555555555555 and 0xAAAAAAAAAAAAAAAA (every other bit)
        # - 0x3333333333333333 and 0xCCCCCCCCCCCCCCCC (every other two bits)
        # - 0x0F0F0F0F0F0F0F0F and 0xF0F0F0F0F0F0F0F0 (every other four bits)
        # - ...
        # - 0x00000000FFFFFFFF and 0xFFFFFFFF00000000
        let
          x1 = (bitAnd x0 6148914691236517205) + shiftRU (bitAnd x0 (-6148914691236517206)) 1;
          x2 = (bitAnd x1 3689348814741910323) + shiftRU (bitAnd x1 (-3689348814741910324)) 2;
          x3 = (bitAnd x2 1085102592571150095) + shiftRU (bitAnd x2 (-1085102592571150096)) 4;
          x4 = (bitAnd x3 71777214294589695) + shiftRU (bitAnd x3 (-71777214294589696)) 8;
          x5 = (bitAnd x4 281470681808895) + shiftRU (bitAnd x4 (-281470681808896)) 16;
          x6 = (bitAnd x5 4294967295) + shiftRU (bitAnd x5 (-4294967296)) 32;
        in x6;

      /* bitScanForward :: int -> int

         Computes the index of the lowest set bit in the 2's complement
         binary representation of the given integer, where index 0 corresponds
         to the least-significant bit. If there are no bits set, the index will
         be equal to `num.bits.bitSize`.
      */
      bitScanForward = x0:
        if x0 == 0
        then 64
        else popCount (bitAnd x0 (-x0) - 1);

      /* countTrailingZeros :: int -> int

         Computes the number of zeros after (in place values less than) the
         lowest set bit in the 2's complement binary representation of the given
         integer, where index 0 corresponds to the least-significant bit. If
         there are no bits set, the result will be equal to `num.bits.bitSize`.
      */
      countTrailingZeros = x0:
        if x0 == 0
          then 64
          else bitScanForward x0;

      /* bitScanReverse :: int -> int

         Computes the index of the highest set bit in the 2's complement
         representation of the given integer, where index 0 corresponds to the
         least-significant bit. If there are no bits set, the index will be
         equal to `num.bits.bitSize`.
      */
      bitScanReverse = x0:
        let
          x1 = bitOr x0 (x0 / 2);
          x2 = bitOr x1 (x1 / 4);
          x3 = bitOr x2 (x2 / 16);
          x4 = bitOr x3 (x3 / 256);
          x5 = bitOr x4 (x4 / 65536);
          x6 = bitOr x5 (x5 / 4294967296);
        in
          if x0 == 0
            then 64
          else if x0 < 0 # MSB is set
            then 63
          else builtins.elemAt debruijn (shiftRU (x6 * 285870213051386505) 58);

      /* countLeadingZeros :: int -> int

         Computes the number of zeros before (in place values greater than) the
         highest set bit in the 2's complement binary representation of the
         given integer, where index 0 corresponds to the least-significant bit.
         If there are no bits set, the result will be equal to
         `num.bits.bitSize`.
      */
      countLeadingZeros = x0:
        if x0 == 0
          then 64
          else bitXor (bitScanReverse x0) 63;
    };
}
