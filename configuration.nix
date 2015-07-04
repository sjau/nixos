# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda";

  boot.initrd.luks.devices = [
    {
      name = "crypto_root"; device = "/dev/disk/by-uuid/3d8128bc-834e-4403-9339-e166a7c534b6";
    }
  ];

  fileSystems."/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
  fileSystems."/var/log" = { device = "tmpfs" ; fsType = "tmpfs"; };
  fileSystems."/var/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };


  # Trust hydra. Needed for one-click installations.
  nix.trustedBinaryCaches = [ "http://hydra.nixos.org" ];

  networking.hostName = "nixi"; # Define your hostname.
  networking.hostId = "bac8c473";
  # networking.wireless.enable = true;  # Enables wireless.
  networking.networkmanager.enable = true;
  services.dbus.enable = true;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "lat9w-16";
    consoleKeyMap = "sg-latin1";
    defaultLocale = "en_US.UTF-8";
  };


  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "ch";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.kdm.enable = true;
  services.xserver.desktopManager.kde4.enable = true;

  # Install apache
  services.httpd = {
    enable = true;
    documentRoot = "/var/www/html";
    adminAddr = "admin@localhost";
    extraModules = [
      { name = "php5"; path = "${pkgs.php}/modules/libphp5.so"; }
    ];
    extraConfig = ''
      <Directory /var/www/html>
        DirectoryIndex index.php
        Order deny,allow
        Allow from *
      </Directory>
    '';
    # PHP
    enablePHP = true;
    phpOptions = ''
        max_execution_time = 3000
        max_input_time = 600
        memory_limit = 1280M
        post_max_size = 800M
        upload_max_filesize = 200M
        session.gc_maxlifetime = 144000
    '';
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.extraUsers.guest = {
  #   isNormalUser = true;
  #   uid = 1000;
  # };
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = "/var/run/current-system/sw/bin/bash";
  users.extraUsers.hyper = {
    createHome = true;
    home = "/home/hyper";
    description = "hyper";
    isNormalUser = true;
    group = "users";
    extraGroups = [ "networkmanager" "vboxusers" ];
    uid = 1000;
    useDefaultShell = true;
  };
  fileSystems."/home/hyper/.cache" = { device = "tmpfs" ; fsType = "tmpfs"; };

  fonts = {
    enableFontDir = true;
    enableCoreFonts = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs ; [
      liberation_ttf
      ttf_bitstream_vera
      dejavu_fonts
      terminus_font
      bakoma_ttf
      clearlyU
      cm_unicode
      andagii
      bakoma_ttf
      inconsolata
      gentium
    ];
  };

  # SMART.
  services.smartd.enable = true;
  services.smartd.devices = [ { device = "/dev/sda"; } ];

  # Time.
  time.timeZone = "Europe/Zurich";

  # Add the NixOS Manual on virtual console 8
  services.nixosManual.showManual = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
#    build-essential
    chromium
    cifs_utils
    filezilla
    ghostscript
    gimp
    git
    htop
    imagemagick
    iotop
    kde4.kdepim
    kde4.konversation
    kde4.networkmanagement
    kde4.oxygen_icons
    libreoffice
    mc
#    mysql-client
#    mysql-server
    nox
    openvpn
    oxygen-gtk2
    oxygen-gtk3
    pass
    pastebinit
    pdftk
#    php5
#    php5-curl
#    php5-mysql
#    plasma-theme-oxygen
#    qt5-default
#    qt5-qmake
#    qtbase5-dev-tools
    qt5Full
    recoll
#    rssowl2
    smartmontools
    smplayer
    skype
    sysfsutils
    sudo
#    suisseid-pkcs11
    tmux
    unetbootin
    unoconv
#    usb-creator-kde
#    virtualbox
    vlc
    wget
#    whois
  ];

}
