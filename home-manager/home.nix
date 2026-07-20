{ inputs, lib, config, pkgs, ... }:

{
  imports = [
    ./shell.nix
  ];

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
    settings = {
      user = {
        email = "mateusanselmoguarino@gmail.com";
        name = "matoanselmo";
      };
    };
  };

  home.packages = with pkgs; [
    orca-slicer
    elephant
  ];
}
