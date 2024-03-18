let
  string = import ./string.nix;
  list = import ./list.nix;
  set = import ./set.nix;
in rec {
  /* toJSON :: Set -> JSON
  */
  toJSON = builtins.toJSON;

  /* @partial
     fromJSON :: JSON -> Set
  */
  fromJSON = builtins.fromJSON;

  /* toTOML :: Set -> TOML
  */
  toTOML = data:
    let
      # Escape a TOML key; if it is a string that's a valid identifier, we don't
      # need to add quotes
      tomlEscapeKey = val:
        # Identifier regex taken from https://toml.io/en/v1.0.0-rc.1#keyvalue-pair
        if builtins.isString val && builtins.match "[A-Za-z0-9_-]+" val != null
          then val
          else toJSON val;

      # Escape a TOML value
      tomlEscapeValue = toJSON;

      # Render a TOML value that appears on the right hand side of an equals
      tomlValue = v:
        if builtins.isList v
          then "[${string.concatMapSep ", " tomlValue v}]"
        else if builtins.isAttrs v
          then "{${string.concatMapSep ", " (kv: tomlKV kv._0 kv._1) (set.toList v)}}"
        else tomlEscapeValue v;

      # Render an inline TOML "key = value" pair
      tomlKV = k: v: 
        if v == null
          then "" 
          else "${tomlEscapeKey k} = ${tomlValue v}";

      # Turn a prefix like [ "foo" "bar" ] into an escaped header value like
      # "foo.bar"
      dots = string.concatMapSep "." tomlEscapeKey;

      # Render a TOML table with a header
      tomlTable = oldPrefix: k: v:
        let
          prefix = oldPrefix ++ [k];
          rest = go prefix v;
        in "[${dots prefix}]" + string.optional (rest != "") "\n${rest}";

      # Render a TOML array of attrsets using [[]] notation. 'subtables' should
      # be a list of attrsets.
      tomlTableArray = oldPrefix: k: subtables:
        let prefix = oldPrefix ++ [k];
        in string.concatMapSep "\n\n" (v:
          let rest = go prefix v;
          in "[[${dots prefix}]]" + string.optional (rest != "") "\n${rest}") subtables;

      # Wrap a string in a list, yielding the empty list if the string is empty
      optionalNonempty = str: list.optional (str != "") str;

      # Render an attrset into TOML; when nested, 'prefix' will be a list of the
      # keys we're currently in
      go = prefix: attrs:
        let
          attrList = set.toList attrs;

          # Render values that are objects using tables
          tableSplit = list.partition ({ _1, ... }: builtins.isAttrs _1) attrList;
          tablesToml = string.concatMapSep "\n\n"
            (kv: tomlTable prefix kv._0 kv._1)
            tableSplit._0;

          # Use [[]] syntax only on arrays of attrsets
          tableArraySplit = list.partition
            ({ _1, ... }: builtins.isList _1 && _1 != [] && list.all builtins.isAttrs _1)
            tableSplit._1;
          tableArraysToml = string.concatMapSep "\n\n"
            (kv: tomlTableArray prefix kv._0 kv._1)
            tableArraySplit._0;

          # Everything else becomes bare "key = value" pairs
          pairsToml = string.concatMapSep "\n" (kv: tomlKV kv._0 kv._1) tableArraySplit._1;
        in string.concatSep "\n\n" (list.concatMap optionalNonempty [
          pairsToml
          tablesToml
          tableArraysToml
        ]);
    in if builtins.isAttrs data
      then go [] data
      else builtins.throw "std.serde.toTOML: input data is not an attribute set, cannot be converted to TOML";

  /* @partial
     fromTOML :: TOML -> Set
  */
  fromTOML = builtins.fromTOML;
}
