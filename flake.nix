{
  description = "Zenful nix-darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # mac-app-util.url = "github:hraban/mac-app-util";

    opencode.url = "github:anomalyco/opencode/dev";

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
      opencode,
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
            pkgs.antigravity
            pkgs.appcleaner
            pkgs.biome
            pkgs.bun
            pkgs.cloudflared
            pkgs.claude-code
            pkgs.cocoapods
            pkgs.rabbitmq-server
            pkgs.rabbitmqadmin-ng
            pkgs.ruff
            pkgs.deno
            pkgs.dioxus-cli
            pkgs.fzf
            pkgs.gh
            pkgs.iterm2
            pkgs.jq
            pkgs.maccy
            pkgs.neovim
            opencode.packages.${pkgs.system}.default
            pkgs.nix-zsh-completions
            pkgs.nixfmt-rfc-style
            pkgs.nodejs_24
            pkgs.oh-my-posh
            pkgs.pnpm
            pkgs.rustup
            pkgs.rustlings
            pkgs.supabase-cli
            pkgs.uv
            pkgs.vscode
            pkgs.vlc-bin
            pkgs.yarn
          ];

          environment.variables = {
            RABBITMQ_BASE = ''$HOME/.rabbitmq'';
            RABBITMQ_MNESIA_BASE = ''$HOME/.rabbitmq/mnesia'';
            RABBITMQ_LOG_BASE = ''$HOME/.rabbitmq/log'';
            RABBITMQ_PID_FILE = ''$HOME/.rabbitmq/rabbitmq.pid'';
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

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
              "promptfoo"
            ];
            casks = [
              "batfi"
              "thebrowsercompany-dia"
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
              "/Applications/Nix Apps/Visual Studio Code.app"
            ];
            NSGlobalDomain."AppleSpacesSwitchOnActivate" = false;
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
