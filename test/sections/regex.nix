with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.regex" {
  escape = assertEqual (regex.escape ''.[]{}()\*+?|^$'') ''\.\[]\{\}\(\)\\\*\+\?\|\^\$'';

  capture = assertEqual (regex.capture "foo") "(foo)";

  match = string.unlines [
    (assertEqual
      (regex.match "([[:alpha:]]+)([[:digit:]]+)" "foo123")
      (optional.just ["foo" "123"]))
    (assertEqual
      (regex.match "([[:alpha:]]+)([[:digit:]]+)" "foobar")
      optional.nothing)
  ];

  allMatches = assertEqual (regex.allMatches "[[:digit:]]+" "foo 123 bar 456") ["123" "456"];

  firstMatch = string.unlines [
    (assertEqual (regex.firstMatch "[aeiou]" "foobar") (optional.just "o"))
    (assertEqual (regex.firstMatch "[aeiou]" "xyzzyx") optional.nothing)
  ];

  lastMatch = string.unlines [
    (assertEqual (regex.lastMatch "[aeiou]" "foobar") (optional.just "a"))
    (assertEqual (regex.lastMatch "[aeiou]" "xyzzyx") optional.nothing)
  ];

  split = assertEqual (regex.split "(,)" "1,2,3") ["1" [","] "2" [","] "3"];

  splitOn = assertEqual (regex.splitOn "(,)" "1,2,3") ["1" "2" "3"];

  substituteWith = assertEqual (regex.substituteWith "([[:digit:]])" (g: builtins.toJSON (builtins.fromJSON (builtins.head g) + 1)) "123") "234";

  substitute = assertEqual (regex.substitute "[aeiou]" "\\0\\0" "foobar") "foooobaar";
}
