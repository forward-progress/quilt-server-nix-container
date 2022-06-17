{
  description = "A containerized quilt server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    java = {
      url = "github:nathans-flakes/java";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, java }: {
    nixosConfigurations.container =
      let
        system = "x86_64-linux";
        rconPassword = "totallyAPassword";
      in
      nixpkgs.lib.nixosSystem {
        # TODO make generic in system after I've made the java flake do as such
        inherit system;
        modules = [
          ({ pkgs, ... }@attrs: {
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
            environment.systemPackages = [
              # OpenJ9 java
              java.packages."${system}".semeru-latest
              # Rcon client
              pkgs.mcrcon
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
              # Oneshot service to link the files we need out of the store
              directory-setup =
                let
                  propertiesFile = (import ./modules/server-properties.nix attrs).propertiesFile {
                    motd = "Nathan's Private Modded Minecraft";
                    enable-rcon = true;
                    rcon-password = rconPassword;
                  };
                in
                {
                  description = "Setup the minecraft server directory";
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig.Type = "oneshot";
                  script =
                    ''
                      # Make sure the directory exists
                      mkdir -p /var/minecraft/server;

                      # link the server.properties
                      ln -s ${propertiesFile} /var/minecraft/server/server.properties

                      # Make sure everything belongs to the minecraft user
                      chown -R minecraft:minecraft /var/minecraft
                    '';
                };
            };
          })
        ];
      };
  };
}
