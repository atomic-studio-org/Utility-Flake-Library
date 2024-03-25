# This flake was initially generated by fh, the CLI for FlakeHub (version 0.1.9)
{
  description = "Utility Library for Atomic Studio projects";

  inputs = {
    bluebuild.url = "https://flakehub.com/f/blue-build/cli/0.8.2.tar.gz";
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";
    nix-pre-commit-hooks.url = "https://github.com/cachix/pre-commit-hooks.nix/tarball/master";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
  };

  outputs = { self, flake-schemas, nixpkgs, nix-pre-commit-hooks, bluebuild }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      schemas = flake-schemas.schemas;

      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixpkgs-fmt);

      lib = forEachSupportedSystem ({ pkgs }: {
        iterFullSystemSupport = forEachSupportedSystem;

        devShellPackages = with pkgs; [
          bluebuild.packages.${pkgs.system}.bluebuild
          git
          jq
          yq
          nixpkgs-fmt
          nushell
          gh
          jujutsu
        ];
      });

      checks = forEachSupportedSystem ({ pkgs }: rec {
        default = pre-commit-check;
        pre-commit-check = nix-pre-commit-hooks.lib.${pkgs.system}.run {
          src = ./.;

          hooks = {
            nixpkgs-fmt.enable = true;
            shellcheck.enable = true;
            yamllint = {
              enable = true;
              settings = {
                configPath = "${./yamllint.yml}";
              };
            };
            commitizen.enable = true;
            markdownlint = {
              enable = true;
              settings.config = {
                "MD013" = {
                  line_length = 280;
                  code_blocks = false;
                  tables = false;
                };
                "MD033" = {
                  allowed_elements = [ "div" "h1" "h2" "h3" "h4" "img" "a" "p" "br" "hr" "strong" ];
                };
              };
            };
          };
        };
      });

      templates = rec {
        default = github-repository;
        github-repository = {
          path = ./template/github-repository;
          description = "Github repository template for any Atomic Studio project";
        };
        package-repository = {
          path = ./template/package-repository;
          description = "Github repository template for any Atomic Studio project that needs packaging";
        };
      };

      packages = forEachSupportedSystem ({ pkgs }: {
        generate-sbkey = pkgs.writers.writeNuBin "sbkey-generator" ''
          # Generate secure boot keys for any kernel signing effort you need
          def main [--folder_name (-f): string] {
            if $folder_name != null {
              mkdir $folder_name
            } else {
              mkdir result
            }

            ${pkgs.lib.getExe pkgs.openssl} req -new -x509 -newkey rsa:2048 -nodes -days 36500 -outform DER -keyout "result/MOK.priv" -out "result/MOK.der"
          }
        '';

        cosign-generate = pkgs.writers.writeNuBin "cosign-generate" ''
          # Generate a private and public cosign key for container signing usage!
          def main [--keep] {
            echo "DO NOT add any password, this will break your CI jobs!"
            ${pkgs.cosign}/bin/cosign generate-key-pair
            open cosign.key | ${pkgs.lib.getExe pkgs.gh} secret set SIGNING_SECRET --app actions
            if $keep == null {
              rm cosign.key
            }
          }
        '';
      });

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = self.lib.${pkgs.system}.devShellPackages;
        };
      });
    };
}
