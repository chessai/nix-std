with rec {
  function = import ./function.nix;
  inherit (function) const flip;
};

let
  imports = {
    list = import ./list.nix;
    num = import ./num.nix;
    set = import ./set.nix;
    string = import ./string.nix;
  };
  _null = null;

  /* unsafe show functions */
  showBool = x:
    if x == true
    then "true"
    else "false";
  showFloat = builtins.toString;
  showFunction = const "<<lambda>>";
  showInt = builtins.toString;
  showList = ls:
    let body = imports.string.intercalate ", " (imports.list.map showInternal ls);
        tokens = [ "[" ] ++ imports.list.optional (! imports.list.empty ls) body ++ [ "]" ];
    in imports.string.intercalate " " tokens;
  showNull = const "null";
  showPath = builtins.toString;
  showSet = s:
    let showKey = k:
          let v = s.${k};
          in "${k} = ${showInternal v};";
        body = imports.string.intercalate " " (imports.list.map showKey (imports.set.keys s));
    in "{ " + body + " }";
  showString = s: "\"" + s + "\"";
  showInternal = x:
    let /* shows :: [{ isType :: a -> bool, showType :: a -> string }]*/
        shows = [
          { isType = builtins.isBool; showType = showBool; }
          { isType = builtins.isFloat; showType = showFloat; }
          { isType = builtins.isFunction; showType = showFunction; }
          { isType = builtins.isInt; showType = showInt; }
          { isType = builtins.isList; showType = showList; }
          { isType = builtins.isNull; showType = showNull; }
          { isType = builtins.isPath; showType = showPath; }
          { isType = builtins.isString; showType = showString; }
          { isType = builtins.isAttrs; showType = showSet; }
        ];

        /* show' :: a -> string */
        show' = (imports.list.foldr
          (c: n: if n.isType x then n else c)
          ({ isType = const false; showType = builtins.toString; })
          shows).showType;
    in show' x;

  addCheck = type: check: type // {
    check = x: type.check x && check x;
  };

  between = lo: hi:
    let baseType = { check = builtins.isInt; };
    in addCheck baseType (x: x >= lo && x <= hi) // {
         name = "intBetween";
         description = "an integer in [${builtins.toString lo}, ${builtins.toString hi}]";
         show = showInt;
       };

  unsigned = bit: lo: hi:
    between lo hi // {
      name = "u${builtins.toString bit}";
      description = "an unsigned integer in [${builtins.toString lo}, ${builtins.toString hi}]";
    };

  signed = bit: lo: hi:
    between lo hi // {
      name = "i${builtins.toString bit}";
      description = "a signed integer in [${builtins.toString lo}, ${builtins.toString hi}]";
    };

in
rec {
  show = showInternal;

  /*
  type Type = {
    name :: string,
    check :: a -> bool,
    show :: a -> string,
  }
  */

  mkType = {
    name,
    check,
    description,
    show ? showInternal
  }: {
    inherit name check description show;
  };

  bool = mkType {
    name = "bool";
    description = "boolean";
    check = builtins.isBool;
  };

  int = mkType {
    name = "int";
    description = "machine integer";
    check = builtins.isInt;
  };

  i8 = signed 8 (-128) 127;
  i16 = signed 16 (-32768) 32767;
  i32 = signed 32 (-2147483648) 2147483647;
  #i64 = signed 64 (-9223372036854775808) 9223372036854775807;
  u8 = unsigned 8 0 255;
  u16 = unsigned 16 0 65535;
  u32 = unsigned 32 0 4294967295;
  #u64 = signed 64 0 18446744073709551615;

  /* Port numbers. Alias of u16 */
  port = u16;

  float = mkType {
    name = "f32";
    description = "32-bit floating point number";
    check = builtins.isFloat;
  };

  string = mkType {
    name = "string";
    description = "string";
    check = builtins.isString;
  };

  stringMatching = pattern: mkType {
    name = "stringMatching ${imports.string.escapeNixString pattern}";
    description = "string matching the pattern ${pattern}";
    check = x: string.check x && builtins.match pattern x != _null;
  };

  attrs = mkType {
    name = "attrs";
    description = "attribute set";
    check = builtins.isAttrs;
  };

  drv = mkType {
    name = "derivation";
    description = "derivation";
    check = x: builtins.isAttrs x && x.type or null == "derivation";
  };

  path = mkType {
    name = "path";
    description = "a path";
    check = x: builtins.isString x && builtins.substring 0 1 (builtins.toString x) == "/";
  };

  listOf = type: mkType {
    name = "[${type.name}]";
    description = "list of ${type.description}s";
    check = x: builtins.isList x && imports.list.all type.check x;
  };

  nonEmptyListOf = type:
    let base = addCheck (listOf type) (x: x != []);
    in base // {
         name = "nonempty ${base.name}";
         description = "non-empty " + base.description;
         show = showList;
       };

  null = mkType {
    name = "null";
    description = "null";
    check = x: x == _null;
  };

  nullOr = type: either null type;

  enum = values:
    let showType = v:
          if builtins.isString v
          then ''"${v}"''
          else if builtins.isInt v
               then builtins.toString v
               else ''<${builtins.typeOf v}>'';
    in mkType {
         name = "enum";
         description = "one of ${imports.string.concatMapSep ", " showType values}";
         check = flip imports.list.elem values;
       };

  either = a: b: mkType {
    name = "either";
    description = "${a.description} or ${b.description}";
    check = x: a.check x || b.check x;
  };

  oneOf = types:
    let ht = imports.list.match types {
          nil = throw "types.oneOf needs at least one type in its argument";
          cons = x: xs: { _0 = x; _1 = xs; };
        };
    in imports.list.foldl' either ht._0 ht._1;
}
