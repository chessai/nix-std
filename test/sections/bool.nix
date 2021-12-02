with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.bool" {
  true = assertEqual builtins.true bool.true;
  false = assertEqual builtins.false bool.false;
  not = string.unlines [
    (assertEqual (bool.not false) true)
    (assertEqual (bool.not true) false)
  ];
  ifThenElse = string.unlines [
    (assertEqual (ifThenElse true "left" "right") "left")
    (assertEqual (ifThenElse false "left" "right") "right")
  ];
  toOptional = string.unlines [
    (assertEqual (optional.just 0) (bool.toOptional true 0))
    (assertEqual optional.nothing (bool.toOptional false 0))
  ];
  toNullable = string.unlines [
    (assertEqual 0 (bool.toNullable true 0))
    (assertEqual null (bool.toNullable false 0))
  ];
}
