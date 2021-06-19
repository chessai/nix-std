with rec {
  function = import ./function.nix;
  inherit (function) compose id flip;

  semigroup = import ./semigroup.nix;

  imports = {
    list = import ./list.nix;
    string = import ./string.nix;
    optional = import ./optional.nix;
  };
};

rec {
  first = optional semigroup.first;

  last = optional semigroup.last;

  min = optional semigroup.min;

  max = optional semigroup.max;

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

  /* 'optional' recovers a monoid from a semigroup by adding `optional.nothing`
     as the empty element.
  */
  optional = sg: semigroup.optional sg // {
    empty = imports.optional.nothing;
  };

  nullable = sg: semigroup.nullable sg // {
    empty = null;
  };
}
