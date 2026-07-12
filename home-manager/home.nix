{ inputs, lib, config, pkgs, ... }:

{
  imports = [];

  nixpkgs = {
    overlays = [];
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "ruggy";
    homeDirectory = "/home/ruggy";

    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Mateus Anselmo";
    userEmail = "mateusanselmoguarino@gmail.com";
  };

  # User-specific packages go here
  home.packages = with pkgs; [
    # discord
    # vscode
    # neofetch
  ];
}
