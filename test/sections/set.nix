with { std = import ./../../default.nix; };
with std;
with { inherit (std.tuple) tuple2; };

with (import ./../framework.nix);

let
  testSet = { a = 0; b = 1; c = 2; };
in section "std.set" {
  check = string.unlines [
    (assertEqual true (types.attrs.check {}))
    (assertEqual false (types.attrs.check []))
    (assertEqual true ((types.attrsOf types.int).check testSet))
    (assertEqual true ((types.attrsOf types.int).check {}))
    (assertEqual false ((types.attrsOf types.int).check (testSet // { d = "foo"; })))
  ];

  show = string.unlines [
    (assertEqual "{ a = 0; b = 1; c = 2; }" (types.attrs.show testSet))
    (assertEqual "{ }" (types.attrs.show {}))
  ];

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
  mapToValues = assertEqual [ 1 2 3 ] (set.mapToValues (_: num.add 1) testSet);
  filter = assertEqual { b = 1; } (set.filter (k: v: v == 1) testSet);
  traverse = assertEqual testSet (set.traverse nullable.applicative (x: if (num.even x || num.odd x) then x else null) testSet);
  toList = assertEqual [
    (tuple2 "a" 0)
    (tuple2 "b" 1)
    (tuple2 "c" 2)
  ] (set.toList testSet);
  fromList = assertEqual testSet (set.fromList (set.toList testSet));
  gen = assertEqual (set.gen [ "a" "b" ] id) { a = "a"; b = "b"; };

  get = string.unlines [
    (assertEqual (set.get "a" { a = 0; }) (optional.just 0))
    (assertEqual (set.get "a" { }) optional.nothing)
    (assertEqual (set.unsafeGet "a" { a = 0; }) 0)
  ];
  getOr = assertEqual (set.getOr 0 "a" {}) 0;

  at = string.unlines [
    (assertEqual (set.at [ "a" "b" ] { a.b = 0; }) (optional.just 0))
    (assertEqual (set.at [ "a" "c" ] { a.b = 0; }) optional.nothing)
    (assertEqual (set.at [ "a" "b" "c" ] { a.b = 0; }) optional.nothing)
    (assertEqual (set.unsafeAt [ "a" "b" ] { a.b = 0; }) 0)
  ];
  atOr = assertEqual (set.atOr null [ "a" "b" "c" ] { a.b = 0; }) null;

  assign = assertEqual (set.assign "a" 0 { }) { a = 0; };
  assignAt = assertEqual (set.assignAt [ "a" ] 0 { }) { a = 0; };
  assignAtPath = assertEqual (set.assignAt [ "a" "x" ] 0 { }) { a.x = 0; };
  assignAtEmpty = assertEqual (set.assignAt [ ] { a = 0; } testSet) { a = 0; };
  assignAtMerge = assertEqual (set.assignAt [ "x" "y" ] 0 testSet) (testSet // { x.y = 0; });
}
