{
  description = "Fulcrum infrastructure development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # Infrastructure
          opentofu
          talosctl
          kubectl
          kubernetes-helm
          cilium-cli

          # Data / validation
          jq
          yq-go
          kubeconform
          yamllint

          # Language servers
          tofu-ls
          yaml-language-server
          nixd

          # Formatting / linting
          nixfmt
          shellcheck
          shfmt

          # Workflow
          just
          git
        ];

        # shellHook = ''
        #   export KUBECONFIG="$PWD/k8s/kubeconfig"
        #   export TALOSCONFIG="$PWD/infra/talos/talosconfig"
        #
        #   proxmox-auth() {
        #     read -s -p "Proxmox password: " pw
        #     echo
        #     export PROXMOX_VE_PASSWORD="$pw"
        #     unset pw
        #   }
        # '';
      };
    };
}
