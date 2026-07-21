{pkgs, ...}: {
  home.packages = [
    pkgs.fastfetch
    pkgs.fortune
    pkgs.nerd-fonts.jetbrains-mono
  ];

  programs.fish = {
    enable = true;

    shellAliases = {
      hms = "home-manager switch --flake ~/system#ruggy@nix";
      nrs = "sudo nixos-rebuild switch --flake ~/system#nix";
      ll = "ls -la";
      ".." = "cd ..";
      ".h" = "cd ~";
    };

    shellAbbrs = {
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";
    };

    interactiveShellInit = ''
      set fish_greeting

      fastfetch
      echo ""
      fortune -s
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      format = "$all";

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      git_branch = {
        symbol = " ";
      };

      nodejs = {
        symbol = " ";
      };

      python = {
        symbol = " ";
      };

      rust = {
        symbol = " ";
      };

      package = {
        symbol = " ";
      };
    };
  };
}
