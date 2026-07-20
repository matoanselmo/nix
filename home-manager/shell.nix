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
      ll = "ls -la";
      ".." = "cd ..";
    };

    shellAbbrs = {
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";
      nrs = "sudo nixos-rebuild switch --flake ~/system#nix";
      cat = "bat";
    };

    interactiveShellInit = ''
      set fish_greeting

      fastfetch --logo none --structure "Title:OS:Kernel:Shell:DE:WM:CPU:GPU:Memory:Disk"
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
