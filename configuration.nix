# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# All options for https://nixos.org/nixos/manual/ch-options.html

{ config, pkgs, ... }:

let
    myUser      = "hyper";
    myPwd       = "***";
    myCIFS      = "***";
    myHostName  = "subi";

#    myUser      = "${builtins.readFile /root/.nixos/myUser}";
#    myPwd       = "${builtins.readFile /root/.nixos/myPwd}";
#    myHostName  = "${builtins.readFile /root/.nixos/myHostName}";


in
    # Check if custom vars are set
    assert myUser       != "";
    assert myPwd        != "";
    assert myCIFS       != "";
    assert myHostName   != "";


{
    imports = [
        # Include the results of the hardware scan.
        ./hardware-configuration.nix
    ];

    # Use the GRUB 2 boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    # Define on which hard drive you want to install Grub.
    boot.loader.grub.device = "/dev/sda";

    boot.initrd.luks.devices = [{
                            # device = "/dev/disk/by-label/nixos";
        name = "crypto_root"; device = "/dev/disk/by-uuid/c6cb0b53-6ad1-425c-8ef8-71730fec9ce6";
    }];

    hardware = {
        # Hardware settings
        cpu.intel.updateMicrocode = true;
        enableAllFirmware = true;
        pulseaudio.enable = true;
        #pulseaudio.systemWide = true;
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
                    options = "noauto,user,uid=1000,gid=100,username=hyper,password=${myCIFS},iocharset=utf8,sec=ntlm";
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
        options = "noauto,user,uid=1000,gid=100,username=hyper,password=${myCIFS},iocharset=utf8,sec=ntlm";
    };
    fileSystems."/mnt/Shows" = {
        device = "//10.0.0.10/Shows";
        fsType = "cifs";
        options = "noauto,user,uid=1000,gid=100,username=hyper,password=${myCIFS},iocharset=utf8,sec=ntlm";
    };
    fileSystems."/mnt/SJ" = {
        device = "//10.0.0.10/SJ";
        fsType = "cifs";
        options = "noauto,user,uid=1000,gid=100,username=hyper,password=${myCIFS},iocharset=utf8,sec=ntlm";
    };
    fileSystems."/mnt/Video" = {
        device = "//10.0.0.10/Video";
        fsType = "cifs";
        options = "noauto,user,uid=1000,gid=100,username=hyper,password=${myCIFS},iocharset=utf8,sec=ntlm";
    };
    fileSystems."/mnt/backup" = {
        device = "//10.0.0.10/backup";
        fsType = "cifs";
        options = "noauto,user,uid=1000,gid=100,username=hyper,password=${myCIFS},iocharset=utf8,sec=ntlm";
    };
    fileSystems."/mnt/eeePC" = {
        device = "//10.0.0.10/eeePC";
        fsType = "cifs";
        options = "noauto,user,uid=1000,gid=100,username=hyper,password=${myCIFS},iocharset=utf8,sec=ntlm";
    };
    fileSystems."/mnt/hyper" = {
        device = "//10.0.0.10/hyper";
        fsType = "cifs";
        options = "noauto,user,uid=1000,gid=100,username=hyper,password=${myCIFS},iocharset=utf8,sec=ntlm";
    };
    fileSystems."/mnt/jus-law" = {
        device = "//vpn-data.jus-law.ch/Advo";
        fsType = "cifs";
        options = "noauto,user,uid=1000,gid=100,username=none,password=none,iocharset=utf8";
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
        hostName = "${myHostName}"; # Define your hostname.
        hostId = "bac8c473";
        #  enable = true;  # Enables wireless. Disable when using network manager
        networkmanager.enable = true;
        firewall.allowPing = true;
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
    # services.printing.enable = true;

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
                AutoLoginPass=${myPwd}
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
            date.timezone = "CET"
        '';
    };

    # Enable Virtualbox
    services.virtualboxHost.enable = true;
    nixpkgs.config.virtualbox.enableExtensionPack = true;

    # Enable Avahi for local domain resoltuion
    services.avahi = {
        enable = true;
        hostName = "${myHostName}";
        nssmdns = true;
        publishing = true;
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

    # Setuid
    security.setuidPrograms = [ "mount.cifs" ];

    # Enable sudo
    security.sudo = {
        enable = true;
        wheelNeedsPassword = true;
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.defaultUserShell = "/var/run/current-system/sw/bin/bash";
    users.extraUsers.${myUser} = {
        createHome = true;
        home = "/home/${myUser}";
        description = "${myUser}";
        isNormalUser = true;
        group = "users";
        extraGroups = [ "networkmanager" "vboxusers" "wheel" "audio" ]; # wheel is for the sudo group
        uid = 1000;
        useDefaultShell = true;
        password = "${myPwd}";
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
        ];
    };

    # Enable OpenVPN
    services.openvpn.enable = true;
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
            down = "umount /mnt/jus-law";
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

    # Enable btsync
    services.btsync = {
        enable = true;
        deviceName = "${myHostName}";
        enableWebUI = true;
        httpListenAddr = "127.0.0.1";
        httpLogin = "${myUser}";
        httpPass = "${myPwd}";
    };

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
    environment.systemPackages = with pkgs; [
        chromium
        cifs_utils
        filezilla
        firefox
        ghostscript
        gimp
        git
        gnome.gtk
        gnupg
        htop
        imagemagick
        iotop
        jdk
        jre
        jwhois
# KDE 4
        kde4.akonadi
        kde4.applications
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
        kde4.networkmanagement
        kde4.oxygen_icons
        kde4.kdeutils
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
        mplayer
        mumble
        mysql55
        nox     # Easy search for packages
        openvpn
        openssl
        oxygen-gtk2
        oxygen-gtk3
        pass
        pastebinit
        pdftk
#       plasma-theme-oxygen
        pinentry
        qt5Full
        qt5SDK
        qtpass
        recode
        recoll
#       rssowl2
        smartmontools
        smplayer
        skype
        sqlite
        stdenv # build-essential on nixos
        sudo
#       suisseid-pkcs11
        swt
        sysfsutils
        teamspeak_client
        thunderbird
        tmux
        unetbootin
        unoconv
        unzip
        vlc
        wget
        wine
        (pkgs.callPackage ./suisseid-pkcs11.nix {})
        (pkgs.callPackage ./swisssign-pin-entry.nix {})
#       (pkgs.callPackage ./swisssigner.nix {})
#       (pkgs.callPackage ./rssowl.nix {})
#   ] ++ ( builtins.filter pkgs.stdenv.lib.isDerivation (builtins.attrValues kdeApps_stable));
    ];

# suisseid-pkcs11 requires on ubuntu the following packages:
# fontconfig fontconfig-config fonts-dejavu-core libaudio2 libccid libfontconfig1 libice6 libjbig0 libjpeg-turbo8 libjpeg8 libqt-declarative
# libqt4-network libqt4-script libqt4-sql libqt4-xml libqt4-xmlpatterns libqt4core4 libqtdbus4 libqtgui4 libsm6 libtiff5 libxi6 libxrender1
# libxt6 pcscd qtcore4-l10n suisseid-pkcs11 swisssign-pin-entry x11-common


}
