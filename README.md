# Setup Commands

**Restart your Mac** first to avoid potential FileVault issues.

### 1. Install xcode
```bash
xcode-select --install
```

### 2. Install Nix Package Manager

```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
```

### 3. Download and Extract Dotfiles in a new terminal

```bash
git clone https://github.com/BhuvanSA/.dotfiles.git ~/.dotfiles && sudo nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/.dotfiles#m1airb
```

### 4.
