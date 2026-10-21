{ pkgs, ... }:
{
  programs.foot = {
    enable = true;
    settings.main = {
      font = "JetBrains Mono:size=12";
      include = "${pkgs.foot.themes}/share/foot/themes/onedark";
    };
  };
}
