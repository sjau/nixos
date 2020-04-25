# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "hid" "xhci_hcd" "xhci_pci" "ahci" "usb_storage" "usbhid" ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.kernelParams = [ "amdgpu.dc=1" ];
  boot.initrd.postDeviceCommands = "sleep 5; zpool import -a; zfs load-key -a";
#  boot.kernelParams = [ "zfs.zfs_arc_max=6442450944" "boot.debug1devices" ];
  boot.kernel.sysctl = { "vm.swappiness" = 20; "vm.dirty_ratio" = 10; "vm.dirty_background_ratio" = 1; };
#  boot.extraModulePackages = [ config.boot.kernelPackages.rtlwifi_new config.boot.kernelPackages.wireguard ];
#  boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ wireguard ];
  # Deactivate discreet optimus/nvidia card
#  boot.blacklistedKernelModules = [ "nouveau" ];

  fileSystems."/" =
    { device = "tankSubi/encZFS/Nixos";
      fsType = "zfs";
    };

  fileSystems."/home/hyper/.cache" =
    { device = "tankSubi/encZFS/Volatile/hyper.cache";
      fsType = "zfs";
    };

  fileSystems."/mnt/encZFS/Media" =
    { device = "tankSubi/encZFS/Media";
      fsType = "zfs";
    };

  fileSystems."/mnt/encZFS/Media/Anime" =
    { device = "tankSubi/encZFS/Media/Anime";
      fsType = "zfs";
    };

  fileSystems."/mnt/encZFS/Media/Shows" =
   { device = "tankSubi/encZFS/Media/Shows";
     fsType = "zfs";
   };

  fileSystems."/mnt/encZFS/VMs" =
    { device = "tankSubi/encZFS/VMs";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "tankSubi/encZFS/Volatile/tmp";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9bcbc94c-0cf5-4196-8743-30cff4da376a";
      fsType = "ext4";
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 8;
#  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
