# Setup Commands

**Restart your Mac** first to avoid potential FileVault issues.

### 1. Install Nix Package Manager

```bash
sh <(curl --proto '=https' --tlsv1.2 -L [https://nixos.org/nix/install](https://nixos.org/nix/install))
```

### 2. Download and Extract Dotfiles in a new terminal

```bash
curl -L 'https://github.com/BhuvanSA/.dotfiles/archive/refs/heads/main.tar.gz' | tar -xz && mv .dotfiles-main .dotfiles && cd .dotfiles && nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/.dotfiles#m1airb
```
