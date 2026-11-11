# Command-line tools for every host. They're system-wide rather than in Home
# Manager because the server has no Home Manager.
{ pkgs, ... }:
{
  # `cd` is zoxide: `cd proj` jumps to the best match, `cdi` picks one.
  programs.zoxide = {
    enable = true;
    flags = [ "--cmd cd" ];
  };

  # Per-directory environments (`use flake` in an .envrc), with nix-direnv.
  programs.direnv.enable = true;

  programs.bat.enable = true;
  programs.yazi.enable = true;
  programs.lazygit.enable = true;

  # `nh os switch` etc.: nixos-rebuild with a build tree and a package diff.
  # The abbreviations in fish.nix call it.
  programs.nh = {
    enable = true;
    flake = "/home/ruggy/System";
  };

  # Shell history, synced between the hosts through the Atuin server on
  # matoserver (hosts/server/services.nix). Ctrl+R searches it; the up arrow
  # stays fish's own. Once per machine: `atuin register` on the first one,
  # then `atuin login` and `atuin sync` on the others.
  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      sync_address = "http://matoserver:8888";
      auto_sync = true;
      sync_frequency = "5m";
    };
  };

  environment.systemPackages = with pkgs; [
    eza
    fd
    ripgrep
    btop
    dust
    fzf
  ];

  # ll and l are defined in terms of ls, so they become eza too.
  environment.shellAliases.ls = "eza --group-directories-first";

  # fzf: Ctrl+T inserts files and Alt+C changes directory. Its Ctrl+R is
  # switched off (an empty FZF_CTRL_R_COMMAND) so Atuin keeps that key.
  programs.fish.interactiveShellInit = ''
    set --global FZF_CTRL_R_COMMAND ""
    source ${pkgs.fzf}/share/fzf/key-bindings.fish && fzf_key_bindings
  '';
}
