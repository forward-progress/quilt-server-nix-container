{
  description = "A containerized quilt server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    java = {
      url = "github:nathans-flakes/java";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, java }: rec {
    # Module
    nixosModules = {
      forward-progress = { config, lib, pkgs, ... }: with lib; {
        imports = [
          ./modules/minecraft.nix
          ./modules/backup.nix
        ];
        options = {
          forward-progress.config = {
            javaPackage = mkOption {
              description = "Version of java to use";
              example = "pkgs.jdk";
              default = pkgs.jdk;
            };
          };
        };
      };
      default = self.nixosModules.forward-progress;
    };

    # Testing container
    nixosConfigurations = {
      container =
        let
          system = "x86_64-linux";
          writeTextFile = nixpkgs.legacyPackages."${system}".writeTextFile;
        in
        makeContainer rec {
          inherit system;
          minecraftVersion = "1.18.2";
          quiltVersion = "0.17.1-beta.4";
          ram = 4096; # In mebibytes
          packwizUrl = "https://raw.githubusercontent.com/Fabulously-Optimized/fabulously-optimized/main/Packwiz/1.18.2/pack.toml";
          # Indicate that we accept the eula
          acceptEula = "true";
          b2AccountID = "00284106ead1ac40000000002";
          b2KeyFile = writeTextFile {
            name = "b2KeyFile";
            text = "lol. lamo";
          };
          b2Bucket = "ForwardProgressServerBackup";
        };
    };

    makeContainer =
      {
        # Platform this container is being built for
        system
        # Version of minecraft to use
      , minecraftVersion
        # Version of quilt to use
      , quiltVersion
        # Ammount of ram to allocate, in mebibytes
      , ram
        # The url of the packwiz pack to use for this server
      , packwizUrl
      , # Indicate that we accept the eula
        acceptEula
      , # Directory in the continar to backup to
        backupDirectory ? "/var/minecraft/backup"
      , # The B2 account id
        b2AccountID
      , # The file containing the b2 account key
        b2KeyFile
      , # The name of the b2 bucket to backup to
        b2Bucket
      }:
      nixpkgs.lib.nixosSystem {
        # TODO make generic in system after I've made the java flake do as such
        inherit system;
        modules = [
          self.nixosModules.forward-progress
          ({ pkgs, lib, ... }@attrs:
            let
              # OpenJDK 17
              javaPackage = pkgs.jdk;
            in
            {
              ###
              ## Container stuff
              ###
              # Let nix know this is a container
              boot.isContainer = true;
              # Set system state version
              system.stateVersion = "22.05";
              # Insert the git revision of this flake
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
              # Setup networking
              networking.useDHCP = false;
              # Allow minecraft out
              networking.firewall.allowedTCPPorts = [ 25565 ];

              # Install packages
              # FIXME: Remove this, the systemd services should not rely on it
              environment.systemPackages = with pkgs; [
                javaPackage
                # Rcon client
                mcrcon
                # Util linux for ipcs
                util-linux
                # backblaze b2 clent
                backblaze-b2
                # Ripgrep for scripting
                ripgrep
              ];

              ###
              ## User
              ###
              users = {
                mutableUsers = false;
                # Enable us to not use a password, this is a container
                allowNoPasswordLogin = true;
              };

              ###
              ## Configure module
              ###
              forward-progress = {
                services = {
                  minecraft = {
                    enable = true;
                    minecraft-version = minecraftVersion;
                    quilt-version = quiltVersion;
                    ram = ram;
                    properties = {
                      motd = "Nathan's Private Modded Minecraft";
                    };
                    packwiz-url = packwizUrl;
                    acceptEula = true;
                  };
                  backup = {
                    enable = true;
                    backblaze = {
                      enable = true;
                      accountId = b2AccountID;
                      keyFile = b2KeyFile;
                      bucket = b2Bucket;
                    };
                  };
                };
              };
            })
        ];
      };
  };
}
