{
  description = "Flake utils demo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachSystem [
    "aarch64-darwin"
    "x86_64-darwin"
  ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib stdenv;
      in
      {
        packages = rec {
          dark-notify = stdenv.mkDerivation {
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
          };
          vim-plugin = pkgs.vimUtils.buildVimPlugin {
            name = "dark-notify";
            src = ./vimplugin;
            runtimeDeps = [ dark-notify ];
          };
          demo-vim = pkgs.neovim.override {
            configure = {
              packages.demoPlugins.start = [
                vim-plugin
              ];
            };
          };
          default = dark-notify;
        };
        apps = rec {
          dark-notify = flake-utils.lib.mkApp { drv = self.packages.${system}.dark-notify; };
          default = dark-notify;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [ self.packages.${system}.dark-notify ];
        };
      }
    );
}
