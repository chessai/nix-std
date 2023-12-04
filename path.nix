with rec {
  string = import ./string.nix;
  bool = import ./bool.nix;
  types = import ./types.nix;
};

rec {
  /* baseName :: string | path -> string

     Returns everything following the final slash in a path, without
     context. Typically, this corresponds to the file or directory name.

     > path.baseName "/a/b/c"
     "c"
     > path.baseName /a/b/c
     "c"
  */
  baseName = p: builtins.baseNameOf (
    if types.path.check p then p
    # NOTE: the builtin's behaviour is inconsistent when passed a path vs string, and
    # it is nonsensical to retain string context for the stripped-off filename anyway.
    else builtins.unsafeDiscardStringContext (toString p)
  );

  /* dirName :: string -> string

     Returns the directory part of the path-like string, without context.

     > path.dirName "/a/b/c"
     "/a/b"
     > path.dirName "a/b/c"
     "a/b"
  */
  dirName = p: builtins.dirOf (builtins.unsafeDiscardStringContext (toString p));

  /* parent :: path -> path
     parent :: string -> string

     Returns the directory part of the path.

     > path.dirName "/a/b/c"
     "/a/b"
     > path.dirName /a/b/c
     /a/b
  */
  parent = builtins.dirOf;

  /* fromString :: string -> optional path

     Casts a string into a path type. Returns `optional.nothing`
     if the path is not absolute (it must start with a `/` to be valid).

     > path.fromString "/a/b/c"
     { _tag = "just"; value = /a/b/c; }
     > path.fromString "a/b/c"
     { _tag = "nothing"; }
  */
  fromString = s: bool.toOptional (string.hasPrefix "/" s) (unsafeFromString s);

  /* unsafeFromString :: string -> path

     Casts a string into a path type. The resulting path will be incorrect if
     a relative path is provided.

     > path.unsafeFromString "/a/b/c"
     /a/b/c
  */
  unsafeFromString = s: /. + builtins.unsafeDiscardStringContext (toString s);
}
