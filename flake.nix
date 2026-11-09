{
  description = "Mato's NixOS hosts: desktop, laptop and server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Not in nixpkgs; community flake with a Home Manager module.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Not in nixpkgs; repackages Helium's .deb releases, with a Home Manager
    # module (laptop only; see my.browser).
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure Boot (desktop only; see CLAUDE.md).
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tessera, the Quickshell shell. Pinned in flake.lock; bump with
    # `nix flake update tessera`.
    tessera = {
      url = "github:matoanselmo/tessera";
      flake = false;
    };

    # Not in nixpkgs; Rust CAD app with its own flake (desktop only).
    solidcraft = {
      url = "github:tangency-labs/solidcraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Printer add-ons for the server (hosts/server/printer.nix). Not in
    # nixpkgs; pinned to the revisions that ran on Ubuntu. Bump with
    # `nix flake update <name>`.
    klipper-led-effect = {
      url = "github:julianschill/klipper-led_effect/266f1049c7172c2fba0da4a52314dcfc0c3bb56f";
      flake = false;
    };
    klipper-tmc-autotune = {
      url = "github:andrewmcgr/klipper_tmc_autotune/9f88cf7a8cabf5890d56fee2c688f2fe61087683";
      flake = false;
    };
    moonraker-timelapse = {
      url = "github:mainsail-crew/moonraker-timelapse/c7fff11e542b95e0e15b8bb1443cea8159ac0274";
      flake = false;
    };
    mainsail-config = {
      url = "github:mainsail-crew/mainsail-config/ff3869a621db17ce3ef660adbbd3fa321995ac42";
      flake = false;
    };
    mobileraker-companion = {
      url = "github:Clon1998/mobileraker_companion/d455af67d6e9bb5d194121616cd0863043bee2c7";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      ...
    }@inputs:
    let
      # workstation = false leaves out the desktop, Home Manager and the NAS
      # mount (the server *is* the NAS).
      mkHost =
        {
          dir,
          hostName ? dir,
          workstation ? true,
        }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            flakeHost = dir; # differs from the hostname on the server
          };
          modules = [
            disko.nixosModules.disko
            ./modules/nixos/core.nix
            ./hosts/${dir}
            { networking.hostName = hostName; }
          ]
          ++ nixpkgs.lib.optionals workstation [
            home-manager.nixosModules.home-manager
            ./modules/nixos
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                users.ruggy = ./modules/home;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost { dir = "desktop"; };
        laptop = mkHost { dir = "laptop"; };
        server = mkHost {
          dir = "server";
          hostName = "matoserver";
          workstation = false;
        };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
    };
}
