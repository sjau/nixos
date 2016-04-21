# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# All options for https://nixos.org/nixos/manual/ch-options.html

{ config, pkgs, ... }:

let

    # Create file in import path looking like:   { user = 'username'; passwd = 'password'; cifs = 'cifspassword'; hostname = 'hostname'; }
    # This info is in a different file, so that the config can bit tracked by git without revealing sensitive infos. Feel free to expand
    mySecrets  = import /root/.nixos/mySecrets.nix;


in
    # Check if custom vars are set
    assert mySecrets.user       != "";
    assert mySecrets.passwd     != "";
    assert mySecrets.cifs       != "";
    assert mySecrets.hostname   != "";


{
    imports = [
        # Include the results of the hardware scan.
        ./hardware-configuration.nix
    ];

#    boot.kernelPackages = pkgs.linuxPackages_custom {
#        version = "4.3-rc5";
#        src = pkgs.fetchurl {
#            url = "https://cdn.kernel.org/pub/linux/kernel/v4.x/testing/linux-4.3-rc5.tar.xz";
#            sha256 = "7951dee001cc69e1eb851ba57e851ee880ea07056af059581d25893e1ebb9aec";
#        };
#        configfile = /etc/nixos/customKernel.config;
#    };

    # Use the GRUB 2 boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    # Define on which hard drive you want to install Grub.
    boot.loader.grub.device = "/dev/sda";

    boot.initrd.luks.devices = [{
                            # device = "/dev/disk/by-label/nixos";
        name = "crypto_root"; device = "/dev/disk/by-uuid/c6cb0b53-6ad1-425c-8ef8-71730fec9ce6";
        allowDiscards = true;
    }];

    hardware = {
        # Hardware settings
        cpu.intel.updateMicrocode = true;
        enableAllFirmware = true;
        pulseaudio.enable = true;
        #pulseaudio.systemWide = true;
        opengl.driSupport32Bit = true;  # Required for Steam
        pulseaudio.support32Bit = true; # Required for Steam
    };

/*
    fileSystems = {
        "/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
        "/var/log" = { device = "tmpfs" ; fsType = "tmpfs"; };
        "/var/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
    } //
        (let
            makeFileSystems = { name }: {
                inherit name;
                value = {
                    device = "//10.0.0.10/${name}";
                    fsType = "cifs";
                    options = "noauto,user,uid=1000,gid=100,username=hyper,password=${mySecrets.cifs},iocharset=utf8,sec=ntlm";
                };
            };
        in builtins.listToAttrs (map makeFileSystems [
               { name = "Audio"; }
               { name = "Shows"; }
               { name = "SJ"; }
               { name = "Video"; }
               { name = "backup"; }
               { name = "hyper"; }
               { name = "eeePC"; }
        ]));
*/


    fileSystems."/home/hyper/.cache" = { device = "tmpfs" ; fsType = "tmpfs"; };
    fileSystems."/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
    fileSystems."/var/log" = { device = "tmpfs" ; fsType = "tmpfs"; };
    fileSystems."/var/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };

    # CIFS
    fileSystems."/mnt/Audio" = {
        device = "//10.0.0.10/Audio";
        fsType = "cifs";
        options = [ "noauto" "user" "uid=1000" "gid=100" "username=hyper" "password=${mySecrets.cifs}" "iocharset=utf8" "sec=ntlm" ];
    };
    fileSystems."/mnt/Shows" = {
        device = "//10.0.0.10/Shows";
        fsType = "cifs";
        options = [ "noauto" "user" "uid=1000" "gid=100" "username=hyper" "password=${mySecrets.cifs}" "iocharset=utf8" "sec=ntlm" ];
    };
    fileSystems."/mnt/SJ" = {
        device = "//10.0.0.10/SJ";
        fsType = "cifs";
        options = [ "noauto" "user" "uid=1000" "gid=100" "username=hyper" "password=${mySecrets.cifs}" "iocharset=utf8" "sec=ntlm" ];
    };
    fileSystems."/mnt/Video" = {
        device = "//10.0.0.10/Video";
        fsType = "cifs";
        options = [ "noauto" "user" "uid=1000" "gid=100" "username=hyper" "password=${mySecrets.cifs}" "iocharset=utf8" "sec=ntlm" ];
    };
    fileSystems."/mnt/backup" = {
        device = "//10.0.0.10/backup";
        fsType = "cifs";
        options = [ "noauto" "user" "uid=1000" "gid=100" "username=hyper" "password=${mySecrets.cifs}" "iocharset=utf8" "sec=ntlm" ];
    };
    fileSystems."/mnt/eeePC" = {
        device = "//10.0.0.10/eeePC";
        fsType = "cifs";
        options = [ "noauto" "user" "uid=1000" "gid=100" "username=hyper" "password=${mySecrets.cifs}" "iocharset=utf8" "sec=ntlm" ];
    };
    fileSystems."/mnt/hyper" = {
        device = "//10.0.0.10/hyper";
        fsType = "cifs";
        options = [ "noauto" "user" "uid=1000" "gid=100" "username=hyper" "password=${mySecrets.cifs}" "iocharset=utf8" "sec=ntlm" ];
    };
    fileSystems."/mnt/jus-law" = {
        device = "//vpn-data.jus-law.ch/Advo";
        fsType = "cifs";
#        options = [ "noauto" "user" "uid=1000" "gid=100" "username=none" "password=none" "iocharset=utf8" "x-systemd.requires=openvpn-j-l.service" ];
        options = [ "noauto" "user" "uid=1000" "gid=100" "username=none" "password=none" "iocharset=utf8" ];
    };




    # Create some folders
    system.activationScripts.media = ''
        mkdir -m 0755 -p /mnt/Audio
        mkdir -m 0755 -p /mnt/Shows
        mkdir -m 0755 -p /mnt/SJ
        mkdir -m 0755 -p /mnt/Video
        mkdir -m 0755 -p /mnt/backup
        mkdir -m 0755 -p /mnt/eeePC
        mkdir -m 0755 -p /mnt/hyper
        mkdir -m 0755 -p /mnt/jus-law
    '';


    # Trust hydra. Needed for one-click installations.
    #nix.trustedBinaryCaches = [ "http://hydra.nixos.org" ];

    # Setup networking
    networking = {
        hostName = "${mySecrets.hostname}"; # Define your hostname.
        hostId = "bac8c473";
        #  enable = true;  # Enables wireless. Disable when using network manager
        networkmanager.enable = true;
        firewall.allowPing = true;
        firewall.allowedUDPPorts = [ 21025 21026 22000 22026 ];
        firewall.allowedTCPPorts = [ 22000 ];
        # Syncthing: 21025 21026 22000 22026
        extraHosts = ''
            127.0.0.1       ivwbox.de
            127.0.0.1       *.ivwbox.de
            127.0.0.1       *.webtrendslive.ch

            188.40.139.2    ns99
            10.8.0.8        ns
            176.9.139.175   hetzi manager.roleplayer.org # Hetzner EX4 Roleplayer
            10.8.0.97       scriptcase
            10.8.20.79      raspimam
            10.8.20.80      mam

            10.10.11.7      vpn-data.jus-law.ch

            81.4.108.20     juslawvpn
            176.31.121.75   kimsufi
        '';
    };
    
    # Make /etc/hosts writeable
    environment.etc."hosts".mode = "0644";

    # Enable dbus
    services.dbus.enable = true;

    # Select internationalisation properties.
    i18n = {
        consoleFont = "lat9w-16";
        consoleKeyMap = "sg-latin1";
        defaultLocale = "en_US.UTF-8";
    };


    # Enable the OpenSSH daemon.
    services.openssh = {
        enable = true;
        permitRootLogin = "yes";
    };

    # Enable CUPS to print documents.
    services.printing = {
        enable = true;
        drivers = [ pkgs.gutenprint pkgs.hplip ];
    };

    # Enable the X11 windowing system.
    services.xserver = {
        enable = true;
        layout = "ch";
        xkbOptions = "eurosign:e";
        synaptics = {
            enable = true;
        };

        # Enable the KDE Desktop Environment.
        displayManager.kdm = {
            enable = true;
            extraConfig = ''
                [X-:0-Core]
                AutoLoginEnable=true
                AutoLoginUser=hyper
                AutoLoginPass=${mySecrets.passwd}
            '';
        };
        desktopManager.kde4.enable = true;
        #desktopManager.kde5.enable = true;
        startGnuPGAgent = true;
    };
    # Need to deactivate because of gpg agent
    programs.ssh.startAgent = false;

    # Enable apache
    services.httpd = {
        enable = true;
        documentRoot = "/var/www/html";
        adminAddr = "admin@localhost";
        extraModules = [{
            name = "php5"; path = "${pkgs.php}/modules/libphp5.so";
        }];
        extraConfig = ''
            <Directory /var/www/html>
                DirectoryIndex index.php
                Require all granted
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
            date.timezone = "CET"
        '';
    };

    # Enable mysql
    services.mysql = {
        enable = true;
        dataDir = "/var/mysql";
        rootPassword = "${mySecrets.passwd}";
        user = "mysql";
        package = pkgs.mysql;
        extraOptions = ''
#            log_error = /var/mysql/mysql_err.log
            max_allowed_packet = 64M
        '';
    };

    # Enable Virtualbox
    virtualisation.virtualbox.host.enable = true;
    nixpkgs.config.virtualbox.enableExtensionPack = true;

#    nixpkgs.config = { 
#        virtualbox.enableExtensionPack = true;
#        packageOverrides = pkgs: rec { kde4.kdesdk_kioslaves = pkgs.stdenv.lib.overrideDerivation pkgs.kde4.kdesdk_kioslaves (oldAttrs: { buildInputs = with pkgs; [ kdelibs apr aprutil perl ]; }); };
#    };

    
    
    # Enable Avahi for local domain resoltuion
    services.avahi = {
        enable = true;
        hostName = "${mySecrets.hostname}";
        nssmdns = true;
#        publishing = true;
    };

    # Enable nscd
    services.nscd = {
        enable = true;
    };

    # Enable ntp
    services.ntp = {
        enable = true;
        servers = [ "0.ch.pool.ntp.org" "1.ch.pool.ntp.org" "2.ch.pool.ntp.org" "3.ch.pool.ntp.org" ];
    };

    # Enable cron
    services.cron = {
        enable = true;
        systemCronJobs = [
#            "0 3,9,15,21 * * * root /root/fstrim.sh >> /tmp/fstrim.txt 2>&1"
            "0 2 * * * root /root/backup.sh >> /tmp/backup.txt 2>&1"
            "0 */6 * * * root /root/ssd_level_wear.sh >> /tmp/ssd_level_wear.txt 2>&1"
            "10 * * * * hyper nice php -f /var/www/html/e/abc_spider.php >/dev/null 2>&1"
            "25 * * * * hyper nice php -f /var/www/html/e/ei_spider.php >/dev/null 2>&1"
            "40 * * * * hyper nice php -f /var/www/html/e/news_spider.php >/dev/null 2>&1"
            "55 * * * * hyper nice php -f /var/www/html/e/si_spider.php >/dev/null 2>&1"
        ];
    };
   
    # Enable Syslog
    #services.syslogd = {
    #    enable = true;
    #    tty = "9";
    #};
        
    # Setuid
    security.setuidPrograms = [ "mount.cifs" ];

    # Enable sudo
    security.sudo = {
        enable = true;
        wheelNeedsPassword = true;
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.defaultUserShell = "/var/run/current-system/sw/bin/bash";
    users.extraUsers.${mySecrets.user} = {
        createHome = true;
        home = "/home/${mySecrets.user}";
        description = "${mySecrets.user}";
        isNormalUser = true;
        group = "users";
        extraGroups = [ "networkmanager" "vboxusers" "wheel" "audio" ]; # wheel is for the sudo group
        uid = 1000;
        useDefaultShell = true;
        password = "${mySecrets.passwd}";
    };

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
            ubuntu_font_family
        ];
    };

    # Enable OpenVPN
#    services.openvpn.enable = true;
    services.openvpn.servers = {
        h-b = {
            config = ''
                config /root/.openvpn/h-b/SJ.conf
            '';
        };
        j-l = {
            config = ''
                config /root/.openvpn/j-l/client.conf
            '';
#            down = "umount /mnt/jus-law";
        };
        ks = {
            config = ''
                config /root/.openvpn/ks/subi.conf
            '';
        };
        rp = {
            config = ''
                config /root/.openvpn/rp/client.conf
            '';
        };
        home-lan = {
            config = ''
                config /root/.openvpn/home-lan/subi.conf
            '';
        };
    };

    # Enable smartmon daemon
    services.smartd = {
        enable = true;
        devices = [ { device = "/dev/sda"; } ];
    };

    # Enable smartcard daemon
    services.pcscd = {
        enable = true;
    };

    # Enable Syncthing
    services.syncthing = {
        enable = true;
        dataDir = "/home/hyper/Desktop/Syncthing";
        user = "${mySecrets.user}";
    };

    # Enable TOR
    # use systemctl stop tor to turn it off
    services.tor = {
        enable = true;
        client.enable = true;
        controlPort = 9051;
    };

    # Enable Locate
    services.locate.enable = true;

    # Time.
    time.timeZone = "Europe/Zurich";

    # Add the NixOS Manual on virtual console 8
    services.nixosManual.showManual = true;

    # Setup nano
    programs.nano.nanorc = ''
        set nowrap
        set tabstospaces
        set tabsize 4
        set const
        # include /usr/share/nano/sh.nanorc
    '';

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    nixpkgs.config.allowUnfree = true;
    #nixpkgs.config.firefox = {
    #        enableAdobeFlash = true;
    #};
    nixpkgs.config.chromium = {
        enablePepperFlash = true; # Chromium removed support for Mozilla (NPAPI) plugins so Adobe Flash no longer works 
    };

    environment.systemPackages = with pkgs; [
        androidsdk_4_4 # contains ADB
        aspell
        aspellDicts.de
        aspellDicts.en
        chromium
        cifs_utils
        cdrtools
        coreutils
        curl
        dcfldd # dd alternative that shows progress and can make different checksums on the fly
        ethtool
        fatrace
        filezilla
        firefoxWrapper
        ffmpeg
        gcc
        gdb
        ghostscript
        gimp
        git
        gnome.gtk
        gnome3.geary
        gnucash
        gnupg
        gparted
        hdparm
        htop
        icedtea8_web
        iftop
        imagemagick
        inkscape
        iotop
        jdk
        jre
        jwhois
# KDE 4
        kde4.akonadi
        kde4.applications
        kde4.k3b
#       kde4.kactivities
        kde4.kdeadmin
#       kde4.kdeartwork
        kde4.kdeaccessibility
        kde4.kdebase_workspace
        kde4.kdebindings
#       kde4.kdeedu
        kde4.kdegames
        kde4.kdegraphics
        kde4.kdelibs
        kde4.kdenetwork
        kde4.kdepim
        kde4.kdepim_runtime
        kde4.kdepimlibs
        kde4.kdesdk
#       kde4.kdetoys
        kde4.kdevelop
        kde4.kdevplatform
        kde4.kdewebdev
        kde4.kde_baseapps
        kde4.kde_base_artwork
        kde4.kde_wallpapers
        kde4.konversation
        kde4.kdemultimedia
        kde4.kdeplasma_addons
        kde4.kdeutils
        kde4.oxygen_icons
        kde4.plasma-nm
        kde4.print_manager
        kde4.ktorrent
# KDE 5
    #   kde5.ark
    #   kde5.kde-baseapps
    #   kde5.kate
    #   kde5.kdepim
    #   kde5.kdepimlibs
    #   kde5.kdepim-runtime
    #   kde5.ksnapshot
    #   kde5.kwallet
    #   kde5.okular
    #   kde5.oxygen
    #   kde5.oxygen-fonts
    #   kde5.oxygen-icons
    #   kde5.plasma-desktop
    #   kde5.plasma-nm
    #   kde5.plasma-workspace
        libreoffice
        lightning
        lsof
        mc
        monodevelop
        mplayer
        mumble
        mupdf
        nmap
        nix-repl # do:  :l <nixpkgs> to load the packages, then do qt5.m and hit tab twice
        nox     # Easy search for packages
        nss
        nssTools
        ntfs3g
        opensc
        openssl
        openvpn
        oxygen-gtk2
        oxygen-gtk3
        parted
        pass
        pastebinit
        pciutils
        pcsctools
        pdftk
#       plasma-theme-oxygen
        php     # PHP-Cli
        pinentry
        poppler_utils # provides command_not_found
        psmisc
        pwgen
        qt5Full
#        qt5SDK
        qtcreator
        qtpass
        recode
        recoll
#       rssowl2
        simplescreenrecorder
        smartmontools
        smplayer
        skype
        sox
        sqlite
        stdenv # build-essential on nixos
        steam
        subversion
        sudo
#       suisseid-pkcs11
        swt
        sylpheed
        syncthing
        sysfsutils
        system_config_printer
        teamspeak_client
        tesseract
        thunderbird
        tmux
        unetbootin
        unoconv
        unrar
        unzip
        usbutils
        vlc
        wget
        which
        wine
        winetricks
        xpdf    # provides pdftotext
        zip
        (pkgs.callPackage ./pastesl.nix {})
        (pkgs.callPackage ./pdfForts.nix {})
        (pkgs.callPackage ./quiterss.nix {})

#        (pkgs.callPackage ./localsigner.nix {})
#        (pkgs.callPackage ./suisseid-pkcs11.nix {})
#        (pkgs.callPackage ./swisssign-pin-entry.nix {})
#       (pkgs.callPackage ./swisssigner.nix {})
#   ] ++ ( builtins.filter pkgs.stdenv.lib.isDerivation (builtins.attrValues kdeApps_stable));
    ];

# suisseid-pkcs11 requires on ubuntu the following packages:
# fontconfig fontconfig-config fonts-dejavu-core libaudio2 libccid libfontconfig1 libice6 libjbig0 libjpeg-turbo8 libjpeg8 libqt-declarative
# libqt4-network libqt4-script libqt4-sql libqt4-xml libqt4-xmlpatterns libqt4core4 libqtdbus4 libqtgui4 libsm6 libtiff5 libxi6 libxrender1
# libxt6 pcscd qtcore4-l10n suisseid-pkcs11 swisssign-pin-entry x11-common


}
