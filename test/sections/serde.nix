with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

section "std.serde" {
  toml =
    let
      checkRoundtrip = data:
        assertEqual true (builtins.fromTOML (serde.toTOML data) == data);
    in
    string.unlines [
      # basic k = v notation
      (checkRoundtrip { foo = 1; })
      # inline JSON-like literals
      (checkRoundtrip { foo = [1 2 3]; })
      # basic table
      (checkRoundtrip { foo.bar = 1; })
      # nested tables with dots
      (checkRoundtrip { foo.bar.baz = 1; })
      # properly escapes invalid identifiers
      (checkRoundtrip { foo."bar.baz-quux".xyzzy = 1; })
      # double-bracket list notation for lists of dictionaries
      (checkRoundtrip { foo = [{ bar = 1; } { bar = [{ quux = 2; }]; }]; })
      # mixing dot notation and list notation
      (checkRoundtrip { foo.bar.baz = [{ bar = 1; } { bar = [{ quux = 2; }]; }]; })
    ];
}
