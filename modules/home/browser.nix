# Zen Browser (beta) from github:0xc000022070/zen-browser-flake. The binary
# and desktop entry are `zen-beta`.
{ inputs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  # setAsDefaultBrowser fills in xdg.mimeApps but doesn't turn it on.
  xdg.mimeApps.enable = true;
}
