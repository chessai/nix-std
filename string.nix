with rec {
  function = import ./function.nix;
  inherit (function) flip not;

  list = import ./list.nix;
  regex = import ./regex.nix;
  num = import ./num.nix;
  _optional = import ./optional.nix;
};

rec {
  semigroup = {
    append = x: y: x + y;
  };

  monoid = semigroup // {
    inherit empty;
  };

  /* empty :: string

     The empty string.
  */
  empty = "";

  /* @partial
     substring :: int -> int -> string -> string

     Take a substring of a string at an offset with a given length. If the
     offset is past the end of the string, the result will be the empty string.
     If there are less than the requested number of characters until the end of
     the string, returns as many as possible. Otherwise, if the length is
     negative, simply returns the rest of the string after the starting
     position.

     Fails if the starting position is negative.

     > string.substring 2 3 "foobar"
     "oba"
     > string.substring 4 7 "foobar"
     "ar"
     > string.substring 10 5 "foobar"
     ""
     > string.substring 2 (-1) "foobar"
     "obar"
  */
  substring = builtins.substring;

  /* @partial
     unsafeIndex :: string -> int -> string

     Returns the nth character of a string. Fails if the index is out of bounds.

     > string.unsafeIndex 3 "foobar"
     "b"
  */
  unsafeIndex = str: n:
    if n < 0 || n >= length str
      then throw "std.string.unsafeIndex: index out of bounds"
      else substring n 1 str;

  /* index :: string -> int -> optional string

     Returns the nth character of a string. Returns `optional.nothing` if the
     string is empty.

     > string.index 3 "foobar"
     { _tag = "just"; value = "b"; }
     > string.index (-1) "foobar"
     { _tag = "nothing"; }
  */
  index = str: n:
    if n < 0 || n >= length str
      then _optional.nothing
      else _optional.just (substring n 1 str);

  /* length :: string -> int

     Compute the length of a string.

     > string.length "foo"
     3
     > string.length ""
     0
  */
  length = builtins.stringLength;

  /* isEmpty :: string -> bool

     Check if a string is the empty string.

     > string.isEmpty "foo"
     false
     > string.isEmpty ""
     true
  */
  isEmpty = str: str == "";

  /* replace :: [string] -> [string] -> string -> string

     Replace all occurrences of each string in the first list with the
     corresponding string in the second list.

     > string.replace [ "o" "a" ] [ "u" "e" ] "foobar"
     "fuuber"
  */
  replace = builtins.replaceStrings;

  /* concat :: [string] -> string

     Concatenate a list of strings.

     > string.concat [ "foo" "bar" ]
     "foobar"
  */
  concat = concatSep "";

  /* concatSep :: string -> [string] -> string

     Concatenate a list of strings, with a separator in between.

     > string.concatSep ", " [ "1" "2" "3" ]
     "1, 2, 3"
  */
  concatSep = builtins.concatStringsSep;

  /* concatMap :: (a -> string) -> [a] -> string

     Apply a function to each element in a list and concatenate the resulting
     list of strings.

     > string.concatMap builtins.toJSON [ 1 2 3 ]
     "123"
  */
  concatMap = f: strs: concat (list.map f strs);

  /* concatMapSep :: string -> (a -> string) -> [a] -> string

     Apply a function to each element in a list and concatenate the resulting
     list of strings, with a separator in between.

     > string.concatMapSep ", " builtins.toJSON [ 1 2 3 ]
     "1, 2, 3"
  */
  concatMapSep = sep: f: strs: concatSep sep (list.map f strs);

  /* concatImap :: (int -> a -> string) -> [a] -> string

     Apply a function to each index and element in a list and concatenate the
     resulting list of strings.

     > string.concatImap (i: x: x + builtins.toJSON i) [ "foo" "bar" "baz" ]
     "foo0bar1baz2"
  */
  concatImap = f: strs: concat (list.imap f strs);

  /* concatImapSep :: string -> (int -> a -> string) -> [a] -> string

     Apply a function to each index and element in a list and concatenate the
     resulting list of strings, with a separator in between.

     > string.concatImapSep "\n" (i: x: builtins.toJSON (i + 1) + ": " + x) [ "foo" "bar" "baz" ]
     "1: foo\n2: bar\n3: baz"
  */
  concatImapSep = sep: f: strs: concatSep sep (list.imap f strs);

  /* toChars :: string -> [string]

     Convert a string to a list of the characters in the string.

     > string.toChars "foo"
     [ "f" "o" "o" ]
  */
  toChars = str: list.generate (unsafeIndex str) (length str);

  /* map :: (string -> string) -> string -> string

     Map over a string, applying a function to each character.
  */
  map = f: str: concatMap f (toChars str);

  /* imap :: (int -> string -> string) -> string -> string

     Map over a string, applying a function to each character and its index.
  */
  imap = f: str: concatImap f (toChars str);

  /* filter :: (string -> bool) -> string -> string

     Filter the characters in a string, keeping only those which match the
     given predicate.
  */
  filter = pred: str: concat (list.filter pred (toChars str));

  /* findIndex :: (string -> bool) -> string -> Optional int

     Find the index of the first character in a string matching the predicate,
     or return null if no such character is present.
  */
  findIndex = pred: str:
    let
      len = length str;
      go = i:
        if i >= len
        then _optional.nothing
        else if pred (unsafeIndex str i)
             then _optional.just i
             else go (i + 1);
    in go 0;

  /* findLastIndex :: (string -> bool) -> string -> Optional int

     Find the index of the last character in a string matching the predicate, or
     return null if no such character is present.
  */
  findLastIndex = pred: str:
    let
      len = length str;
      go = i:
        if i < 0
        then _optional.nothing
        else if pred (unsafeIndex str i)
             then _optional.just i
             else go (i - 1);
    in go (len - 1);

  /* find :: (string -> bool) -> string -> Optional string

     Find the first character in a string matching the predicate, or return null
     if no such character is present.
  */
  find = pred: str:
    let i = findIndex pred str;
    in if i._tag == "nothing"
       then _optional.nothing
       else _optional.just (unsafeIndex str i.value);

  /* findLast :: (string -> bool) -> string -> Optional string

     Find the last character in a string matching the predicate, or return null
     if no such character is present.
  */
  findLast = pred: str:
    let i = findLastIndex pred str;
    in if i._tag == "nothing"
       then _optional.nothing
       else _optional.just (unsafeIndex str i.value);

  /* escape :: [string] -> string -> string

     Backslash-escape the chars in the given list.

     > string.escape [ "$" ] "foo$bar"
     "foo\\$bar"
  */
  escape = chars: replace chars (list.map (c: "\\${c}") chars);

  /* escapeShellArgs :: string -> string

     Escape an argument to be suitable to pass to the shell
  */
  escapeShellArg = arg: "'${replace ["'"] ["'\\''"] (toString arg)}'";

  /* escapeNixString :: string -> string

     Turn a string into a Nix expression representing that string
  */
  escapeNixString = str: escape ["$"] (builtins.toJSON str);

  /* hasPrefix :: string -> string -> bool

     Test if a string starts with a given string.
  */
  hasPrefix = pre: str:
    let
      strLen = length str;
      preLen = length pre;
    in preLen <= strLen && substring 0 preLen str == pre;

  /* hasSuffix :: string -> string -> bool

     Test if a string ends with a given string.
  */
  hasSuffix = suf: str:
    let
      strLen = length str;
      sufLen = length suf;
    in sufLen <= strLen && substring (length str - sufLen) sufLen str == suf;

  /* hasInfix :: string -> string -> bool

     Test if a string contains a given string.
  */
  # TODO: should this just be 'regex.firstMatch (regex.escape infix) str != null'?
  hasInfix = infix: str:
    let
      infixLen = length infix;
      strLen = length str;
      go = i:
        if i > strLen - infixLen
          then false
        else substring i infixLen str == infix || go (i + 1);
    in infixLen <= strLen && go 0;

  /* removePrefix :: string -> string -> string

     If the string starts with the given prefix, return the string with the
     prefix stripped. Otherwise, returns the original string.

     > removePrefix "/" "/foo"
     "foo"
     > removePrefix "/" "foo"
     "foo"
  */
  removePrefix = pre: str:
    let
      preLen = length pre;
      strLen = length str;
    in if hasPrefix pre str
      then substring preLen (strLen - preLen) str
      else str;

  /* removeSuffix :: string -> string -> string

     If the string ends with the given suffix, return the string with the suffix
     stripped. Otherwise, returns the original string.

     > removeSuffix ".nix" "foo.nix"
     "foo"
     > removeSuffix ".nix" "foo"
     "foo"
  */
  removeSuffix = suf: str:
    if hasSuffix suf str
      then substring 0 (length str - length suf) str
      else str;

  /* count :: string -> string -> int

     Count the number of times a string appears in a larger string (not counting
     overlapping).

     > string.count "oo" "foooobar"
     2
  */
  count = needle: str: list.length (regex.allMatches (regex.escape needle) str);

  /* optional :: bool -> string -> string

     Return the string if the condition is true, otherwise return the empty
     string.
  */
  optional = b: str: if b then str else "";

  /* @partial
     unsafeHead :: string -> string

     Return the first character of the string.

     Fails if the string is empty.
  */
  unsafeHead = str:
    let len = length str;
    in if len > 0
      then unsafeIndex str 0
      else throw "std.string.unsafeHead: empty string";

  /* head :: string -> optional string

     Return the first character of the string.

     Returns `optional.nothing` if the string is empty.
  */
  head = str:
    let len = length str;
    in if len > 0
      then _optional.just (unsafeIndex str 0)
      else _optional.nothing;

  /* @partial
     unsafeTail :: string -> string

     Return the string minus the first character.

     Fails if the string is empty.
  */
  unsafeTail = str:
    let len = length str;
    in if len > 0
      then substring 1 (len - 1) str
      else throw "std.string.unsafeTail: empty string";

  /* tail :: string -> optional string

     Return the string minus the first character.

     Returns `optional.nothing` if the string is empty.
  */
  tail = str:
    let len = length str;
    in if len > 0
      then _optional.just (substring 1 (len - 1) str)
      else _optional.nothing;

  /* @partial
     unsafeInit :: string -> string

     Return the string minus the last character.

     Fails if the string is empty.
  */
  unsafeInit = str:
    let len = length str;
    in if len > 0
      then substring 0 (len - 1) str
      else throw "std.string.unsafeInit: empty string";

  /* init :: string -> optional string

     Return the string minus the last character.

     Returns `optional.nothing` if the string is empty.
  */
  init = str:
    let len = length str;
    in if len > 0
      then _optional.just (substring 0 (len - 1) str)
      else _optional.nothing;

  /* @partial
     unsafeLast :: string -> string

     Return the last character of a string.

     Fails if the string is empty.
  */
  unsafeLast = str:
    let len = length str;
    in if len > 0
      then substring (len  - 1) 1 str
      else throw "std.string.unsafeLast: empty string";

  /* last :: string -> optional string

     Return the last character of a string.

     Returns `optional.nothing` if the string is empty.
  */
  last = str:
    let len = length str;
    in if len > 0
      then _optional.just (substring (len  - 1) 1 str)
      else _optional.nothing;

  /* take :: int -> string -> string

     Return the first n characters of a string. If less than n characters are
     present, take as many as possible.
  */
  take = n: substring 0 (num.max 0 n);

  /* drop :: int -> string -> string

     Remove the first n characters of a string. If less than n characters are
     present, return the empty string.
  */
  drop = n: substring (num.max 0 n) (-1);

  /* takeEnd :: int -> string -> string

     Return the last n characters of a string. If less than n characters are
     present, take as many as possible.
  */
  takeEnd = n: str:
    let
      len = length str;
      n' = num.min len n;
    in substring (len - n') n' str;

  /* takeEnd :: int -> string -> string

     Remove the last n characters of a string. If less than n characters are
     present, return the empty string.
  */
  dropEnd = n: str:
    substring 0 (num.max 0 (length str - n)) str;

  /* takeWhile :: (string -> bool) -> string -> string

     Return the longest prefix of the string that satisfies the predicate.
  */
  takeWhile = pred: str:
    let n = findIndex (not pred) str;
    in if n._tag == "nothing"
      then str
      else take n.value str;

  /* dropWhile :: (string -> bool) -> string -> string

     Return the rest of the string after the prefix returned by 'takeWhile'.
  */
  dropWhile = pred: str:
    let n = findIndex (not pred) str;
    in if n._tag == "nothing"
      then ""
      else drop n.value str;

  /* takeWhileEnd :: (string -> bool) -> string -> string

     Return the longest suffix of the string that satisfies the predicate.
  */
  takeWhileEnd = pred: str:
    let n = findLastIndex (not pred) str;
    in if n._tag == "nothing"
      then ""
      else drop (n.value + 1) str;

  /* dropWhileEnd :: (string -> bool) -> string -> string

     Return the rest of the string after the suffix returned by 'takeWhileEnd'.
  */
  dropWhileEnd = pred: str:
    let n = findLastIndex (not pred) str;
    in if n._tag == "nothing"
      then ""
      else take (n.value + 1) str;

  /* splitAt :: int -> string -> (string, string)

     Return a tuple of the parts of the string before and after the given index.
  */
  splitAt = n: str: { _0 = take n str; _1 = drop n str; };

  /* span :: (string -> bool) -> string -> (string, string)

     Find the longest prefix satisfying the given predicate, and return a tuple
     of this prefix and the rest of the string.
  */
  span = pred: str:
    let n = findIndex (not pred) str;
    in if n._tag == "nothing"
      then { _0 = str; _1 = ""; }
      else splitAt n.value str;

  /* break :: (string -> bool) -> string -> (string, string)

     Find the longest prefix that does not satisfy the given predicate, and
     return a tuple of this prefix and the rest of the string.
  */
  break = pred: str:
    let n = findIndex pred str;
    in if n._tag == "nothing"
      then { _0 = str; _1 = ""; }
      else splitAt n.value str;

  /* reverse :: string -> string

     Reverse a string.
  */
  reverse = str:
    let len = length str;
    in concat (list.generate (n: substring (len - n - 1) 1 str) len);

  /* replicate :: int -> string -> string

     Return a string consisting of n copies of the given string.
  */
  replicate = n: str: concat (list.replicate n str);

  /* lines :: string -> [string]

     Split a string on line breaks, returning the contents of each line. A line
     is ended by a "\n", though the last line may not have a newline.

     > string.lines "foo\nbar\n"
     [ "foo" "bar" ]
     > string.lines "foo\nbar"
     [ "foo" "bar" ]
     > string.lines "\n"
     [ "" ]
     > string.lines ""
     []
  */
  lines = str:
    let
      len = length str;
      str' =
        if len > 0 && substring (len - 1) 1 str == "\n"
          then substring 0 (len - 1) str
          else str;
    in if isEmpty str # "" is a special case; "\n"/"" don't have the same result
      then []
      else regex.splitOn "\n" str';

  /* unlines :: [string] -> string

     Join a list of strings into one string with each string on a separate line.

     > string.unlines [ "foo" "bar" ]
     "foo\nbar\n"
     > string.unlines []
     ""
  */
  unlines = concatMap (x: x + "\n");

  /* words :: string -> [string]

     Split a string on whitespace, returning a list of each whitespace-delimited
     word. Leading or trailing whitespace does not affect the result.

     > string.words "foo \t  bar   "
     [ "foo" "bar" ]
     > string.words " "
     []
  */
  words = str:
    let stripped = strip str;
    in if isEmpty stripped
      then []
      else regex.splitOn ''[[:space:]]+'' stripped;

  /* unwords :: [string] -> string

     Join a list of strings with spaces.

     > string.unwords [ "foo" "bar" ]
     "foo bar"
  */
  unwords = concatSep " ";

  /* intercalate :: string -> [string] -> string

     Alias for 'concatSep'.
  */
  intercalate = concatSep;

  /* lowerChars :: [string]

     A list of the lowercase characters of the English alphabet.
  */
  lowerChars = toChars "abcdefghijklmnopqrstuvwxyz";

  /* upperChars :: [string]

     A list of the uppercase characters of the English alphabet.
  */
  upperChars = toChars "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  /* toLower :: string -> string

     Convert an ASCII string to lowercase.
  */
  toLower = replace upperChars lowerChars;

  /* toUpper :: string -> string

     Convert an ASCII string to uppercase.
  */
  toUpper = replace lowerChars upperChars;

  /* strip :: string -> string

     Remove leading and trailing whitespace from a string.
  */
  strip = regex.substitute ''^[[:space:]]+|[[:space:]]+$'' "";

  /* stripStart :: string -> string

     Remove leading whitespace from a string.
  */
  stripStart = regex.substitute ''^[[:space:]]+'' "";

  /* stripEnd :: string -> string

     Remove trailing whitespace from a string.
  */
  stripEnd = regex.substitute ''[[:space:]]+$'' "";

  /* @partial
     justifyLeft :: int -> string -> string

     Justify a string to the left to a given length, adding copies of the
     padding string if necessary. Does not shorten the string if the target
     length is shorter than the original string. If the padding string is longer
     than a single character, it will be cycled to meet the required length.

     Fails if the string to fill with is empty.

     > string.justifyLeft 7 "x" "foo"
     "fooxxxx"
     > string.justifyLeft 2 "x" "foo"
     "foo"
     > string.justifyLeft 7 "xyz" "foo"
     "fooxyzx"
  */
  justifyLeft = n: fill: str:
    let
      strLen = length str;
      fillLen = length fill;
      padLen = num.max 0 (n - strLen);
      padCopies = (padLen + fillLen - 1) / fillLen; # padLen / fillLen, but rounding up
      padding = take padLen (replicate padCopies fill);
    in if fillLen > 0
      then str + padding
      else throw "std.string.justifyLeft: empty padding string";

  /* @partial
     justifyRight :: int -> string -> string

     Justify a string to the right to a given length, adding copies of the
     padding string if necessary. Does not shorten the string if the target
     length is shorter than the original string. If the padding string is longer
     than a single character, it will be cycled to meet the required length.

     Fails if the string to fill with is empty.

     > string.justifyRight 7 "x" "foo"
     "xxxxfoo"
     > string.justifyRight 2 "x" "foo"
     "foo"
     > string.justifyRight 7 "xyz" "foo"
     "xyzxfoo"
  */
  justifyRight = n: fill: str:
    let
      strLen = length str;
      fillLen = length fill;
      padLen = num.max 0 (n - strLen);
      padCopies = (padLen + fillLen - 1) / fillLen; # padLen / fillLen, but rounding up
      padding = take padLen (replicate padCopies fill);
    in if fillLen > 0
      then padding + str
      else throw "std.string.justifyRight: empty padding string";

  /* @partial
     justifyCenter :: int -> string -> string

     Center-justify a string to a given length, adding copies of the padding
     string on either side if necessary. Does not shorten the string if the
     target length is shorter than the original string. If the padding string is
     longer than a single character, it will be cycled to meet the required
     length. If the padding is unbalanced on both sides, additional padding will
     go on the right.

     Fails if the string to fill with is empty.

     > string.justifyCenter 7 "x" "foo"
     "xxfooxx"
     > string.justifyCenter 2 "x" "foo"
     "foo"
     > string.justifyCenter 8 "xyz" "foo"
     "xyfooxyz"
  */
  justifyCenter = n: fill: str:
    let
      strLen = length str;
      fillLen = length fill;
      leftLen = num.max 0 ((n - strLen + 1) / 2); # bias when left padding
      rightLen = num.max 0 ((n - strLen) / 2);
    in if fillLen > 0
      then justifyRight (strLen + leftLen + rightLen) fill (justifyLeft (strLen + leftLen) fill str)
      else throw "std.string.justifyCenter: empty padding string";
}
