with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.num.bits" {
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
}
