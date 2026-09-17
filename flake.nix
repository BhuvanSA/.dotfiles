{
  description = "Zenful nix-darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # mac-app-util.url = "github:hraban/mac-app-util";

    claude-code.url = "github:sadjow/claude-code-nix";
    claude-code.inputs.nixpkgs.follows = "nixpkgs";

    opencode-nix.url = "github:nklmilojevic/opencode-nix";
    opencode-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Pinned to the last nixpkgs rev Hydra actually built zed-editor for on
    # aarch64-darwin (2026-09-11, zed 1.19.2). Newer nixos-unstable revs change
    # zed's derivation hash without a darwin build in cache.nixos.org, which
    # turns every rebuild into a multi-hour local Rust compile. Drop this input
    # and go back to `pkgs.zed-editor` once darwin builds are cached again.
    nixpkgs-zed.url = "github:NixOS/nixpkgs/c320b9607c14419236aa9151a3d3a73e23bbd090";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-zed,
      claude-code,
      opencode-nix,
      # mac-app-util,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # Allow unfree packages, such as obsidian
          nixpkgs.config.allowUnfree = true;
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.actionlint
            # `az self-test` (installCheckPhase) crashes with SIGABRT during
            # Python 3.14 interpreter shutdown on the macOS 27 beta — the check
            # passes functionally, only the exit aborts. The extension override
            # forces a local build (not cached), so we hit it. Skip the check.
            ((pkgs.azure-cli.withExtensions [
              (pkgs.azure-cli-extensions.containerapp.overridePythonAttrs (old: {
                pythonRelaxDeps = [ "kubernetes" ];
              }))
            ]).overrideAttrs (_: {
              doInstallCheck = false;
            }))
            pkgs.bun
            pkgs.cloudflared
            claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
            opencode-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
            pkgs.cocoapods
            pkgs.ffmpeg-headless
            pkgs.rabbitmq-server
            pkgs.rabbitmqadmin-ng
            (pkgs.callPackage ./pkgs/remindctl.nix { })
            pkgs.ruff
            pkgs.dioxus-cli
            pkgs.doctl
            pkgs.fzf
            pkgs.gh
            pkgs.google-cloud-sdk
            pkgs.gws
            pkgs.ghostty-bin
            pkgs.iterm2
            pkgs.jq
            # pkgs.kubectl
            # pkgs.minikube
            pkgs.maccy
            pkgs.neovim
            pkgs.nix-zsh-completions
            pkgs.nixfmt
            pkgs.nodejs_24
            pkgs.oh-my-posh
            pkgs.pango
            pkgs.pnpm
            pkgs.postgresql_18
            pkgs.pi-coding-agent
            pkgs.rustup
            pkgs.rustlings
            pkgs.smartmontools
            pkgs.tree
            pkgs.twilio-cli
            pkgs.hoppscotch
            pkgs.uv
            pkgs.vlc-bin
            pkgs.yarn
            nixpkgs-zed.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zed-editor
          ];

          environment.variables = {
            EDITOR = "zeditor --wait";
            VISUAL = "zeditor --wait";
            RABBITMQ_BASE = "$HOME/.rabbitmq";
            RABBITMQ_MNESIA_BASE = "$HOME/.rabbitmq/mnesia";
            RABBITMQ_LOG_BASE = "$HOME/.rabbitmq/log";
            RABBITMQ_PID_FILE = "$HOME/.rabbitmq/rabbitmq.pid";
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Extra binary caches
          nix.settings.substituters = [
            "https://opencode-nix-cache.cachix.org"
            "https://nix-community.cachix.org"
          ];
          nix.settings.trusted-public-keys = [
            "opencode-nix-cache.cachix.org-1:Wq9yk7XD0pg457w4D5HV2OJVj++tl70tfzde1SrfYX8="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];

          # Garbage collection — weekly on Saturday at 3 AM, keep last 7 days
          nix.gc = {
            automatic = true;
            interval = { Weekday = 6; Hour = 3; Minute = 0; };
            options = "--delete-older-than 7d";
          };

          # Store optimisation — deduplicate identical files weekly
          nix.optimise = {
            automatic = true;
            interval = { Weekday = 6; Hour = 4; Minute = 0; };
          };

          # Daily auto-update: nix flake update + darwin-rebuild switch
          # Runs at 09:00; RunAtLoad catches up if the Mac was asleep.
          launchd.daemons.dotfiles-auto-update = {
            script = ''
              export PATH=/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin
              cd /Users/bhuvansa/.dotfiles || exit 1
              /run/current-system/sw/bin/nix flake update
              chown bhuvansa:staff flake.lock
              /run/current-system/sw/bin/darwin-rebuild switch --flake /Users/bhuvansa/.dotfiles#m1airb
            '';
            serviceConfig = {
              StartCalendarInterval = [ { Hour = 9; Minute = 0; } ];
              RunAtLoad = false;
              StandardOutPath = "/var/log/dotfiles-auto-update.log";
              StandardErrorPath = "/var/log/dotfiles-auto-update.log";
            };
          };

          # Font configuration
          fonts = {
            packages = [
              pkgs.nerd-fonts.agave
            ];
          };

          programs.zsh = {
            enable = true;
            interactiveShellInit = ''
              source $HOME/.dotfiles/configs/zsh/.zshrc
            '';
          };

          homebrew = {
            enable = true;
            brews = [
              "mas"
              "mole"
            ];
            casks = [
              "batfi"
              "orbstack"
              "google-chrome"
              "karabiner-elements"
              "requestly"
            ];
            masApps = {
              # "Dropover" = 1355679052;
            };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          system.defaults = {
            dock.autohide = true;
            dock.autohide-delay = 0.0;
            dock.autohide-time-modifier = 0.0;
            dock.mru-spaces = false;
            dock.persistent-apps = [
              "/Applications/Zed.app"
            ];
            NSGlobalDomain."AppleSpacesSwitchOnActivate" = false;

            menuExtraClock = {
              ShowSeconds = true;
            };
          };

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
          system.primaryUser = "bhuvansa";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."m1airb" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          # mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # enableRosetta = true;
              user = "bhuvansa";
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              mutableTaps = false;
            };
          }
          (
            { config, ... }:
            {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
            }
          )
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."m1airb".pkgs;
    };
}
