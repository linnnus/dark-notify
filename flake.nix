{
  description = "Flake utils demo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      eachSystem = nixpkgs.lib.genAttrs supportedSystems;
      eachPkgs = f: eachSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
      in f pkgs);
    in
    {
      packages = eachPkgs (pkgs: rec {
        inherit (pkgs) dark-notify;
        vimPlugins = { inherit (pkgs.vimPlugins) dark-notify; };

        demo-vim = pkgs.neovim.override {
          configure = {
            packages.demoPlugins.start = [
              vimPlugins.dark-notify
            ];
          };
        };

        default = dark-notify;
      });

      overlays = {
        default = final: prev: {
          dark-notify = prev.callPackage ({
            stdenv
          }: stdenv.mkDerivation {
            pname = "dark-notify";
            version = "0.1.0";
            src = ./.;
            buildPhase = ''
              cc @compile_flags.txt -O3 -o dark-notify dark-notify.m
            '';
            installPhase = ''
              mkdir -p $out/bin
              mv dark-notify $out/bin
            '';
          }) { };

          vimPlugins = prev.vimPlugins.extend (final': prev': {
            dark-notify = prev.vimUtils.buildVimPlugin {
              name = "dark-notify";
              src = ./vimplugin;
              runtimeDeps = [ final.dark-notify ];
            };
          });
        };
      };

      devShells = eachPkgs (pkgs: {
        default = pkgs.mkShell {
          buildInputs = [ self.packages.${pkgs.system}.dark-notify ];
        };
      });
    };
}
