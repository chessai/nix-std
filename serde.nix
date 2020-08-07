{
  /* toJSON :: Set -> JSON
  */
  toJSON = builtins.toJSON;

  /* @partial
     fromJSON :: JSON -> Set
  */
  fromJSON = builtins.fromJSON;

  /* toTOML :: Set -> TOML
  */
  toTOML = throw "implement toTOML";

  /* @partial
     fromTOML :: TOML -> Set
  */
  fromTOML = builtins.fromTOML;
}
