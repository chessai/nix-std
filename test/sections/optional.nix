with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.optional" {
  laws = string.unlines [
    (functor optional.functor {
      typeName = "optional";
      identity = {
        x = optional.just 5;
      };
      composition = {
        f = optional.monad.join;
        g = optional.just;
        x = optional.just "foo";
      };
    })
    (applicative optional.applicative {
      typeName = "optional";
      identity = {
        v = optional.nothing;
      };
      composition = {
        u = optional.just (b: builtins.toString (b + 1));
        v = optional.just (a: a + 1);
        w = optional.just 5;
      };
      homomorphism = {
        f = builtins.toString;
        x = 5;
      };
      interchange = {
        u = optional.just (x: x + "-" + x);
        y = "foo";
      };
    })
    (monad optional.monad {
      typeName = "optional";
      leftIdentity = {
        f = x: optional.just (x + x);
        x = 5;
      };
      rightIdentity = {
        x = optional.just 55;
      };
      associativity = {
        m = optional.just optional.nothing;
        f = x: optional.match x {
          nothing = optional.just (optional.just 5);
          just = k: optional.just (optional.just (k + 1));
        };
        g = x: optional.match x {
          nothing = optional.just (optional.just 1);
          just = k: optional.just (optional.just (k + 5));
        };
      };
    })
    (semigroup (optional.semigroup list.semigroup) {
      typeName = "optional";
      associativity = {
        a = optional.just [1 2 3 4];
        b = optional.just [5 6 7 8];
        c = optional.just [9 10];
      };
    })
    (monoid (optional.monoid list.monoid) {
      typeName = "optional";
      leftIdentity = {
        x = optional.just [1 2 3 4 5];
      };
      rightIdentity = {
        x = optional.just ["one" "two" "three" "four" "five"];
      };
    })
  ];

  match = assertEqual "foobar"
    (optional.match (optional.just "foobar") {
      nothing = "baz";
      just = function.id;
    });

  isJust = string.unlines [
    (assertEqual true (optional.isJust (optional.just 5)))
    (assertEqual true (optional.isJust (optional.just null)))
    (assertEqual false (optional.isJust optional.nothing))
  ];

  isNothing = string.unlines [
    (assertEqual false (optional.isNothing (optional.just 5)))
    (assertEqual false (optional.isNothing (optional.just null)))
    (assertEqual true (optional.isNothing optional.nothing))
  ];

  toNullable = string.unlines [
    (assertEqual 1 (optional.toNullable (optional.just 1)))
    (assertEqual null (optional.toNullable optional.nothing))
  ];
}
