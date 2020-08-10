let
  list = import ./list.nix;
in rec {
  semigroup = {
    append = x: y: x + y;
  };

  monoid = semigroup // {
    empty = "";
  };

  /* Take a substring of a string at an offset with a given length
     substring :: int -> int -> string -> string
  */
  substring = builtins.substring;

  /* length :: string -> int
  */
  length = builtins.stringLength;

  /* Replace all occurrences of each string in the first list with the
     corresponding string in the second list

     replace :: [string] -> [string] -> string -> string
  */
  replace = builtins.replaceStrings;

  /* concat :: [string] -> string
  */
  concat = concatSep "";

  /* concatSep :: string -> [string] -> string
  */
  concatSep = builtins.concatStringsSep;

  /* concatMap :: (a -> string) -> [a] -> string
  */
  concatMap = f: strs: concat (list.map f strs);

  /* concatMapSep :: string -> (a -> string) -> [a] -> string
  */
  concatMapSep = sep: f: strs: concatSep sep (list.map f strs);

  /* concatImap :: (int -> a -> string) -> [a] -> string
  */
  concatImap = f: strs: concat (list.imap f strs);

  /* concatImapSep :: string -> (int -> a -> string) -> [a] -> string
  */
  concatImapSep = sep: f: strs: concatSep sep (list.imap f strs);

  /* toChars :: string -> [string]
  */
  toChars = str: list.generate (i: substring i 1 str) (length str);

  /* Map over a string, applying a function to each character
     map :: (string -> string) -> string -> string
  */
  map = f: str: concatMap f (toChars str);

  /* Backslash-escape the chars in the given list
     escape :: [string] -> string -> string
  */
  escape = chars: replace chars (list.map (c: "\\${c}") chars);

  /* Escape an argument to be suitable to pass to the shell
     escapeShellArgs :: string -> string
  */
  escapeShellArg = arg: "'${replace ["'"] ["'\\''"] (toString arg)}'";

  /* Turn a string into a Nix expression representing that string
  */
  escapeNixString = str: escape ["$"] (builtins.toJSON str);

  /* hasPrefix :: string -> string -> bool
  */
  hasPrefix = pre: str:
    let
      strLen = length str;
      preLen = length pre;
    in preLen <= strLen && substring 0 preLen str == pre;

  /* hasSuffix :: string -> string -> bool
  */
  hasSuffix = suf: str:
    let
      strLen = length str;
      sufLen = length suf;
    in sufLen <= strLen && substring (length str - sufLen) sufLen str == suf;

  /* hasInfix :: string -> string -> bool
  */
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
  */
  removePrefix = pre: str:
    let
      preLen = length pre;
      strLen = length str;
    in if hasPrefix pre str
      then substring preLen (strLen - preLen) str
      else str;

  /* removeSuffix :: string -> string -> string
  */
  removeSuffix = suf: str:
    if hasSuffix suf str
      then substring 0 (length str - length suf) str
      else str;

  /* optional :: bool -> string -> string
  */
  optional = b: str: if b then str else "";

  /* lowerChars :: [string]
  */
  lowerChars = toChars "abcdefghijklmnopqrstuvwxyz";

  /* upperChars :: [string]
  */
  upperChars = toChars "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  /* toLower :: string -> string
  */
  toLower = replace upperChars lowerChars;

  /* toUpper :: string -> string
  */
  toUpper = replace lowerChars upperChars;
}
