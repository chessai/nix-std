with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.string" {
  laws = string.unlines [
    (semigroup string.semigroup {
      typeName = "string";
      associativity = {
        a = "foo";
        b = "bar";
        c = "baz";
      };
    })
    (monoid string.monoid {
      typeName = "string";
      leftIdentity = {
        x = "foo";
      };
      rightIdentity = {
        x = "bar";
      };
    })
  ];
  substring = string.unlines [
    (assertEqual (string.substring 2 3 "foobar") "oba")
    (assertEqual (string.substring 4 7 "foobar") "ar")
    (assertEqual (string.substring 10 5 "foobar") string.empty)
    (assertEqual (string.substring 1 (-20) "foobar") "oobar")
  ];
  index = assertEqual (string.index "foobar" 3) "b";
  length = assertEqual (string.length "foo") 3;
  empty = string.unlines [
    (assertEqual (string.isEmpty "a") false)
    (assertEqual (string.isEmpty string.empty) true)
  ];
  replace = assertEqual (string.replace ["o" "a"] ["u " "e "] "foobar") "fu u be r";
  concat = assertEqual (string.concat ["foo" "bar"]) "foobar";
  concatSep = assertEqual (string.concatSep ", " ["1" "2" "3"]) "1, 2, 3";
  concatMap = assertEqual (string.concatMap builtins.toJSON [ 1 2 3 ]) "123";
  concatMapSep = assertEqual (string.concatMapSep ", " builtins.toJSON [ 1 2 3 ]) "1, 2, 3";
  concatImap = assertEqual (string.concatImap (i: x: x + builtins.toJSON i) [ "foo" "bar" "baz" ]) "foo0bar1baz2";
  concatImapSep = assertEqual (string.concatImapSep "\n" (i: x: builtins.toJSON (i + 1) + ": " + x) [ "foo" "bar" "baz" ]) "1: foo\n2: bar\n3: baz";
  toChars = assertEqual (string.toChars "foo") ["f" "o" "o"];
  map = assertEqual (string.map (x: x + " ") "foo") "f o o ";
  imap = assertEqual (string.imap (i: x: builtins.toJSON i + x) "foo") "0f1o2o";
  filter = assertEqual (string.filter (x: x != " ") "foo bar baz") "foobarbaz";
  findIndex = assertEqual (string.findIndex (x: x == " ") "foo bar baz") (optional.just 3);
  findLastIndex = assertEqual (string.findLastIndex (x: x == " ") "foo bar baz") (optional.just 7);
  find = string.unlines [
    (assertEqual (string.find (x: x == " ") "foo bar baz") (optional.just " "))
    (assertEqual (string.find (x: x == "q") "foo bar baz") optional.nothing)
  ];
  findLast = string.unlines [
    (assertEqual (string.find (x: x == " ") "foo bar baz") (optional.just " "))
    (assertEqual (string.find (x: x == "q") "foo bar baz") optional.nothing)
  ];
  escape = assertEqual (string.escape ["$"] "foo$bar") "foo\\$bar";
  escapeShellArg = assertEqual (string.escapeShellArg "foo 'bar' baz") "'foo '\\''bar'\\'' baz'";
  escapeNixString = assertEqual (string.escapeNixString "foo$bar") ''"foo\$bar"'';
  hasPrefix = string.unlines [
    (assertEqual (string.hasPrefix "foo" "foobar") true)
    (assertEqual (string.hasPrefix "foo" "barfoo") false)
    (assertEqual (string.hasPrefix "foo" string.empty) false)
  ];
  hasSuffix = string.unlines [
    (assertEqual (string.hasSuffix "foo" "barfoo") true)
    (assertEqual (string.hasSuffix "foo" "foobar") false)
    (assertEqual (string.hasSuffix "foo" string.empty) false)
  ];
  hasInfix = string.unlines [
    (assertEqual (string.hasInfix "bar" "foobarbaz") true)
    (assertEqual (string.hasInfix "foo" "foobar") true)
    (assertEqual (string.hasInfix "bar" "foobar") true)
  ];
  removePrefix = string.unlines [
    (assertEqual (string.removePrefix "/" "/foo") "foo")
    (assertEqual (string.removePrefix "/" "foo") "foo")
  ];
  removeSuffix = string.unlines [
    (assertEqual (string.removeSuffix ".nix" "foo.nix") "foo")
    (assertEqual (string.removeSuffix ".nix" "foo") "foo")
  ];
  count = assertEqual (string.count "." ".a.b.c.d.") 5;
  optional = string.unlines [
    (assertEqual (string.optional true "foo") "foo")
    (assertEqual (string.optional false "foo") string.empty)
  ];
  head = assertEqual (string.head "bar") "b";
  tail = assertEqual (string.tail "bar") "ar";
  init = assertEqual (string.init "bar") "ba";
  last = assertEqual (string.last "bar") "r";
  take = string.unlines [
    (assertEqual (string.take 3 "foobar") "foo")
    (assertEqual (string.take 7 "foobar") "foobar")
    (assertEqual (string.take (-1) "foobar") string.empty)
  ];
  drop = string.unlines [
    (assertEqual (string.drop 3 "foobar") "bar")
    (assertEqual (string.drop 7 "foobar") string.empty)
    (assertEqual (string.drop (-1) "foobar") "foobar")
  ];
  takeEnd = string.unlines [
    (assertEqual (string.takeEnd 3 "foobar") "bar")
    (assertEqual (string.takeEnd 7 "foobar") "foobar")
    (assertEqual (string.takeEnd (-1) "foobar") string.empty)
  ];
  dropEnd = string.unlines [
    (assertEqual (string.dropEnd 3 "foobar") "foo")
    (assertEqual (string.dropEnd 7 "foobar") string.empty)
    (assertEqual (string.dropEnd (-1) "foobar") "foobar")
  ];
  takeWhile = assertEqual (string.takeWhile (x: x != " ") "foo bar baz") "foo";
  dropWhile = assertEqual (string.dropWhile (x: x != " ") "foo bar baz") " bar baz";
  takeWhileEnd = assertEqual (string.takeWhileEnd (x: x != " ") "foo bar baz") "baz";
  dropWhileEnd = assertEqual (string.dropWhileEnd (x: x != " ") "foo bar baz") "foo bar ";
  splitAt = assertEqual (string.splitAt 3 "foobar") { _0 = "foo"; _1 = "bar"; };
  span = assertEqual (string.span (x: x != " ") "foo bar baz") { _0 = "foo"; _1 = " bar baz"; };
  break = assertEqual (string.break (x: x == " ") "foo bar baz") { _0 = "foo"; _1 = " bar baz"; };
  reverse = string.unlines [
    (assertEqual (string.reverse "foobar") "raboof")
    (assertEqual (string.reverse string.empty) string.empty)
  ];
  replicate = string.unlines [
    (assertEqual (string.replicate 3 "foo") "foofoofoo")
    (assertEqual (string.replicate 0 "bar") string.empty)
  ];
  lines = string.unlines [
    (assertEqual (string.lines "foo\nbar\n") [ "foo" "bar" ])
    (assertEqual (string.lines "foo\nbar") [ "foo" "bar" ])
    (assertEqual (string.lines "\n") [ string.empty ])
    (assertEqual (string.lines string.empty) [])
  ];
  unlines = string.unlines [
    (assertEqual (string.unlines [ "foo" "bar" ]) "foo\nbar\n")
    (assertEqual (string.unlines []) string.empty)
  ];
  words = string.unlines [
    (assertEqual (string.words "foo \t bar   ") [ "foo" "bar" ])
    (assertEqual (string.words " ") [])
    (assertEqual (string.words string.empty) [])
  ];
  unwords = assertEqual (string.unwords [ "foo" "bar" ]) "foo bar";
  intercalate = assertEqual (string.intercalate ", " ["1" "2" "3"]) "1, 2, 3";
  toLower = assertEqual (string.toLower "FOO bar") "foo bar";
  toUpper = assertEqual (string.toUpper "FOO bar") "FOO BAR";
  strip = string.unlines [
    (assertEqual (string.strip "   \t\t  foo   \t") "foo")
    (assertEqual (string.strip "   \t\t   \t") string.empty)
  ];
  stripStart = assertEqual (string.stripStart "   \t\t  foo   \t") "foo   \t";
  stripEnd = assertEqual (string.stripEnd "   \t\t  foo   \t") "   \t\t  foo";
  justifyLeft = string.unlines [
    (assertEqual (string.justifyLeft 7 "x" "foo") "fooxxxx")
    (assertEqual (string.justifyLeft 2 "x" "foo") "foo")
    (assertEqual (string.justifyLeft 9 "xyz" "foo") "fooxyzxyz")
    (assertEqual (string.justifyLeft 7 "xyz" "foo") "fooxyzx")
  ];
  justifyRight = string.unlines [
    (assertEqual (string.justifyRight 7 "x" "foo") "xxxxfoo")
    (assertEqual (string.justifyRight 2 "x" "foo") "foo")
    (assertEqual (string.justifyRight 9 "xyz" "foo") "xyzxyzfoo")
    (assertEqual (string.justifyRight 7 "xyz" "foo") "xyzxfoo")
  ];
  justifyCenter = string.unlines [
    (assertEqual (string.justifyCenter 7 "x" "foo") "xxfooxx")
    (assertEqual (string.justifyCenter 2 "x" "foo") "foo")
    (assertEqual (string.justifyCenter 8 "xyz" "foo") "xyfooxyz")
  ];
}
