let
  list = import ./list.nix;
  set = import ./set.nix;
  string = import ./string.nix;
  types = import ./types.nix;

  unique = xs:
    let
      xs' = builtins.sort builtins.lessThan xs;
    in builtins.length xs <= 1 || list.all (x: x) (list.zipWith (x: y: x != y) xs' (list.tail xs'));
in
rec {
  fields = rec {
    /* positional :: [{ name: string, type: type }] -> ConstructorSpecification

       Specifies that the variant should contain the provided field names, but
       the constructor and match function both expect appropriate positional
       arguments. The field names are only used in the internal representation.

       > point = adt.struct "point" (adt.fields.positional [{ name = "x"; type = types.int; } { name = "y"; type = types.int; }])
       > p = point.ctors.make 1 2
       > p
       { _type = "point"; x = 1; y = 2; }
       > point.match p (x: y: x + y)
       3
    */
    positional = fields:
      assert builtins.isList fields
      && builtins.all
        (f:
          builtins.isAttrs f
          && f ? name && builtins.isString f.name
          && f ? type
        )
        fields;
      fields;

    /* positional_ :: [string] -> ConstructorSpecification

       Like `fields.positional`, but the fields are untyped.
    */
    positional_ = fields:
      assert builtins.isList fields && builtins.all builtins.isString fields;
      assert unique fields;
      positional (list.map (f: { name = f; type = types.any; }) fields);

    /* record :: { string: type } -> ConstructorSpecification

       Specifies that the variant should contain the provided field names, but
       the constructor and match function both expect a single attrset argument
       with the appropriate fields.

       > point = adt.struct "point" (adt.fields.record { x = types.int; y = types.int; })
       > p = point.ctors.make { x = 1; y = 2; }
       > p
       { _type = "point"; x = 1; y = 2; }
       > point.match p ({ x, y }: x + y)
       3
    */
    record = fields:
      assert builtins.isAttrs fields;
      fields;

    /* record_ :: [string] -> ConstructorSpecification

       Like `fields.record`, but the fields are untyped.
    */
    record_ = fields:
      assert builtins.isList fields && builtins.all builtins.isString fields;
      assert unique fields;
      list.fold set.monoid (list.map (x: { ${x} = types.any; }) fields);

    /* none :: ConstructorSpecification

       Specifies that the variant should contain no fields. The constructor will
       not be a function, but a singleton attrset. The corresponding match
       branch will expect a value, not a function, when matching.

       > optional = adt.enum "optional" { just = adt.fields.positional_ ["value"]; nothing = adt.fields.none; }
       > optional.ctors.just 5
       { _tag = "just"; _type = "optional"; value = 5; }
       > optional.ctors.nothing
       { _tag = "nothing"; _type = "optional"; }
       > optional.match optional.ctors.nothing { just = x: x + 2; nothing = 7; }
       7
    */
    none = null;

    /* anon :: [type] -> ConstructorSpecification

       Like `fields.positional`, but instead of providing the names for the
       fields, the given number of anonymous field names are used instead.

       > point = adt.struct "point" (adt.fields.anon [types.int types.int])
       > p = point.ctors.make 1 2
       > p
       { _type = "point"; _0 = 1; _1 = 2; }
       > point.match p (x: y: x + y)
       3
    */
    anon = types:
      assert builtins.isList types;
      positional (list.imap (i: t: { name = "_${builtins.toString i}"; type = t; }) types);

    /* anon_ :: int -> ConstructorSpecification

       Like `fields.anon`, but the fields are untyped.
    */
    anon_ = x:
      assert builtins.isInt x && x > 0;
      positional_ (list.map (n: "_${builtins.toString n}") (list.range 0 (x - 1)));
  };

  /* struct :: string -> ConstructorSpecification -> ADT

     Create a new algebraic data type with one one constructor, named 'make'.
  */
  struct = name: constructor: new name { make = constructor; };

  /* enum :: string -> { string: ConstructorSpecification } -> ADT

     Create a new algebraic data type consisting of a sum type with the
     constructors provided. This is simply an alias for 'new' to communicate
     intention when a sum type is being created.
  */
  enum = new;

  /* new :: string -> { string: ConstructorSpecification } -> ADT

     Create a new algebraic data type based on a specification of its
     constructors.

     Examples:

     > adt.new "optional" {
         just = adt.fields.positional_ [ "value" ];
         nothing = adt.fields.none;
       }

     > adt.new "result" {
         ok = adt.fields.anon_ 1;
         err = adt.fields.anon_ 1;
       }

     > adt.new "pair" {
         make = adt.fields.anon_ 2;
       }

     > adt.new "point" {
         make = adt.fields.record_ [ "x" "y" ];
       }
  */
  new = name: constructors:
    assert builtins.isString name;
    assert builtins.isAttrs constructors;
    assert builtins.all
      (spec:
        builtins.any (x: x) [
          (spec == null)
          (
            builtins.isList spec
            &&
            builtins.all
              (f:
                builtins.isAttrs f
                && f ? name && builtins.isString f.name
                && f ? type
              )
              spec
          )
          (builtins.isAttrs spec)
        ]
      )
      (builtins.attrValues constructors);
    assert builtins.all (name: !builtins.elem name [ "_tag" "_type" ]) (builtins.attrNames constructors);
    let
      only = as: as.${builtins.head (builtins.attrNames as)};
      needsTag = builtins.length (builtins.attrNames constructors) > 1;
      genNaryCtor = base: args:
        let
          len = builtins.length args;
          go = acc: i:
            if i >= len
            then acc
            else
              let
                field = builtins.elemAt args i;
              in x: go (acc // { ${field.name} = x; }) (i + 1);
        in go base 0;
      applyList = f: xs: list.foldl' (f': x: f' x) f xs;
      makeCtor = ctorName: spec:
        let
          baseAttrs = if needsTag then { _tag = ctorName; _type = name; } else { _type = name; };
        in
          if spec == null then
            # nullary
            baseAttrs
          else if builtins.isList spec then
            # positional, struct field named by string
            genNaryCtor baseAttrs spec
          else if builtins.isAttrs spec then
            # one attrset argument, fields named by strings both ways
            # TODO: could just intersectAttrs here, but wouldn't get checking that
            # all keys are present
            args: list.foldl' (x: y: x // { ${y} = args.${y}; }) baseAttrs (builtins.attrNames spec)
          else
            builtins.throw "std.adt.new: invalid constructor specification for constructor ${string.escapeNixString ctorName}";
      ctors = set.map makeCtor constructors;
      match =
        let
          makeApply = _: spec:
            if spec == null then
              # nullary
              (f: _: f)
            else if builtins.isList spec then
              (f: v: applyList f (list.map (k: v.${k.name}) spec))
            else # attrs
              (f: v: f (set.map (k: _: v.${k}) spec))
            ;
          apply = set.map makeApply constructors;
        in
          if builtins.length (builtins.attrNames constructors) == 0 then
            builtins.throw "std.adt: match on empty ADT: ${string.escapeNixString name}"
          else if !needsTag then
            val: matches:
              let
                matcher =
                  if builtins.isAttrs matches then
                    only matches val
                  else if builtins.isFunction matches then
                    matches
                  else
                    builtins.throw "std.adt: invalid matcher for ${string.escapeNixString name}";
              in if only constructors == null
                then matches
                else (only apply) matcher val
          else
            val: matches:
              if builtins.isAttrs matches then
                apply.${val._tag} matches.${val._tag} val
              else
                builtins.throw "std.adt: expected attrset for matcher on ${string.escapeNixString name}";
      check =
        let
          makeCtorCheck = ctorName: spec:
            if spec == null then
              _: true
            else if builtins.isList spec then
              t: builtins.all ({ name, type }: builtins.hasAttr name t && type.check t.${name}) spec
            else if builtins.isAttrs spec then
              t: builtins.all (name: builtins.hasAttr name t && spec.${name}.check t.${name}) (builtins.attrNames spec)
            else
              builtins.throw "std.adt.new: invalid constructor specification for constructor ${string.escapeNixString ctorName}"
            ;
          ctorChecks = set.map makeCtorCheck constructors;
        in t:
          (t ? _type && t._type == name)
          &&
          (
            if needsTag then
              t ? _tag
              && builtins.elem t._tag (builtins.attrNames constructors)
              && ctorChecks.${t._tag} t
            else
              (only ctorChecks) t
          );
    in { inherit match check ctors; };
}
