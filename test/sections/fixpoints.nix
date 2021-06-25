with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.fixpoints" {
  fix = string.unlines [
    (assertEqual 0 (fixpoints.fix (const 0)))
    (assertEqual 120 (fixpoints.fix (r: n: if n == 0 then 1 else builtins.mul n (r (n - 1))) 5))
  ];
  until = assertEqual 400 (fixpoints.until (x: num.mod x 20 == 0) (compose (builtins.add 1) (builtins.mul 7)) 1);
}
