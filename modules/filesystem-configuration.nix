{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/run/media/Files" = {
    device = "/dev/nvme0n1p4";
    fsType = "ntfs-3g";
    options = [ 
      "nofail" 
      "uid=1000" 
      "gid=100" 
      "rw" 
      "user"
      "umask=000" 
    ];
  };

  fileSystems."/run/media/Dev" = {
    device = "/dev/nvme0n1p5";
    fsType = "ntfs-3g";
    options = [ 
      "nofail" 
      "uid=1000" 
      "gid=100" 
      "rw" 
      "user"
      "umask=000"
    ];
  };
}