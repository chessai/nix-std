with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.tuple" {
  fromList = assertEqual (tuple.fromList [ 0 1 ]) { _0 = 0; _1 = 1; };
}
