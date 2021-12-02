with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.set" {
  filter = assertEqual set.empty (set.filter (_: const false) { a = 0; });
}
