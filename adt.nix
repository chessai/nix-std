let
  list = import ./list.nix;
  set = import ./set.nix;
  string = import ./string.nix;

  unique = xs:
    let
      xs' = builtins.sort builtins.lessThan xs;
    in builtins.length xs <= 1 || list.all (x: x) (list.zipWith (x: y: x != y) xs' (list.tail xs'));
in
rec {
  fields = rec {
    /* positional :: [string] -> ConstructorSpecification

       Specifies that the variant should contain the provided field names, but
       the constructor and match function both expect appropriate positional
       arguments. The field names are only used in the internal representation.

       > point = adt.struct "point" (adt.fields.positional ["x" "y"])
       > p = point.ctors.make 1 2
       > p
       { _type = "point"; x = 1; y = 2; }
       > point.match p (x: y: x + y)
       3
    */
    positional = fields:
      assert builtins.isList fields && builtins.all builtins.isString fields;
      assert unique fields;
      fields;

    /* record :: [string] -> ConstructorSpecification

       Specifies that the variant should contain the provided field names, but
       the constructor and match function both expect a single attrset argument
       with the appropriate fields.

       > point = adt.struct "point" (adt.fields.record ["x" "y"])
       > p = point.ctors.make { x = 1; y = 2; }
       > p
       { _type = "point"; x = 1; y = 2; }
       > point.match p ({ x, y }: x + y)
       3
    */
    record = fields:
      assert builtins.isList fields && builtins.all builtins.isString fields;
      assert unique fields;
      list.fold set.monoid (list.map (x: { ${x} = null; }) fields);

    /* none :: ConstructorSpecification

       Specifies that the variant should contain no fields. The constructor will
       not be a function, but a singleton attrset. The corresponding match
       branch will expect a value, not a function, when matching.

       > optional = adt.enum "optional" { just = adt.fields.positional ["value"]; nothing = adt.fields.none; }
       > optional.ctors.just 5
       { _tag = "just"; _type = "optional"; value = 5; }
       > optional.ctors.nothing
       { _tag = "nothing"; _type = "optional"; }
       > optional.match optional.ctors.nothing { just = x: x + 2; nothing = 7; }
       7
    */
    none = null;

    /* anon :: int -> ConstructorSpecification

       Like `fields.positional`, but instead of providing the names for the
       fields, the given number of anonymous field names are used instead.

       > point = adt.struct "point" (adt.fields.anon 2)
       > p = point.ctors.make 1 2
       > p
       { _type = "point"; _0 = 1; _1 = 2; }
       > point.match p (x: y: x + y)
       3
    */
    anon = x:
      assert builtins.isInt x && x > 0;
      positional (list.map (n: "_${builtins.toString n}") (list.range 0 (x - 1)));
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
         just = adt.fields.positional [ "value" ];
         nothing = adt.fields.none;
       }

     > adt.new "result" {
         ok = adt.fields.anon 1;
         err = adt.fields.anon 1;
       }

     > adt.new "pair" {
         make = adt.fields.anon 2;
       }

     > adt.new "point" {
         make = adt.fields.record [ "x" "y" ];
       }
  */
  new = name: constructors:
    assert builtins.isString name;
    assert builtins.isAttrs constructors;
    assert builtins.all
      (spec:
        builtins.any (x: x) [
          (spec == null)
          (builtins.isList spec && builtins.all builtins.isString spec)
          (builtins.isAttrs spec && builtins.all (x: x == null) (builtins.attrValues spec))
        ]
      )
      (builtins.attrValues constructors);
    assert builtins.all (name: !builtins.elem name [ "_tag" "_type" ]) (builtins.attrNames constructors);
    let
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
              in x: go (acc // { ${field} = x; }) (i + 1);
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
          else builtins.throw "std.adt.new: invalid constructor specification for constructor ${string.escapeNixString ctorName}";
      ctors = set.map makeCtor constructors;
      match =
        let
          makeApply = _: spec:
            if spec == null then
              # nullary
              (f: _: f)
            else if builtins.isList spec then
              (f: v: applyList f (list.map (k: v.${k}) spec))
            else # attrs
              (f: v: f (set.map (k: _: v.${k}) spec))
            ;
          apply = set.map makeApply constructors;
          only = as: as.${builtins.head (builtins.attrNames as)};
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
                    builtins.throw "std.adt: expected function or attrset for matcher on ${string.escapeNixString name}";
              in (only apply) matcher val
          else
            val: matches:
              if builtins.isAttrs matches then
                apply.${val._tag} matches.${val._tag} val
              else
                builtins.throw "std.adt: expected attrset for matcher on ${string.escapeNixString name}";
    in { inherit match ctors; };
}
