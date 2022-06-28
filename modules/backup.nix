{ config, lib, pkgs, ... }:

with lib; {
  options = {
    forward-progress.services.backup = {
      enable = mkEnableOption "Borg Backups";
      backupDirectory = mkOption {
        example = "/var/minecraft/backup";
        description = "Directory in the container to backup to";
        default = "/var/minecraft/backup";
        type = types.str;
      };
      times = mkOption {
        example = "[ \"*-*-* *:55:00\" ]";
        description = "Times to run backups at";
        # Run hourly, 5 minutes before the hour, so the backups take place on the hour
        default = [ "*-*-* *:55:00" ];
      };
      backblaze = {
        enable = mkEnableOption "Upload backups to backblaze";
        accountId = mkOption {
          description = "Backblaze B2 account ID";
          default = "INVALID";
          type = types.str;
        };
        keyFile = mkOption {
          description = "File containing the B2 account key";
          default = writeTextFile {
            name = "b2KeyFile";
            text = "INVALID";
          };
        };
        bucket = mkOption {
          description = "Name of the b2 bucket to use";
          default = "INVALID";
          type = types.str;
        };
      };
    };
  };

  config =
    let
      services = config.forward-progress.services;
    in
    mkIf (services.backup.enable && services.minecraft.enable) {
      systemd = {
        services.minecraft-backups =
          let
            backupScript = pkgs.substituteAll {
              src = ../scripts/backup.sh;
              isExecutable = true;
              rconPort = services.minecraft.properties.rcon.port;
              rconPasswordFile = services.minecraft.properties.rcon.passwordFile;
              backupDirectory = services.backup.backupDirectory;
              b2AccountID = services.backup.backblaze.accountId;
              b2KeyFile = services.backup.backblaze.keyFile;
              b2Bucket = services.backup.backblaze.bucket;
              b2Enable = if services.backup.backblaze.enable then "true" else "false";
            };
          in
          {
            serviceConfig = {
              Type = "oneshot";
              User = "minecraft";
              Group = "minecraft";
              UMask = "0027";
              ExecStart = backupScript;
            };
            path = with pkgs; [
              bash
              borgbackup
              mcrcon
              rclone
              getent
            ];
          };
        timers.minecraft-backups = {
          wantedBy = [ "timers.target" ];
          partOf = [ "minecraft-backups.service" ];
          requires = [ "minecraft.service" ];
          timerConfig = {
            OnCalendar = services.backup.times;
          };
        };
      };
    };
}
