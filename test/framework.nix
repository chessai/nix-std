with { std = import ./../default.nix; };
with std;

rec {
  section = module: tests: ''
    (
      echo "''${SECTION_INDENT:-}testing ${module}"
      SECTION_INDENT="''${SECTION_INDENT:-}  "
      ${string.concat
          (list.map
            (test: ''echo "''${SECTION_INDENT}...${test._0}"...; ${test._1}'')
              (set.toList tests))
       }
    )
  '';

  assertEqual = x: y:
    if x == y
    then string.empty
    else ''
      ERR="
        assertEqual failed: x != y, where

          x = ${string.escape [''"''] (types.show x)}
          y = ${string.escape [''"''] (types.show y)}

      "
      printf "$ERR"
      exit 1
    '';

  lawCheck = { lawName, typeName ? null }: x: y:
    if x == y
    then ''
      printf "  ''${SECTION_INDENT:-}[${typeName}] ${lawName}: ✓"
      echo ""
    ''
    else ''
      ERR="
        law does not hold: x != y, where

          x = ${string.escape [''"''] (types.show x)}
          y = ${string.escape [''"''] (types.show y)}

      "
      printf "  ''${SECTION_INDENT:-}[${typeName}] ${lawName}: ✗"
      printf "$ERR"
      exit 1
    '';

  functor = functor:
            { typeName
            , identity
            , composition
            }:
    let functorIdentity = xs:
          lawCheck {
            lawName = "functor identity";
            inherit typeName;
          } (functor.map id xs) xs;
        functorComposition = f: g: xs:
          lawCheck {
            lawName = "functor composition";
            inherit typeName;
          } (functor.map (compose f g) xs)
            (functor.map f (functor.map g xs));
    in string.unlines [
         (functorIdentity identity.x)
         (functorComposition composition.f composition.g composition.x)
       ];

  applicative = applicative:
                { typeName
                , identity
                , composition
                , homomorphism
                , interchange
                }:
    let applicativeIdentity = v:
          lawCheck {
            lawName = "applicative identity";
            inherit typeName;
          } (applicative.ap (applicative.pure id) v) v;

        applicativeComposition = u: v: w:
          lawCheck {
            lawName = "applicative composition";
            inherit typeName;
          } (applicative.ap (applicative.ap ((applicative.ap (applicative.pure compose) u)) v) w)
            (applicative.ap u (applicative.ap v w));

        applicativeHomomorphism = f: x:
          lawCheck {
            lawName = "applicative homomorphism";
            inherit typeName;
          } (applicative.ap (applicative.pure f) (applicative.pure x))
            (applicative.pure (f x));

        applicativeInterchange = u: y:
          lawCheck {
            lawName = "applicative interchange";
            inherit typeName;
          } (applicative.ap u (applicative.pure y))
            (applicative.ap (applicative.pure (f: f y)) u);
    in string.unlines [
         (applicativeIdentity identity.v)
         (applicativeComposition composition.u composition.v composition.w)
         (applicativeHomomorphism homomorphism.f homomorphism.x)
         (applicativeInterchange interchange.u interchange.y)
       ];

  monad = monad:
          { typeName
          , leftIdentity
          , rightIdentity
          , associativity
          }:
    let monadLeftIdentity = f: x:
          lawCheck {
            lawName = "monad left identity";
            inherit typeName;
          } (monad.bind (monad.pure x) f) (f x);

        monadRightIdentity = x:
          lawCheck {
            lawName = "monad right identity";
            inherit typeName;
          } (monad.bind x monad.pure) x;

        monadAssociativity = m: f: g:
          lawCheck {
            lawName = "monad associativity";
            inherit typeName;
          } (monad.bind (monad.bind m f) g)
            (monad.bind m (x: monad.bind (f x) g));
    in string.unlines [
         (monadLeftIdentity leftIdentity.f leftIdentity.x)
         (monadRightIdentity rightIdentity.x)
         (monadAssociativity associativity.m associativity.f associativity.g)
       ];

  semigroup = semigroup: { typeName, associativity }:
    let semigroupAssociativity = a: b: c:
          lawCheck {
            lawName = "semigroup associativity";
            inherit typeName;
          } (semigroup.append a (semigroup.append b c))
            (semigroup.append (semigroup.append a b) c);
    in semigroupAssociativity associativity.a associativity.b associativity.c;

  monoid = monoid: { typeName, leftIdentity, rightIdentity }:
    let monoidLeftIdentity = x:
          lawCheck {
            lawName = "monoid left identity";
            inherit typeName;
          } (monoid.append monoid.empty x) x;
        monoidRightIdentity = x:
          lawCheck {
            lawName = "monoid right identity";
            inherit typeName;
          } (monoid.append x monoid.empty) x;
    in string.unlines [
         (monoidLeftIdentity leftIdentity.x)
         (monoidRightIdentity rightIdentity.x)
       ];
}
