{
  tuple0 = { };
  tuple1 = _0: { inherit _0; };
  tuple2 = _0: _1: { inherit _0 _1; };
  tuple3 = _0: _1: _2: { inherit _0 _1 _2; };
  tuple4 = _0: _1: _2: _3: { inherit _0 _1 _2 _3; };
  tuple5 = _0: _1: _2: _3: _4: { inherit _0 _1 _2 _3 _4; };
  tuple6 = _0: _1: _2: _3: _4: _5: { inherit _0 _1 _2 _3 _4 _5; };
  tuple7 = _0: _1: _2: _3: _4: _5: _6: { inherit _0 _1 _2 _3 _4 _5 _6; };
  tuple8 = _0: _1: _2: _3: _4: _5: _6: _7: { inherit _0 _1 _2 _3 _4 _5 _6 _7; };
  tuple9 = _0: _1: _2: _3: _4: _5: _6: _7: _8: { inherit _0 _1 _2 _3 _4 _5 _6 _7 _8; };
  tuple10 = _0: _1: _2: _3: _4: _5: _6: _7: _8: _9: { inherit _0 _1 _2 _3 _4 _5 _6 _7 _8 _9; };

  map1 = f0: { _0 }: { _0 = f0 _0; };
  map2 = f0: f1: { _0, _1 }: { _0 = f0 _0; _1 = f1 _1; };
  map3 = f0: f1: f2: { _0, _1, _2 }: { _0 = f0 _0; _1 = f1 _1; _2 = f2 _2; };
  map4 = f0: f1: f2: f3: { _0, _1, _2, _3 }: { _0 = f0 _0; _1 = f1 _1; _2 = f2 _2; _3 = f3 _3; };
  map5 = f0: f1: f2: f3: f4: { _0, _1, _2, _3, _4 }: { _0 = f0 _0; _1 = f1 _1; _2 = f2 _2; _3 = f3 _3; _4 = f4 _4; };
  map6 = f0: f1: f2: f3: f4: f5: { _0, _1, _2, _3, _4, _5 }: { _0 = f0 _0; _1 = f1 _1; _2 = f2 _2; _3 = f3 _3; _4 = f4 _4; _5 = f5 _5; };
  map7 = f0: f1: f2: f3: f4: f5: f6: { _0, _1, _2, _3, _4, _5, _6 }: { _0 = f0 _0; _1 = f1 _1; _2 = f2 _2; _3 = f3 _3; _4 = f4 _4; _5 = f5 _5; _6 = f6 _6; };
  map8 = f0: f1: f2: f3: f4: f5: f6: f7: { _0, _1, _2, _3, _4, _5, _6, _7 }: { _0 = f0 _0; _1 = f1 _1; _2 = f2 _2; _3 = f3 _3; _4 = f4 _4; _5 = f5 _5; _6 = f6 _6; _7 = f7 _7; };
  map9 = f0: f1: f2: f3: f4: f5: f6: f7: f8: { _0, _1, _2, _3, _4, _5, _6, _7, _8 }: { _0 = f0 _0; _1 = f1 _1; _2 = f2 _2; _3 = f3 _3; _4 = f4 _4; _5 = f5 _5; _6 = f6 _6; _7 = f7 _7; _8 = f8 _8; };
  map10 = f0: f1: f2: f3: f4: f5: f6: f7: f8: f9: { _0, _1, _2, _3, _4, _5, _6, _7, _8, _9 }: { _0 = f0 _0; _1 = f1 _1; _2 = f2 _2; _3 = f3 _3; _4 = f4 _4; _5 = f5 _5; _6 = f6 _6; _7 = f7 _7; _8 = f8 _8; _9 = f9 _9; };

  over0 = f: x@{ _0, ... }: x // { _0 = f _0; };
  over1 = f: x@{ _1, ... }: x // { _1 = f _1; };
  over2 = f: x@{ _2, ... }: x // { _2 = f _2; };
  over3 = f: x@{ _3, ... }: x // { _3 = f _3; };
  over4 = f: x@{ _4, ... }: x // { _4 = f _4; };
  over5 = f: x@{ _5, ... }: x // { _5 = f _5; };
  over6 = f: x@{ _6, ... }: x // { _6 = f _6; };
  over7 = f: x@{ _7, ... }: x // { _7 = f _7; };
  over8 = f: x@{ _8, ... }: x // { _8 = f _8; };
  over9 = f: x@{ _9, ... }: x // { _9 = f _9; };
  over10 = f: x@{ _10, ... }: x // { _10 = f _10; };

  /* toPair :: (a, b) -> { name : a, value : b }

     Converts a 2-tuple to the argument required by e.g. `builtins.listToAttrs`
  */
  toPair = { _0, _1 }: { name = _0; value = _1; };
}