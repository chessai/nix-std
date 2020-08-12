with rec {
  string = import ./string.nix;
  list = import ./list.nix;
};

rec {
  /* match :: regex -> string -> Maybe [string]

     Test if a string matches a regular expression exactly. The output is null
     if the string does not match the regex, or a list of capture groups if it
     does.

     Fails if the provided regex is invalid.

     > regex.match "([[:alpha:]]+)([[:digit:]]+)" "foo123"
     [ "foo" "123" ]
     > regex.match "([[:alpha:]]+)([[:digit:]]+)" "foobar"
     null

     To check whether or not a string matches a regex, simply check if the
     result of 'match' is non-null:

     > regex.match "[[:digit:]]+" "123" != null
     true

     Note that using '+' or '*' on a capture group will only retain the last
     occurrence. If you use '*' on a capture group with zero occurrences, that
     capture group will have a null result:

     > regex.match "([[:digit:]])*" "123"
     [ "3" ]
     > regex.match "([[:digit:]])*" ""
     [ null ]
  */
  match = builtins.match;

  /* allMatches :: regex -> string -> [string]

     Find all occurrances of a regex in a string.

     Fails if the provided regex is invalid.

     > regex.allMatches "[[:digit:]]+" "foo 123 bar 456"
     [ "123" "456" ]
  */
  allMatches = regex: str:
    list.concatMap (g: if builtins.isList g then [(list.head g)] else []) (split "(${regex})" str);

  /* firstMatch :: regex -> string -> Maybe string

     Returns the first occurrence of the pattern in the string, or null if it
     does not occur.

     > regex.firstMatch "[aeiou]" "foobar"
     "o"
     > regex.firstMatch "[aeiou]" "xyzzyx"
     null
  */
  firstMatch = regex: str:
    let res = split "(${regex})" str;
    in if list.length res > 1
      then list.head (list.index res 1)
      else null;

  /* lastMatch :: regex -> string -> Maybe string

     Returns the last occurrence of the pattern in the string, or null if it
     does not occur.

     > regex.lastMatch "[aeiou]" "foobar"
     "a"
     > regex.lastMatch "[aeiou]" "xyzzyx"
     null
  */
  lastMatch = regex: str:
    let
      res = split "(${regex})" str;
      len = list.length res;
    in if len > 1
      then list.head (list.index res (len - 2))
      else null;

  /* split :: regex -> string -> [string | [Maybe string]]

     Split a string using a regex. The result contains interspersed delimiters
     as lists of capture groups from the regex; see 'match' for details on
     capture groups.

     Fails if the provided regex is invalid.

     > regex.split "," "1,2,3"
     [ "1" [ ] "2" [ ] "3" [ ] ]
     > regex.split "(,)" "1,2,3"
     [ "1" [ "," ] "2" [ "," ] "3" [ "," ] ]
  */
  split = builtins.split;

  /* splitOn :: regex -> string -> [string]

     Like 'split', but drops the delimiters.

     Fails if the provided regex is invalid.

     > regex.splitOn "," "1,2,3"
     [ "1" "2" "3" ]
  */
  splitOn = regex: str:
    list.concatMap (g: list.optional (!builtins.isList g) g) (split regex str);

  /* substituteWith :: regex -> ([Maybe string] -> string) -> string -> string

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
    in substituteWith "(${regex})" replaceCaptures;
}
