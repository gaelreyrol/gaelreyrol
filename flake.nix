{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          treefmt = {
            programs.nixfmt = {
              enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform pkgs.nixfmt-rfc-style.compiler;
              package = pkgs.nixfmt-rfc-style;
            };
            programs.yamlfmt.enable = true;
            settings.formatter = {
              "tanka-fmt" = {
                command = "${pkgs.tanka}/bin/tk";
                options = [ "fmt" ];
                includes = [
                  "*.jsonnet"
                  "*.libsonnet"
                ];
              };
            };
          };
          pre-commit = {
            settings.hooks.treefmt.enable = true;
          };
          devShells.default =
            let
              helm = (
                pkgs.wrapHelm pkgs.kubernetes-helm {
                  plugins = with pkgs.kubernetes-helmPlugins; [
                    helm-diff
                    helm-secrets
                    helm-s3
                    helm-git
                  ];
                }
              );
            in
            pkgs.mkShell {
              buildInputs = [
                pkgs.age
                pkgs.sops
                pkgs.just
                pkgs.cfssl
                pkgs.yq-go
                pkgs.kind
                pkgs.kubectl
                helm
                pkgs.go-jsonnet
                pkgs.jsonnet-bundler
                pkgs.gojsontoyaml
                pkgs.tanka
                pkgs.kyverno-chainsaw
                pkgs.minio-client
              ];
              shellHook = config.pre-commit.installationScript;
            };
        };
    };
}
