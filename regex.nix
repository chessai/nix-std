with rec {
  string = import ./string.nix;
  list = import ./list.nix;
  optional = import ./optional.nix;
};

rec {
  /* escape :: string -> regex

     Turn a string into a regular expression matching the exact string. Escapes
     any special characters used in regular expressions.

     > regex.escape "a+b"
     "a\\+b"

     For example, to see if a string is contained in another string:

     > optional.isJust (regex.firstMatch (regex.escape "a+b") "a+b+c")
     true
  */
  escape = string.escape ["\\" "^" "$" "." "+" "*" "?" "|" "(" ")" "[" "{" "}"];

  /* capture :: regex -> regex

     Turn a regex into a capturing regex. Simply wraps the entire regex in a
     capture group.

     > regex.capture "foo"
     "(foo)"
  */
  capture = re: "(${re})";

  /* match :: regex -> string -> optional [nullable string]

     Test if a string matches a regular expression exactly. The output is
     `optional.nothing` if the string does not match the regex, or a list of
     capture groups if it does.

     Fails if the provided regex is invalid.

     > regex.match "([[:alpha:]]+)([[:digit:]]+)" "foo123"
     { _tag = "just"; value = [ "foo" "123" ]; }
     > regex.match "([[:alpha:]]+)([[:digit:]]+)" "foobar"
     { _tag = "nothing"; }

     To check whether or not a string matches a regex, simply check if the
     result of 'match' is non-null:

     > optional.isJust (regex.match "[[:digit:]]+" "123")
     true

     Note that using '+' or '*' on a capture group will only retain the last
     occurrence. If you use '*' on a capture group with zero occurrences, that
     capture group will have a null result:

     > regex.match "([[:digit:]])*" "123"
     { _tag = "just"; value = [ "3" ]; }
     > regex.match "([[:digit:]])*" ""
     { _tag = "just"; value = [ null ]; }
  */
  match = re: str: optional.fromNullable (builtins.match re str);

  /* allMatches :: regex -> string -> [string]

     Find all occurrences (non-overlapping) of a regex in a string.

     Fails if the provided regex is invalid.

     > regex.allMatches "[[:digit:]]+" "foo 123 bar 456"
     [ "123" "456" ]
  */
  allMatches = regex: str:
    list.concatMap (g: if builtins.isList g then [(list.head g)] else []) (split (capture regex) str);

  /* firstMatch :: regex -> string -> optional string

     Returns the first occurrence of the pattern in the string, or
     `optional.nothing` if it does not occur.

     > regex.firstMatch "[aeiou]" "foobar"
     { _tag = "just"; value = "o"; }
     > regex.firstMatch "[aeiou]" "xyzzyx"
     { _tag = "nothing"; }
  */
  firstMatch = regex: str:
    let res = split (capture regex) str;
    in if list.length res > 1
      then optional.just (list.head (list.index res 1))
      else optional.nothing;

  /* lastMatch :: regex -> string -> optional string

     Returns the last occurrence of the pattern in the string, or
     `optional.nothing` if it does not occur.

     > regex.lastMatch "[aeiou]" "foobar"
     { _tag = "just"; value = "a"; }
     > regex.lastMatch "[aeiou]" "xyzzyx"
     { _tag = "nothing"; }
  */
  lastMatch = regex: str:
    let
      res = split (capture regex) str;
      len = list.length res;
    in if len > 1
      then optional.just (list.head (list.index res (len - 2)))
      else optional.nothing;

  /* split :: regex -> string -> [string | [nullable string]]

     Split a string using a regex. The result contains interspersed delimiters
     as lists of capture groups from the regex; see 'match' for details on
     capture groups.

     Note that if there is a leading or trailing delimeter, the first or last
     element of the result respectively will be the empty string.

     Fails if the provided regex is invalid.

     > regex.split "," "1,2,3"
     [ "1" [ ] "2" [ ] "3" ]
     > regex.split "(,)" "1,2,3,"
     [ "1" [ "," ] "2" [ "," ] "3" [ "," ] "" ]
  */
  split = builtins.split;

  /* splitOn :: regex -> string -> [string]

     Like 'split', but drops the delimiters.

     Fails if the provided regex is invalid.

     > regex.splitOn "," "1,2,3"
     [ "1" "2" "3" ]
  */
  splitOn = regex: str:
    list.filter (x: !builtins.isList x) (split regex str);

  /* substituteWith :: regex -> ([nullable string] -> string) -> string -> string

     Perform regex substitution on a string. Replaces each match with the result
     of the given function applied to the capture groups from the regex.

     Fails if the provided regex is invalid.

     > regex.substituteWith "([[:digit:]])" (g: builtins.toJSON (builtins.fromJSON (builtins.head g) + 1)) "123"
     "234"
  */
  substituteWith = regex: f: str:
    let replaceGroup = group:
          if builtins.isList group
            then f group
            else group;
    in string.concatMap (replaceGroup) (split regex str);

  /* substitute :: regex -> string -> string -> string

     Perform regex substitution on a string, replacing each match with the given
     replacement string. If the regex has capture groups, they can be referred
     to with references \1, \2, etc. The reference \0 refers to the entire
     match.

     Fails if the provided regex is invalid or if a reference is out of bounds
     for the number of capture groups.

     > regex.substitute "o" "a" "foobar"
     "faabar"
     > regex.substitute "[aeiou]" "\\0\\0" "foobar"
     "foooobaar"
  */
  substitute = regex: replace:
    let
      subs = split ''\\([[:digit:]]+)'' replace;
      replaceCaptures = captures:
        let
          replaceGroup = group:
            if builtins.isList group
              then list.index captures (builtins.fromJSON (list.head group))
              else group;
        in string.concatMap replaceGroup subs;
    in substituteWith (capture regex) replaceCaptures;
}
