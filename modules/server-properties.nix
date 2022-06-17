{ pkgs, ... }:
{
  propertiesFile =
    { allow-flight ? false
    , allow-nether ? true
    , broadcast-console-to-ops ? true
    , broadcast-rcon-to-ops ? true
    , difficulty ? "easy"
    , enable-command-block ? false
    , enable-jmx-monitoring ? false
    , enable-query ? false
    , enable-rcon ? false
    , enable-status ? true
    , enforce-whitelist ? false
    , entity-broadcast-range-percentage ? 100
    , force-gamemode ? false
    , function-permission-level ? 2
    , gamemode ? "survival"
    , generate-structures ? true
    , generator-settings ? "{}"
    , hardcore ? false
    , hide-online-players ? false
    , level-name ? "world"
    , level-seed ? ""
    , level-type ? "default"
    , max-players ? 20
    , max-tick-time ? 60000
    , max-world-size ? 29999984
    , motd ? "A Minecraft Server"
    , network-compression-threshold ? 256
    , online-mode ? true
    , op-permission-level ? 4
    , player-idle-timeout ? 0
    , prevent-proxy-connections ? false
    , pvp ? true
    , query-port ? 25565
    , rate-limit ? 0
    , rcon-password ? ""
    , rcon-port ? "25575"
    , require-resource-pack ? false
    , resource-pack ? ""
    , resource-pack-prompt ? ""
    , resource-pack-sha1 ? ""
    , server-ip ? ""
    , server-port ? 25565
    , simulation-distance ? 10
    , spawn-animals ? true
    , spawn-monsters ? true
    , spawn-npcs ? true
    , spawn-protection ? 16
    , sync-chunk-writes ? true
    , text-filtering-config ? ""
    , use-native-transport ? true
    , view-distance ? 10
    , white-list ? false
    }:
    pkgs.writeTextFile {
      name = "server.properties";
      text = ''
        allow-flight=${toString allow-flight}
        allow-nether=${toString allow-nether}
        broadcast-console-to-ops=${toString broadcast-console-to-ops}
        difficulty=${difficulty}
        enable-command-block=${toString enable-command-block}
        enable-jmx-monitoring=${toString enable-jmx-monitoring}
        enable-query=${toString enable-query}
        enable-rcon=${toString enable-rcon}
        enable-status=${toString enable-status}
        enforce-whitelist=${toString enforce-whitelist}
        entity-broadcast-range-percentage=${toString entity-broadcast-range-percentage}
        force-gamemode=${toString force-gamemode}
        function-permission-level=${toString function-permission-level}
        gamemode=${gamemode}
        generate-structures=${toString generate-structures}
        generator-settings=${generator-settings}
        hardcore=${toString hardcore}
        hide-online-players=${toString hide-online-players}
        level-name=${level-name}
        level-seed=${level-seed}
        level-type=${level-type}
        max-players=${toString max-players}
        max-tick-time=${toString max-tick-time}
        max-world-size=${toString max-world-size}
        motd=${motd}
        network-compression-threshold=${toString network-compression-threshold}
        online-mode=${toString online-mode}
        op-permission-level=${toString op-permission-level}
        player-idle-timeout=${toString player-idle-timeout}
        prevent-proxy-connections=${toString prevent-proxy-connections}
        pvp=${toString pvp}
        query.port=${toString query-port}
        rate-limit=${toString rate-limit}
        rcon.password=${rcon-password}
        rcon.port=${toString rcon-port}
        require-resource-pack=${toString require-resource-pack}
        resource-pack=${resource-pack}
        resource-pack-prompt=${resource-pack-prompt}
        resource-pack-sha1=${resource-pack-sha1}
        server-ip=${server-ip}
        server-port=${toString server-port}
        simulation-distance=${toString simulation-distance}
        spawn-animals=${toString spawn-animals}
        spawn-monsters=${toString spawn-monsters}
        spawn-npcs=${toString spawn-npcs}
        spawn-protection=${toString spawn-protection}
        sync-chunk-writes=${toString sync-chunk-writes}
        text-filtering-config=${toString text-filtering-config}
        use-native-transport=${toString use-native-transport}
        view-distance=${toString view-distance}
        white-list=${toString white-list}
      '';
    };
}
