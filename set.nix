with rec {
  bool = import ./bool.nix;
  function = import ./function.nix;
  inherit (function) id flip compose;
  list = import ./list.nix;

  imports = {
    optional = import ./optional.nix;
  };
};

rec {
  semigroup = {
    append = x: y: x // y;
  };

  monoid = semigroup // {
    inherit empty;
  };

  /* empty :: set
  */
  empty = {};

  /* assign :: key -> value -> set -> set
  */
  assign = k: v: r: r // { "${k}" = v; };

  /* getAll :: key -> [set] -> [value]

     > set.getAll "foo" [ { foo = "bar"; } { foo = "foo"; } ]
     [ "bar" "foo" ]
  */
  getAll = builtins.catAttrs;

  /* get :: key -> set -> optional value

     > set.get "foo" { foo = "bar"; }
     { _tag = "just"; value = "bar"; }
     > set.get "foo" { }
     { _tag = "nothing"; }
  */
  get = k: s: bool.toOptional (s ? "${k}") (unsafeGet k s);

  /* getOr :: default -> key -> set -> value

     > set.getOr "foobar" "foo" { foo = "bar"; }
     "bar"
     > set.getOr "foobar" "foo" { }
     "foobar"
  */
  getOr = default: k: s: s."${k}" or default;

  /* unsafeGet :: key -> set -> value

     > set.unsafeGet "foo" { foo = "bar"; }
     "bar"
  */
  unsafeGet = k: s: s."${k}";

  /* at :: [key] -> set -> optional value

     > set.at [ "foo" "bar" ] { foo.bar = "foobar"; }
     { _tag = "just"; value = "foobar"; }
     > set.at [ "foo" "foo" ] { foo.bar = "foobar"; }
     { _tag = "nothing"; }
  */
  at = path: s: list.foldl' (s: k:
    imports.optional.monad.bind s (get k)
  ) (imports.optional.just s) path;

  /* atOr :: default -> [key] -> set -> value

     > set.atOr "123" [ "foo" "bar" ] { foo.bar = "foobar"; }
     "foobar"
     > set.atOr "123" [ "foo" "foo" ] { foo.bar = "foobar"; }
     "123"
  */
  atOr = default: path: s: imports.optional.match (at path s) {
    nothing = default;
    just = id;
  };

  /* unsafeAt :: [key] -> set -> value

     > set.unsafeAt [ "foo" "bar" ] { foo.bar = "foobar"; }
     "foobar"
  */
  unsafeAt = path: s: list.foldl' (flip unsafeGet) s path;

  /* optional :: bool -> set -> set

     Optionally keep a set. If the condition is true, return the set
     unchanged, otherwise return an empty set.

     > set.optional true { foo = "bar"; }
     { foo = "bar"; }
     > set.optional false { foo = "bar"; }
     { }
  */
  optional = b: s: if b then s else empty;

  match = o: { empty, assign }:
    if o == {}
    then empty
    else match1 o { inherit assign; };

  # O(log(keys))
  match1 = o: { assign }:
    let k = builtins.head (keys o);
        v = o."${k}";
        r = builtins.removeAttrs o [k];
    in assign k v r;

  /* keys :: set -> [key]
  */
  keys = builtins.attrNames;

  /* values :: set -> [value]
  */
  values = builtins.attrValues;

  /* map :: (key -> value -> value) -> set -> set
  */
  map = builtins.mapAttrs;

  /* mapZip :: (key -> [value] -> value) -> [set] -> set
  */
  mapZip = let
    zipAttrsWithNames = names: f: sets: fromList (list.map (name: {
      _0 = name;
      _1 = f name (getAll name sets);
    }) names);
    zipAttrsWith = f: sets: zipAttrsWithNames (list.concatMap keys sets) f sets;
  in builtins.zipAttrsWith or zipAttrsWith;

  /* mapToValues :: (key -> value -> a) -> set -> [a]
  */
  mapToValues = f: compose values (map f);

  /* filter :: (key -> value -> bool) -> set -> set
  */
  filter = f: s: builtins.listToAttrs (list.concatMap (name: let
    value = s.${name};
  in list.optional (f name value) { inherit name value; }) (keys s));

  /* without :: [key] -> set -> set
  */
  without = flip builtins.removeAttrs;

  /* retain :: [key] -> set -> set
  */
  retain = keys: builtins.intersectAttrs (gen keys id);

  /* traverse :: Applicative f => (value -> f b) -> set -> f set
  */
  traverse = ap: f:
    (flip match) {
      empty = ap.pure empty;
      assign = k: v: r: ap.lift2 id (ap.map (assign k) (f v)) (traverse ap f r);
    };

  /* toList :: set -> [(key, value)]
  */
  toList = s: list.map (k: { _0 = k; _1 = s.${k}; }) (keys s);

  /* fromList :: [(key, value)] -> set
  */
  fromList = xs: builtins.listToAttrs (list.map ({ _0, _1 }: { name = _0; value = _1; }) xs);

  /* gen :: [key] -> (key -> value) -> set
  */
  gen = keys: f: fromList (list.map (n: { _0 = n; _1 = f n; }) keys);
}
