with { std = import ./../../default.nix; };
with std;

with (import ./../framework.nix);

let
  checkRoundtrip = to: from: data: assertEqual data (from (to data));
  checkRoundtripTOML = checkRoundtrip serde.toTOML serde.fromTOML;
  checkRoundtripJSON = checkRoundtrip serde.toJSON serde.fromJSON;
in
section "std.serde" {
  toml =
    string.unlines [
      # basic k = v notation
      (checkRoundtripTOML { foo = 1; })
      # inline JSON-like literals
      (checkRoundtripTOML { foo = [1 2 3]; })
      # basic table
      (checkRoundtripTOML { foo.bar = 1; })
      # nested tables with dots
      (checkRoundtripTOML { foo.bar.baz = 1; })
      # properly escapes invalid identifiers
      (checkRoundtripTOML { foo."bar.baz-quux".xyzzy = 1; })
      # double-bracket list notation for lists of dictionaries
      (checkRoundtripTOML { foo = [{ bar = 1; } { bar = [{ quux = 2; }]; }]; })
      # mixing dot notation and list notation
      (checkRoundtripTOML { foo.bar.baz = [{ bar = 1; } { bar = [{ quux = 2; }]; }]; })
    ];

  json =
    string.unlines [
      # basic k = v notation
      (checkRoundtripJSON { foo = 1; })
      # inline JSON-like literals
      (checkRoundtripJSON { foo = [1 2 3]; })
      # basic table
      (checkRoundtripJSON { foo.bar = 1; })
      # nested tables with dots
      (checkRoundtripJSON { foo.bar.baz = 1; })
      # properly escapes invalid identifiers
      (checkRoundtripJSON { foo."bar.baz-quux".xyzzy = 1; })
      # double-bracket list notation for lists of dictionaries
      (checkRoundtripJSON { foo = [{ bar = 1; } { bar = [{ quux = 2; }]; }]; })
      # mixing dot notation and list notation
      (checkRoundtripJSON { foo.bar.baz = [{ bar = 1; } { bar = [{ quux = 2; }]; }]; })
    ];
}
