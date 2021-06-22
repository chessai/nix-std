with rec {
  function = import ./function.nix;
  inherit (function) compose id flip;

  imports = {
    list = import ./list.nix;
    string = import ./string.nix;
    nullable = import ./nullable.nix;
    optional = import ./optional.nix;
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

  nullable = imports.nullable.semigroup;

  optional = imports.optional.semigroup;
}
