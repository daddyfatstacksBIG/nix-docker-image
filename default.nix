{ pkgsSrc ? (import ./pkgs.nix {}).pkgsSrc
, pkgs ? (import ./pkgs.nix { inherit pkgsSrc; }).pkgs
}: with pkgs;

let
  nixConf = ''
    sandbox = false
    substituters = https://cache.nixos.org https://tdds.cachix.org https://dapp.cachix.org
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= tdds.cachix.org-1:omVB60rGSS+fhwtXk6yAJRI9js+qZ52Yw4CEK+0O9Zs= dapp.cachix.org-1:9GJt9Ja8IQwR7YW/aF0QvCa6OmjGmsKoZIist0dG+Rs=
  '';
in
  dockerTools.buildImageWithNixDb {
    name = "makerdao/nix";
    tag = "latest";

    runAsRoot = ''
      #!${runtimeShell}
      ${dockerTools.shadowSetup}
      groupadd --system -g 30000 nixbld
      for i in $(seq 1 30); do
        useradd --system -d /var/empty -c "Nix build user $i" -u $((30000 + i)) -G nixbld nixbld$i
      done
      mkdir /tmp
      mkdir -m 0755 /etc/nix
      printf %s '${nixConf}' > /etc/nix/nix.conf
      sh /etc/profile.d/nix.sh
    '';

    contents = [
      # Nix
      nix pkgsSrc
      coreutils git gzip gnutar xz less cacert

      # Common system tools
      which findutils gnused gnugrep
      bc jq
      bashInteractive

      # Dapp tools
      solc dapp ethsign seth mcd-cli
    ];
    diskSize = 4096; # 4GB

    config = {
      Env = [
        "USER=root"
        "PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin"
        "GIT_SSL_CAINFO=${cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
        "XDG_CACHE_HOME=/nix/cache"
        "NIX_PATH=nixpkgs=${pkgsSrc}"
      ];
      WorkingDir = "/root";
      Volumes = {
        "/nix" = {};
      };
    };
  }
