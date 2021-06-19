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

  /* 'optional' recovers a monoid from a semigroup by adding `optional.nothing`
     as the empty element. The semigroup's append will simply discard nothings
     in favor of other elements.
  */
  optional = semigroup: {
    append = x: y:
      if x.value == null
        then y
      else if y.value == null
        then x
      else { value = semigroup.append x.value y.value; };
  };

  nullable = semigroup: {
    append = x: y:
      if x == null
        then y
      else if y == null
        then x
      else semigroup.append x y;
  };
}
