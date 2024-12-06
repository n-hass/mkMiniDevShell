{
  description = "A flake for building dev shells";

  inputs = {
    mk-minimal-shell.url = "github:n-hass/mkminimalshell";
  };

  outputs =
    { self, mk-minimal-shell }:
    {
      overlay =
        final: prev:
        let
          baseMkMinimalShell = mk-minimal-shell.overlay final prev;
        in
        {
          mkMiniDevShell = args:
            let
              shellHookOption = args.returnToUserShell or false;
              returnToUserShellHook = let 
                execUserShell = ''
                  TARGET_SHELL=$(${final.pkgs.coreutils}/bin/pinky -l $USER | ${final.pkgs.gawk}/bin/awk '/Shell:/ {print $NF}')
                  exec $TARGET_SHELL
                '';
              in {
                "" = "";
                "0" = "";
                "1" = ''
                  if [ "$DIRENV_IN_ENVRC" = "1" ]; then
                    # do nothing, direnv will load a new shell
                    :
                  elif [ -n "$IN_NIX_SHELL" ]; then
                    ${execUserShell}
                  else
                    echo "Unknown environment loader - use direnv or 'nix develop'"
                  fi
                '';
                "force" = execUserShell;
              }.${toString shellHookOption};


              generatedArgs = {
                extraUnsetEnv = [
                  "returnToUserShell"
                ];
                
                shellHook = ''
                  ${args.shellHook or ""}
                  ${returnToUserShellHook}
                '';
              };
            in
            baseMkMinimalShell.mkMinimalShell (final.lib.recursiveUpdate args generatedArgs);
        };
    };
}
