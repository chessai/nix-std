with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

let
  testFn = { a, b, c ? 1 }: a + b + c;
  testFnSet = {
    __functor = _: testFn;
    foo = "bar";
  };
  testArgs = { a = 0; b = 1; };
in section "std.function" {
  callable = string.unlines [
    (assertEqual 2 (testFn testArgs))
    (assertEqual 2 (testFnSet testArgs))
  ];
  isLambda = string.unlines [
    (assertEqual true (builtins.isFunction testFn))
    (assertEqual false (builtins.isFunction testFnSet))
  ];
  args = string.unlines [
    (assertEqual { a = false; b = false; c = true; } (function.args testFn))
    (assertEqual { a = false; b = false; c = true; } (function.args testFnSet))
  ];
  setArgs = assertEqual { a = false; b = false; } (function.args (
    function.setArgs (set.without ["c"] (function.args testFn)) testFn
  ));
  toFunctionSet = string.unlines [
    (assertEqual true ((function.toSet testFnSet) ? foo))
    (assertEqual 2 (function.toSet testFn testArgs))
    (assertEqual 2 (function.toSet testFnSet testArgs))
  ];
}
