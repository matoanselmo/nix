{pkgs, ...}: {
  home.packages = [
    pkgs.fastfetch
    pkgs.fortune
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

      fastfetch
      echo ""
      fortune -s
    '';
  };

  # Starship is a separate module — enable it here and configure
  # under programs.starship once you're ready:
  # programs.starship.enable = true;
}
