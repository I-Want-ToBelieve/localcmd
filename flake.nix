{
  description = "LocalSend is a free, open-source app that allows you to securely share files and messages with nearby devices over your local network without needing an internet connection.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-root.url = "github:srid/flake-root";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs/stable";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://devenv.cachix.org"
    ];
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.devenv.flakeModule inputs.treefmt-nix.flakeModule inputs.flake-root.flakeModule];
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        android-sdk = inputs.android-nixpkgs.sdk.${system} (sdkPkgs:
          with sdkPkgs; [
            cmdline-tools-latest
            build-tools-30-0-3
            platform-tools
            platforms-android-33
            emulator
          ]);
      in {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.
        devenv.shells.default = {
          name = "localcmd";

          imports = [
            # This is just like the imports in devenv.nix.
            # See https://devenv.sh/guides/using-with-flake-parts/#import-a-devenv-module
            # ./devenv-foo.nix
          ];

          # https://devenv.sh/reference/options/
          packages = with pkgs; [flutter gradle android-sdk];

          # https://devenv.sh/basics/
          env = {
            GREET = "🛠️ Let's hack 🧑🏻‍💻";
            PATH = "$HOME/.pub-cache/bin";
            ANDROID_HOME = "${android-sdk}/share/android-sdk";
            ANDROID_SDK_ROOT = "${android-sdk}/share/android-sdk";
          };

          # https://devenv.sh/scripts/
          scripts.hello.exec = "echo $GREET";

          enterShell = ''
            hello
          '';

          # https://devenv.sh/langhttps://nixos.wiki/wiki/Flutteruages/
          languages.dart = {
            enable = true;
          };
          languages.java = {
            enable = true;
          };

          # Make diffs fantastic
          difftastic.enable = true;

          # https://devenv.sh/pre-commit-hooks/
          pre-commit.hooks = {
            # commons
            editorconfig-checker.enable = true;

            # configs
            yamllint.enable = true;

            # nix
            alejandra.enable = true;
          };
        };

        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          # This is the default, and can be overriden.
          package = pkgs.treefmt;

          # formats .nix files
          programs.alejandra.enable = true;
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
