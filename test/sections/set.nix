with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

let
  testSet = { a = 0; b = 1; c = 2; };
in section "std.set" {
  empty = assertEqual set.empty {};
  keys = assertEqual ["a" "b" "c"] (set.keys testSet);
  values = assertEqual [0 1 2] (set.values testSet);
  map = assertEqual { a = 1; b = 2; c = 3; } (set.map (_: num.add 1) testSet);
  zip = assertEqual { a = [0 1]; b = [1]; c = [2]; } (set.mapZip (_: function.id) [testSet { a = 1; }]);
  filter = assertEqual { b = 1; } (set.filter (k: v: v == 1) testSet);
  toList = assertEqual [
    { _0 = "a"; _1 = 0; }
    { _0 = "b"; _1 = 1; }
    { _0 = "c"; _1 = 2; }
  ] (set.toList testSet);
  fromList = assertEqual testSet (set.fromList (set.toList testSet));
}
