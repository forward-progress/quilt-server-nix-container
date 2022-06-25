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
    # Testing container
    nixosConfigurations = {
      container =
        makeContainer {
          system = "x86_64-linux";
          rconPassword = "totallyAPassword";
          minecraftVersion = "1.18.2";
          quiltVersion = "0.17.1-beta.4";
          ram = 4096; # In mebibytes
          packwizUrl = "https://pack.forward-progress.net/0.3-no-discord/pack.toml";
          # Indicate that we accept the eula
          acceptEula = "true";
        };
    };

    makeContainer =
      { system
        # TODO make this sops compatible by making this read in a file instead
      , rconPassword
      , minecraftVersion
      , quiltVersion
      , ram
      , # In mebibytes
        packwizUrl
      , # Indicate that we accept the eula
        acceptEula
      , # Directory in the continar to backup to
        backupDirectory ? "/var/minecraft/backup/"
      }:
      nixpkgs.lib.nixosSystem {
        # TODO make generic in system after I've made the java flake do as such
        inherit system;
        modules = [
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
              environment.systemPackages = with pkgs; [
                javaPackage
                # Rcon client
                mcrcon
                # Util linux for ipcs
                util-linux
              ];

              ###
              ## User
              ###
              users = {
                mutableUsers = false;
                # Enable us to not use a password, this is a container
                allowNoPasswordLogin = true;
                # Create the minecraft group
                groups."minecraft" = { };
                # And our minecraft user
                users."minecraft" = {
                  group = "minecraft";
                  home = "/var/minecraft";
                  createHome = true;
                  isSystemUser = true;
                };
              };

              ###
              ## Services
              ###
              systemd.services = {
                # The server proper
                minecraft =
                  let
                    propertiesFile = (import ./modules/server-properties.nix attrs).propertiesFile {
                      motd = "Nathan's Private Modded Minecraft";
                      enable-rcon = "true";
                      rcon-password = rconPassword;
                    };
                    quiltInstaller = builtins.fetchurl {
                      url = "https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/0.4.3/quilt-installer-0.4.3.jar";
                      sha256 = "02pq244asikbw1iichwjnw4x92lq1q0fpidb2fp1vm03ack6hmh4";
                    };
                    packwizBootstrap = builtins.fetchurl {
                      url = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar";
                      sha256 = "0v0i7m2bdjnbrfzmv3f0xyc8nc8sv79q53k8yjbqw9q4qr6v5yx8";
                    };
                    subbedScript = pkgs.substituteAll {
                      src = ./scripts/server-start.sh;
                      inherit propertiesFile;
                      inherit quiltInstaller;
                      inherit minecraftVersion;
                      inherit quiltVersion;
                      inherit javaPackage;
                      inherit packwizBootstrap;
                      inherit packwizUrl;
                      inherit acceptEula;
                      inherit ram;
                    };
                  in
                  {
                    description = "Minecraft";
                    wantedBy = [ "multi-user.target" ];
                    serviceConfig = {
                      Type = "simple";
                      User = "minecraft";
                      Group = "minecraft";
                      UMask = "0027";
                      Restart = "on-failure";
                      KillMode = "none"; # FIXME: This is a kludge, identify a way to work around it
                      ExecStop = "${pkgs.mcrcon}/bin/mcrcon -H localhost -p ${rconPassword} stop";
                    };
                    script = builtins.readFile subbedScript;
                  };
              };
            })
        ];
      };
  };
}
