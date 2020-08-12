with {
  function = import ./function.nix;
  inherit (function) compose id flip;

  list = import ./list.nix;

  semigroups = import ./semigroups.nix;
};

{
  first = semigroups.first // {
    empty = null;
  };

  last = semigroups.last // {
    empty = null;
  };

  min = semigroups.min // {
    empty = null;
  };

  max = semigroups.max // {
    empty = max;
  };

  dual = monoid: semigroups.dual monoid // {
    empty = monoid.empty
  };

  endo = semigroups.endo // {
    empty = id;
  };

  all = semigroups.all // {
    empty = true;
  };

  and = semigroups.and // {
    empty = false;
  };

  list = list.monoid;
}
