{ osConfig, ... }:
let
  flake = "~/System#${osConfig.networking.hostName}";
in
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      nrs = "sudo nixos-rebuild switch --flake ${flake}";
      nrb = "sudo nixos-rebuild boot --flake ${flake}";
      nrt = "sudo nixos-rebuild test --flake ${flake}";
      nrd = "nixos-rebuild build --flake ${flake}";
      nfu = "nix flake update --flake ~/System";
    };
    interactiveShellInit = ''
      set fish_greeting ""

      set --global fish_color_autosuggestion 969896
      set --global fish_color_cancel --reverse
      set --global fish_color_command c397d8
      set --global fish_color_comment e7c547
      set --global fish_color_cwd green
      set --global fish_color_cwd_root red
      set --global fish_color_end c397d8
      set --global fish_color_error d54e53
      set --global fish_color_escape 00a6b2
      set --global fish_color_history_current --bold
      set --global fish_color_host --reset
      set --global fish_color_host_remote yellow
      set --global fish_color_normal --reset
      set --global fish_color_operator 00a6b2
      set --global fish_color_param 7aa6da
      set --global fish_color_quote b9ca4a
      set --global fish_color_redirection 70c0b1
      set --global fish_color_search_match white --bold --background=brblack
      set --global fish_color_selection white --bold --background=brblack
      set --global fish_color_status red
      set --global fish_color_user brgreen
      set --global fish_color_valid_path --underline=single
      set --global fish_pager_color_completion --reset
      set --global fish_pager_color_description B3A06D
      set --global fish_pager_color_prefix --bold --underline=single
      set --global fish_pager_color_progress brwhite --bold --background=cyan
      set --global fish_pager_color_selected_background --background=brblack
    '';
    functions.fish_prompt = ''
      set_color $fish_color_cwd
      echo -n (path basename $PWD)
      set_color --reset
      echo -n ' ) '
    '';
  };

  home.sessionPath = [ "$HOME/.local/bin" ];
}
