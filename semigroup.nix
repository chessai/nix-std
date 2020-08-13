with rec {
  function = import ./function.nix;
  inherit (function) compose id flip;

  imports = {
    list = import ./list.nix;
    string = import ./string.nix;
  };
};

{
  first = {
    append = x: _: x;
  };

  last = {
    append = _: x: x;
  };

  min = {
    append = x: y:
      if x < y
      then x
      else y;
  };

  max = {
    append = x: y:
      if x > y
      then x
      else y;
  };

  dual = semigroup: {
    append = flip semigroup.append;
  };

  endo = {
    append = compose;
  };

  all = {
    append = x: y: x && y;
  };

  and = {
    append = x: y: x || y;
  };

  list = imports.list.semigroup;

  string = imports.string.semigroup;

  /* 'maybe' recovers a monoid from a semigroup by adding 'null' as the empty
     element. The semigroup's append will simply discard nulls in favor of other
     elements.
  */
  maybe = semigroup: {
    append = x: y:
      if x == null
        then y
      else if y == null
        then x
      else semigroup.append x y;
  };
}
