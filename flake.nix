{
  description = "Basic haskell cabal template";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = self: super: {
        hsPkgs = super.haskell.packages.ghc965.override {
          overrides = hself: hsuper: {
            # ghcid = super.haskell.lib.dontCheck hsuper.ghcid;
            # haskus-utils-variant = self.haskell.lib.unmarkBroken hsuper.haskus-utils-variant;
          };
        };
        ghcup-hs = self.hsPkgs.callCabal2nix "ghcup-hs" ./. {};
      };

      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        { default = pkgs.ghcup-hs;
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          libs = with pkgs; [
            zlib
          ];
        in
        {
          default = pkgs.hsPkgs.shellFor {
            packages = hsPkgs: [ ];
            buildInputs = with pkgs; [
              hsPkgs.cabal-install
              hsPkgs.cabal-fmt
              hsPkgs.ghcid
              hsPkgs.ghc
              cabal2nix
            ] ++ libs;
            shellHook = "export PS1='[$PWD]\n❄ '";
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;
          };
        });
    };
}
