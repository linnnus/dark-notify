{
  description = "Flake utils demo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
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
          dark-notifier = stdenv.mkDerivation {
            pname = "dark-notifier";
            version = "0.1.0";
            src = ./.;
            buildInputs = with pkgs.darwin.apple_sdk.frameworks; [ Cocoa ];
            buildPhase = ''
              cc -framework Cocoa -fobjc-arc -o dark-notifier dark-notify.m
            '';
            installPhase = ''
              mkdir -p $out/bin
              mv dark-notifier $out/bin
            '';
          };
          default = dark-notifier;
        };
        apps = rec {
          dark-notifier = flake-utils.lib.mkApp { drv = self.packages.${system}.dark-notifier; };
          default = dark-notifier;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [ self.packages.${system}.dark-notifier ];
        };
      }
    );
}
