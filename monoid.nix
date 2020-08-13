with rec {
  function = import ./function.nix;
  inherit (function) compose id flip;

  semigroup = import ./semigroup.nix;

  imports = {
    list = import ./list.nix;
    string = import ./string.nix;
  };
};

rec {
  first = maybe semigroup.first;

  last = maybe semigroup.last;

  min = maybe semigroup.min;

  max = maybe semigroup.max;

  dual = monoid: semigroup.dual monoid // {
    empty = monoid.empty;
  };

  endo = semigroup.endo // {
    empty = id;
  };

  all = semigroup.all // {
    empty = true;
  };

  and = semigroup.and // {
    empty = false;
  };

  list = imports.list.monoid;

  string = imports.string.monoid;

  /* 'maybe' recovers a monoid from a semigroup by adding 'null' as the empty element.
  */
  maybe = sg: semigroup.maybe sg // {
    empty = null;
  };
}
