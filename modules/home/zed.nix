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
      disable_ai = true;
      project_panel.dock = "left";
      ui_font_size = 15;
      buffer_font_size = 15;
      buffer_font_weight = 600;
      buffer_line_height = "comfortable";
      use_smartcase_search = true;
      colorize_brackets = true;
      code_lens = "on";
      show_whitespaces = "none";
      relative_line_numbers = "enabled";
      rounded_selection = false;
      current_line_highlight = "gutter";
      hide_mouse = "never";
      cursor_animation.enabled = true;
      autosave.after_delay.milliseconds = 250;
      diagnostics.inline.enabled = true;
      inlay_hints = {
        enabled = false;
        show_background = false;
      };
      indent_guides = {
        background_coloring = "disabled";
        coloring = "indent_aware";
      };
      toolbar = {
        code_actions = true;
        agent_review = false;
        selections_menu = true;
        quick_actions = true;
        breadcrumbs = true;
      };
      minimap.show = "auto";
      scrollbar.show = "never";
      gutter.line_numbers = true;
      markdown_preview.open_markdown_files_in_preview = true;
      theme = {
        mode = "system";
        light = "One Dark";
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
