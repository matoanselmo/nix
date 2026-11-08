{ pkgs, ... }:
{
  # settings.json stays mutable: Home Manager merges these in and Zed can still
  # write to it, so fonts picked in Zed stick. MonoLisa isn't packaged (it's paid
  # and stays out of git); it's installed by hand into ~/.local/share/fonts.
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "colored-zed-icons-theme"
    ];
    extraPackages = with pkgs; [
      nixd
      nixfmt
    ];
    userSettings = {
      project_panel.dock = "left";
      ui_font_size = 16;
      buffer_font_size = 15;
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
      icon_theme = {
        mode = "system";
        light = "Colored Zed Icons Theme Light";
        dark = "Colored Zed Icons Theme Dark";
      };
    };
  };
}
