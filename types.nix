with rec {
  function = import ./function.nix;
  inherit (function) const flip;

  tuple = import ./tuple.nix;
  inherit (tuple) tuple2;
};

let
  imports = {
    bool = import ./bool.nix;
    list = import ./list.nix;
    nonempty = import ./nonempty.nix;
    num = import ./num.nix;
    set = import ./set.nix;
    string = import ./string.nix;
    types = import ./types.nix;
  };
  _null = null;

  /* unsafe show functions */
  showFunction = const "<<lambda>>";
  showList = show: ls:
    let body = imports.string.intercalate ", " (imports.list.map show ls);
        tokens = [ "[" ] ++ imports.list.optional (! imports.list.empty ls) body ++ [ "]" ];
    in imports.string.intercalate " " tokens;
  showSet = show: s:
    let showKey = k:
          let v = s.${k};
          in "${k} = ${show v};";
        body = imports.list.map showKey (imports.set.keys s);
    in imports.string.intercalate " " ([ "{" ] ++ body ++ [ "}" ]);
  showNonEmpty = show: x:
    "nonempty " + showList show (imports.nonempty.toList x);
  typeShows = imports.set.map (_: imports.nonempty.singleton) {
    inherit (imports.types) bool float int null list path;
    lambda = { check = builtins.isFunction; show = showFunction; };
    set = imports.types.attrs;
  } // {
    string = imports.nonempty.make imports.types.string [
      imports.types.path
    ];
  };
  /* showInternal' :: type -> a -> string */
  showInternal' = type: x: (imports.nonempty.foldl'
    (c: n: if n.check x then n else c)
    type).show x;
  showInternal = x:
    let
        typeName = builtins.typeOf x;
        unknown = imports.nonempty.singleton { show = const "«${typeName}»"; };
    in showInternal' typeShows.${typeName} or unknown x;

  addCheck = type: check: type // {
    check = x: type.check x && check x;
  };

  between = lo: hi:
    addCheck imports.types.int (x: x >= lo && x <= hi) // {
      name = "intBetween";
      description = "an integer in [${builtins.toString lo}, ${builtins.toString hi}]";
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
    show = x:
      if x == true
      then "true"
      else "false";
  };

  int = mkType {
    name = "int";
    description = "machine integer";
    check = builtins.isInt;
    show = builtins.toString;
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
    show = builtins.toString;
  };

  string = mkType {
    name = "string";
    description = "string";
    check = builtins.isString;
    show = s: "\"" + s + "\"";
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
    show = showSet show;
  };

  attrsOf = type:
    let check = x: imports.list.all type.check (imports.set.values x);
    in addCheck attrs check // {
      name = "${attrs.name} ${type.name}";
      description = "${attrs.description} of ${type.description}s";
      show = showSet type.show;
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
    show = builtins.toString;
  };

  list = mkType {
    name = "list";
    description = "list";
    check = builtins.isList;
    show = showList show;
  };

  listOf = type:
    let check = x: imports.list.all type.check x;
    in addCheck list check // {
      name = "[${type.name}]";
      description = "list of ${type.description}s";
      show = showList type.show;
    };

  nonEmptyList =
    let base = addCheck list (x: ! imports.list.empty x);
    in base // {
      name = "nonempty ${base.name}";
      description = "non-empty ${base.description}";
    };

  nonEmptyListOf = type:
    let base = addCheck (listOf type) (x: x != []);
    in base // {
      name = "nonempty ${base.name}";
      description = "non-empty " + base.description;
    };

  nonEmpty = mkType {
    name = "nonempty";
    description = "non-empty";
    check = x: list.check x.tail or null && imports.set.keys x == [ "head" "tail" ];
    show = showNonEmpty show;
  };

  nonEmptyOf = type: let
    tail = listOf type;
    check = x: type.check x.head && tail.check x.tail;
    base = addCheck nonEmpty check;
  in base // {
    name = "${base.name} ${type.name}";
    description = "${base.description} of ${type.description}s";
    show = showNonEmpty type.show;
  };

  null = mkType {
    name = "null";
    description = "null";
    check = x: x == _null;
    show = const "null";
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
    show = x: imports.bool.ifThenElse (a.check x) a.show b.show x;
  };

  oneOf = types:
    let ht = imports.list.match types {
          nil = throw "types.oneOf needs at least one type in its argument";
          cons = x: xs: tuple2 x xs;
        };
    in imports.list.foldl' either ht._0 ht._1;
}
