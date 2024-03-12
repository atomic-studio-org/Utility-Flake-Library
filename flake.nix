# This flake was initially generated by fh, the CLI for FlakeHub (version 0.1.9)
{
  description = "Utility Library for Atomic Studio projects";
  
  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";
    nix-pre-commit-hooks.url = "https://github.com/cachix/pre-commit-hooks.nix/tarball/master";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
  };
  
  outputs = { self, flake-schemas, nixpkgs, nix-pre-commit-hooks }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in {
      schemas = flake-schemas.schemas;
     
      checks = forEachSupportedSystem ({
        pkgs
      }: {
        pre-commit-check = nix-pre-commit-hooks.lib.${pkgs.system}.run {
          src = ./.;

          default_stages = ["manual" "push"];
          hooks = {
            shellcheck.enable = true;
            markdownlint.enable = true;
            yamllint.enable = true;
            commitizen.enable = true;
          };
        };
      });

      template = rec {
	default = github-repository;
	github-repository = {
	  path = ./template/github-repository;
	  description = "Github repository template for any Atomic Studio project";
	};
      };

      packages = forEachSupportedSystem ({ pkgs}: {
	cosign-generate = pkgs.writeScriptBin "cosign-generate" ''
	  echo "DO NOT add any password, this will break your CI jobs!"
	  ${pkgs.cosign}/bin/cosign generate-key-pair
	  cat cosign.key | ${pkgs.lib.getExe pkgs.gh} secret set SIGNING_SECRET --app actions
	  rm cosign.key
	'';
      });

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
	  inherit (self.checks.${pkgs.system}.pre-commit-check) shellHook;
          packages = with pkgs; [
            git
            jq
            nixpkgs-fmt
	    nushell
          ];
        };
      });
    };
}