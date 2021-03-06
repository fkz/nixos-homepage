{ lib, forceCatch
, package }:

let
  isSimple = x: builtins.isString x || builtins.isBool x || builtins.isInt x || builtins.isNull x;
  protect = x: if isDerivation x then { type = "derivation"; } else if isSimple x then x else "(protected)";
  arguments =
    if !(package ? _functionArgs) then { error = "This derivation seems not to use lib.makeOverridable, so parameters couldn't be determined"; } else
    let f = name: isOptional:
      forceCatch (x: x // { type = "derivation"; })
      (if builtins.hasAttr name package.origArgs
      then protect package.origArgs.${name}
      else if isOptional then "(optional)" else { type = "derivation"; }); in
    lib.mapAttrs f package._functionArgs;
  isDerivation = x:
    lib.isDerivation x || lib.isFunction x ||
    (if lib.isList x then lib.any isDerivation x
    else if lib.isAttrs x then lib.any isDerivation (lib.attrValues x)
    else false);
  result = lib.filterAttrs (x: y: !isDerivation y) arguments;
in result