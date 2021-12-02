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
  check = string.unlines [
    (assertEqual true (types.function.check testFn))
    (assertEqual true (types.lambda.check testFn))
    (assertEqual false (types.functionSet.check testFn))
    (assertEqual true (types.function.check testFnSet))
    (assertEqual true (types.functionSet.check testFnSet))
    (assertEqual false (types.lambda.check testFnSet))
  ];
  show = string.unlines [
    (assertEqual "«lambda»" (types.function.show function.id))
    (assertEqual "{ a, b, c ? «code» }: «code»" (types.function.show testFn))
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
    (assertEqual true (types.functionSet.check (function.toSet testFn)))
  ];
}
