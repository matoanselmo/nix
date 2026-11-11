# The prompt, colours and abbreviations are in modules/nixos/fish.nix and the
# tools (zoxide, atuin, fzf...) in modules/nixos/shell.nix, so the server gets
# them too. Home Manager's own fish config still has to be enabled for
# home.sessionPath.
{
  programs.fish.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];
}
