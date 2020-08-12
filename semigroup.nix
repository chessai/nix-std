with rec {
  function = import ./function.nix;
  inherit (function) compose id flip;

  list = import ./list.nix;
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

  list = list.semigroup;
}
