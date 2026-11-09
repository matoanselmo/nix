# The prompt, colours and abbreviations are in modules/nixos/fish.nix, so the
# server gets them too. Home Manager's own fish config still has to be enabled
# for zoxide and home.sessionPath.
{
  programs.fish.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];
}
