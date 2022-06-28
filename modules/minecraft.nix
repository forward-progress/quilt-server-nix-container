{ config, lib, pkgs, ... }@attrs:

with lib; {
  options = {
    forward-progress.services.minecraft = {
      enable = mkEnableOption "minecraft";
      properties =
        let
          withDefault = { description, default }:
            mkOption {
              inherit default;
              inherit description;
              type =
                let t = types."${builtins.typeOf default}"; in
                if t == types.string then types.str else t;
            };
        in
        {
          enable = {
            command-block = withDefault { description = "Enable command blocks"; default = false; };
            jmx-monitoring = withDefault { description = "Enable JMX Monitoring"; default = false; };
            query = withDefault { description = "Enable query"; default = false; };
            status = withDefault { description = "Enable status"; default = true; };
          };
          rcon = {
            # Hardcode to simplify other modules
            # enable = withDefault { description = ""; default = ""; };
            port = withDefault { description = "RCON port"; default = 25575; };
            # Specify a default password file so the other modules will still work
            # TODO: Document that this makes rcon unsafe to expose
            passwordFile = mkOption {
              description = "File containing the rcon password";
              default = pkgs.writeTextFile {
                name = "RCONPassword";
                text = "OhNoAnInsecurePassword";
              };
            };
          };
          level = {
            seed = withDefault { description = "World Seed"; default = ""; };
            type = withDefault { description = "World Type"; default = "default"; };
            # Hardcode this to simplify other modules
            # name = withDefault { description = ""; default = ""; };
          };
          max = {
            players = withDefault { description = "Max Players"; default = 20; };
            tick-time = withDefault { description = "Max Allowed tick time"; default = "60000"; };
            world-size = withDefault { description = "Max world size"; default = 29999984; };
          };
          resource-pack = {
            require = withDefault { description = "Require the resource pack"; default = false; };
            url = withDefault { description = "Url for the resource pack"; default = ""; };
            prompt = withDefault { description = "Prompt for the resource pack"; default = ""; };
            sha1 = withDefault { description = "sha1 for the resource pack"; default = ""; };
          };
          server = {
            ip = withDefault { description = "IP Address to bind to"; default = "0.0.0.0"; };
            port = withDefault { description = "Port to bind to"; default = 25565; };
          };
          spawn = {
            animals = withDefault { description = "Spawn animals"; default = true; };
            monsters = withDefault { description = "Spawn monsters"; default = true; };
            npcs = withDefault { description = "Spawn npcs"; default = true; };
          };
          allow = {
            flight = withDefault { description = "Allow flight on the server"; default = false; };
            nether = withDefault { description = "Allow access to the nether"; default = true; };
          };
          broadcast-console-to-ops = withDefault { description = "Broadcast console commands to ops"; default = true; };
          difficulty = withDefault { description = "Server difficulty"; default = "easy"; };
          enforce-whitelist = withDefault { description = "Enforce the whitelist"; default = false; };
          entity-broadcast-range-percentage = withDefault { description = ""; default = 100; };
          force-gamemode = withDefault { description = "Force Game Mode"; default = false; };
          function-permission-level = withDefault { description = "Function's Permission level"; default = 2; };
          gamemode = withDefault { description = "Server gamemode"; default = "survival"; };
          generate-structures = withDefault { description = "Generate Structures"; default = true; };
          generator-settings = withDefault { description = "Generator Settings"; default = ""; };
          hardcore = withDefault { description = "Hardcore mode"; default = false; };
          hide-online-players = withDefault { description = "Hide online players"; default = false; };
          motd = withDefault { description = "The server's MOTD"; default = "A Minecraft Server"; };
          network-compression-threshold = withDefault { description = "Network Compression Threshold"; default = 256; };
          online-mode = withDefault { description = "Online Mode"; default = true; };
          op-permission-level = withDefault { description = "OP's permission level"; default = 4; };
          player-idle-timeout = withDefault { description = "Player idle timeout"; default = 0; };
          prevent-proxy-connections = withDefault { description = "Prevent proxy connections"; default = false; };
          pvp = withDefault { description = "Enable PvP"; default = true; };
          query-port = withDefault { description = "Query status port"; default = 25565; };
          rate-limit = withDefault { description = "Rate Limit"; default = 0; };
          simulation-distance = withDefault { description = "Simulation Distance"; default = 8; };
          spawn-protection = withDefault { description = "Spawn Protection Radius"; default = 16; };
          sync-chunk-writes = withDefault { description = ""; default = true; };
          text-filtering-config = withDefault { description = ""; default = ""; };
          use-native-transport = withDefault { description = ""; default = true; };
          view-distance = withDefault { description = "View distance"; default = 10; };
          white-list = withDefault { description = "Whitelist"; default = false; };
        };
      minecraft-version = mkOption {
        example = "1.18.2";
        description = "Version of minecraft to install";
        type = types.str;
      };
      quilt-version = mkOption {
        example = "0.17.1-beta.4";
        description = "Version of the quilt launcher to install";
        type = types.str;
      };
      packwiz-url = mkOption {
        example = "";
        description = "Packwiz pack url";
        type = types.str;
      };
      ram = mkOption {
        example = "4096";
        description = "Megabytes of ram to give the server";
        default = 4096;
        type = types.int;
      };
      acceptEula = mkOption {
        example = "true";
        description = "Accept minecraft eula";
        default = false;
        type = types.bool;
      };
    };
  };

  config = mkIf config.forward-progress.services.minecraft.enable {
    users = {
      # Create the minecraft group
      groups."minecraft" = { };
      # And our minecraft user
      users."minecraft" = {
        group = "minecraft";
        home = "/var/minecraft";
        createHome = true;
        isNormalUser = true;
      };
    };
    # Create the minecraft service
    systemd.services.minecraft =
      let
        x = config.forward-progress.services.minecraft.properties;
        boolString = y: if y then "true" else "false";
        propertiesFile =
          (import ./server-properties.nix attrs).propertiesFile {
            allow-flight = boolString x.allow.flight;
            allow-nether = boolString x.allow.nether;
            broadcast-console-to-ops = boolString x.broadcast-console-to-ops;
            broadcast-rcon-to-ops = boolString x.broadcast-rcon-to-ops;
            difficulty = x.difficulty;
            enable-command-block = boolString x.enable.command-block;
            enable-jmx-monitoring = boolString x.enable.jmx-monitoring;
            enable-query = boolString x.enable.query;
            enable-rcon = boolString true;
            enable-status = boolString x.enable.status;
            enforce-whitelist = boolString x.enforce-whitelist;
            entity-broadcast-range-percentage = x.entity-broadcast-range-percentage;
            force-gamemode = boolString x.force-gamemode;
            function-permission-level = x.function-permission-level;
            gamemode = x.gamemode;
            generate-structures = boolString x.generate-structures;
            generator-settings = x.generator-settings;
            hardcore = boolString x.hardcore;
            hide-online-players = boolString x.hide-online-players;
            level-name = "world";
            level-seed = x.level.seed;
            level-type = x.level.type;
            max-players = x.max.players;
            max-tick-time = x.max.tick-time;
            max-world-size = x.max.world-size;
            motd = x.motd;
            network-compression-threshold = x.network-compression-threshold;
            online-mode = boolString x.online-mode;
            op-permission-level = x.op-permission-level;
            player-idle-timeout = x.player-idle-timeout;
            prevent-proxy-connections = boolString x.prevent-proxy-connections;
            pvp = boolString x.pvp;
            query-port = x.query-port;
            rate-limit = x.rate-limit;
            rcon-port = x.rcon.port;
            require-resource-pack = boolString x.resource-pack.require;
            resource-pack = x.resource-pack.url;
            resource-pack-prompt = x.resource-pack.prompt;
            resource-pack-sha1 = x.resource-pack.sha1;
            server-ip = x.server.ip;
            server-port = x.server.port;
            simulation-distance = x.simulation-distance;
            spawn-animals = boolString x.spawn.animals;
            spawn-monsters = boolString x.spawn.monsters;
            spawn-npcs = boolString x.spawn.npcs;
            spawn-protection = x.spawn-protection;
            sync-chunk-writes = boolString x.sync-chunk-writes;
            text-filtering-config = x.text-filtering-config;
            use-native-transport = boolString x.use-native-transport;
            white-list = boolString x.white-list;
          };
        quiltInstaller = builtins.fetchurl {
          url = "https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/0.4.3/quilt-installer-0.4.3.jar";
          sha256 = "02pq244asikbw1iichwjnw4x92lq1q0fpidb2fp1vm03ack6hmh4";
        };
        packwizBootstrap = builtins.fetchurl {
          url = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar";
          sha256 = "0v0i7m2bdjnbrfzmv3f0xyc8nc8sv79q53k8yjbqw9q4qr6v5yx8";
        };
        startScript = pkgs.substituteAll {
          src = ../scripts/server-start.sh;
          isExecutable = true;
          inherit propertiesFile;
          inherit quiltInstaller;
          minecraftVersion = config.forward-progress.services.minecraft.minecraft-version;
          quiltVersion = config.forward-progress.services.minecraft.quilt-version;
          inherit packwizBootstrap;
          packwizUrl = config.forward-progress.services.minecraft.packwiz-url;
          rconPasswordFile = x.rcon.passwordFile;
          ram = config.forward-progress.services.minecraft.ram;
          acceptEula = boolString config.forward-progress.services.minecraft.acceptEula;
        };
        stopScript = pkgs.substituteAll {
          isExecutable = true;
          src = ../scripts/server-stop.sh;
          rconPasswordFile = x.rcon.passwordFile;
          rconPort = x.rcon.port;
          minecraftPort = x.server.port;
        };
      in
      {
        description = "Minecraft";
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [
          bash
          config.forward-progress.config.javaPackage
          mcrcon
          iproute2
          ripgrep
          procps
        ];
        serviceConfig = {
          Type = "simple";
          User = "minecraft";
          Group = "minecraft";
          UMask = "0027";
          Restart = "always";
          KillMode = "none"; # FIXME: This is a kludge, identify a way to work around it
          ExecStart = startScript;
          ExecStop = stopScript;
          SuccessExitStatus = "0 1 255";
        };
      };
  };
}
