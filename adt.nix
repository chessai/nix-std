let
  list = import ./list.nix;
  set = import ./set.nix;

  applyList = f: xs: list.foldl' (f': x: f' x) f xs;
in
{
  /*
     create a new algebraic data type based on a specification.

     examples:

     > adt.new "optional" { just = [ "value" ]; nothing = null; }
     > adt.new "result" { ok = 1; err = 1; }
     > adt.new "pair" { make = 2; }
     > adt.new "point" { make = { x = null; y = null; }; }
  */
  new = name: constructors:
    assert builtins.isAttrs constructors;
    assert builtins.all
      (spec:
        builtins.any (x: x) [
          (spec == null)
          (builtins.isList spec && builtins.all builtins.isString spec)
          (builtins.isAttrs spec && builtins.all (x: x == null) (builtins.attrValues spec))
          (builtins.isInt spec && spec > 0)
        ]
      )
      (builtins.attrValues constructors);
    assert builtins.all (name: name != "_tag") (builtins.attrNames constructors);
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
      makeCtor = ctorName: spec:
        let
          baseAttrs = if needsTag then { _tag = ctorName; } else {};
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
          else if builtins.isInt spec then
            genNaryCtor baseAttrs (list.map (n: "_${builtins.toString n}") (list.range 0 (spec - 1)))
          else builtins.throw "std.adt.new: invalid constructor specification for '${ctorName}'";
      ctors = set.map makeCtor constructors;
      match =
        let
          makeApply = _: spec:
            if spec == null then
              # nullary
              (f: _: f)
            else if builtins.isList spec then
              (f: v: f (list.foldl' (x: y: x // y) {} (list.map (k: { ${k} = v.${k}; }) spec)))
            else if builtins.isAttrs spec then
              (f: v: f (set.map (k: _: v.${k})))
            else # int
              (f: v: applyList f (list.map (k: v."_${builtins.toString k}") (list.range 0 (spec - 1))))
            ;
          apply = set.map makeApply constructors;
          only = as: as.${builtins.head (builtins.attrNames as)};
        in
          if builtins.length (builtins.attrNames constructors) == 0 then
            builtins.throw "std.adt: match on empty ADT: ${name}"
          else if !needsTag then
            val: matches: (only apply) (only matches) val # TODO: should this be an attrset of matches?
          else
            val: matches: apply.${val._tag} matches.${val._tag} val;
    in { inherit match ctors; };
}
