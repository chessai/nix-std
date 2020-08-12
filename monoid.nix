with rec {
  function = import ./function.nix;
  inherit (function) compose id flip;

  list = import ./list.nix;

  semigroup = import ./semigroup.nix;
};

{
  first = semigroup.first // {
    empty = null;
  };

  last = semigroup.last // {
    empty = null;
  };

  min = semigroup.min // {
    empty = null;
  };

  max = semigroup.max // {
    empty = max;
  };

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

  list = list.monoid;
}
