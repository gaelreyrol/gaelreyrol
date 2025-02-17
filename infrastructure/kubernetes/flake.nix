{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        devShells.default = let 
          helm = (pkgs.wrapHelm pkgs.kubernetes-helm {
            plugins = with pkgs.kubernetes-helmPlugins; [
              helm-diff
              helm-secrets
              helm-s3
              helm-git
            ];
          });
        in pkgs.mkShell {
          buildInputs = [
            pkgs.yq-go
            pkgs.kind
            pkgs.kubectl
            helm
            pkgs.go-jsonnet
            pkgs.jsonnet-bundler
            pkgs.gojsontoyaml
            pkgs.tanka
          ];
        };
      };
    };
}