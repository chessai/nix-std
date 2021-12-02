with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

let
  testSet = { a = 0; b = 1; c = 2; };
in section "std.set" {
  empty = assertEqual set.empty {};
  optional = string.unlines [
    (assertEqual set.empty (set.optional false testSet))
    (assertEqual testSet (set.optional true testSet))
  ];
  keys = assertEqual ["a" "b" "c"] (set.keys testSet);
  values = assertEqual [0 1 2] (set.values testSet);
  map = assertEqual { a = 1; b = 2; c = 3; } (set.map (_: num.add 1) testSet);
  zip = assertEqual { a = [0 1]; b = [1]; c = [2]; } (set.mapZip (_: function.id) [testSet { a = 1; }]);
  without = assertEqual { b = 1; c = 2; } (set.without [ "a" ] testSet);
  retain = assertEqual { a = 0; } (set.retain [ "a" ] testSet);
  filter = assertEqual { b = 1; } (set.filter (k: v: v == 1) testSet);
  traverse = assertEqual testSet (set.traverse nullable.applicative (x: if (num.even x || num.odd x) then x else null) testSet);
  toList = assertEqual [
    { _0 = "a"; _1 = 0; }
    { _0 = "b"; _1 = 1; }
    { _0 = "c"; _1 = 2; }
  ] (set.toList testSet);
  fromList = assertEqual testSet (set.fromList (set.toList testSet));
  gen = assertEqual (set.gen [ "a" "b" ] id) { a = "a"; b = "b"; };
}
