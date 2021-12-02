with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.set" {
  toList = let
    s = { a = 0; };
    xs = [ { _0 = "a"; _1 = 0; } ];
  in string.unlines [
    (assertEqual (set.fromList xs) s)
    (assertEqual (set.toList s) xs)
  ];
}
