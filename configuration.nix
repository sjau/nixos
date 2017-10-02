# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let

    # Create file in import path looking like:   { user = 'username'; passwd = 'password'; cifs = 'cifspassword'; hostname = 'hostname'; }
    # This info is in a different file, so that the config can bit tracked by git without revealing sensitive infos. Feel free to expand
    mySecrets  = import /root/.nixos/mySecrets.nix;

    pass = pkgs: pkgs.pass.override { gnupg = pkgs.gnupg; }; # or your gnupg version

in
    # Check if custom vars are set
    assert mySecrets.user           != "";
    assert mySecrets.passwd         != "";
    assert mySecrets.hashedpasswd   != "";
    assert mySecrets.cifs           != "";
    assert mySecrets.hostname       != "";
    assert mySecrets.smbhome        != "";
    assert mySecrets.smboffice      != "";
    assert mySecrets.ibsuser        != "";
    assert mySecrets.ibspass        != "";
    assert mySecrets.ibsip          != "";

{
    imports =
        [ # Include the results of the hardware scan.
        ./hardware-configuration.nix
        ];

    # Add more filesystems
    boot.supportedFilesystems = [ "zfs" ];

    # Use the GRUB 2 boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    # Define on which hard drive you want to install Grub.
    boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

    #LUKS Stuff in hardware-cofniguration.nix
    hardware = {
        # Hardware settings
        cpu.intel.updateMicrocode = true;
        enableAllFirmware = true;
        pulseaudio.enable = true;
        opengl.driSupport32Bit = true;  # Required for Steam
        pulseaudio.support32Bit = true; # Required for Steam
    };

    # Filsystem and remote dirs - thx to sphalerite, clever and Shados
    fileSystems = let 
    makeServer = { remotefs, userfs, passwordfs, xsystemfs, localfs }: name: {
        name = "${localfs}/${name}";
        value = {
            device = "//${remotefs}/${name}";
            fsType = "cifs";
            options = [ "noauto" "user" "uid=1000" "gid=100" "username=${userfs}" "password=${passwordfs}" "iocharset=utf8" "x-systemd.requires=${xsystemfs}" ];
        };
    };
    home = makeServer {
        remotefs = "${mySecrets.smbhome}";
        userfs = "${mySecrets.user}";
        passwordfs = "${mySecrets.cifs}";
        xsystemfs = "";
        localfs = "/mnt/home";
    };
    ibs = makeServer {
        remotefs = "${mySecrets.ibsip}";
        userfs = "${mySecrets.ibsuser}";
        passwordfs = "${mySecrets.ibspass}";
        xsystemfs = "openvpn-ibs.service";
        localfs = "/mnt/IBS";
    };
    office = makeServer {
        remotefs = "${mySecrets.smboffice}";
        userfs = "none";
        passwordfs = "none";
        xsystemfs = "openvpn-j-l.service";
        localfs = "/mnt/jus-law";
    };
    in (builtins.listToAttrs (
        map home [ "Audio" "Shows" "SJ" "Video" "backup" "hyper" "eeePC" "rtorrent" ]
        ++ map ibs [ "ARCHIV" "DATEN" "INDIGO" "LEAD" "VERWALTUNG" "SCAN" ]
        ++ [( office "Advo" )]))
    // {
        "/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
        "/var/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
    };

    # Create some folders
    system.activationScripts.media = ''
        mkdir -m 0755 -p /mnt/home
        mkdir -m 0755 -p /mnt/home/Audio
        mkdir -m 0755 -p /mnt/home/Shows
        mkdir -m 0755 -p /mnt/home/SJ
        mkdir -m 0755 -p /mnt/home/Video
        mkdir -m 0755 -p /mnt/home/backup
        mkdir -m 0755 -p /mnt/home/eeePC
        mkdir -m 0755 -p /mnt/home/hyper
        mkdir -m 0755 -p /mnt/home/rtorrent
        mkdir -m 0755 -p /mnt/jus-law
        mkdir -m 0755 -p /mnt/jus-law/Advo
    '';



    # Trust hydra. Needed for one-click installations.
    nix.trustedBinaryCaches = [ "http://hydra.nixos.org" ];

    # Setup networking
    networking = {
        hostName = "${mySecrets.hostname}"; # Define your hostname.
        hostId = "bac8c473";
        #  enable = true;  # Enables wireless. Disable when using network manager
        networkmanager.enable = true;
        firewall.allowPing = true;
        firewall.allowedUDPPorts = [ 5000 21025 21026 22000 22026 ];
        firewall.allowedTCPPorts = [ 5000 22000 ];
        # Syncthing: 21025 21026 22000 22026
        extraHosts = ''
            188.40.139.2    ns99
            10.8.0.8        ns
            176.9.139.175   hetzi manager.roleplayer.org # Hetzner EX4 Roleplayer
            10.8.0.97       scriptcase
            10.8.20.79      raspimam
            10.8.20.80      mam

            10.10.11.7      vpn-data.jus-law.ch

            81.4.108.20     juslawvpn
            176.31.121.75   kimsufi

            # Ad some custom blocking stuff
            127.0.0.1       ivwbox.de
            127.0.0.1       hyrekilo.club

            # Get ad server list from: https://pgl.yoyo.org/adservers/
            ${builtins.readFile (builtins.fetchurl { name = "blocked_hosts.txt"; url = "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"; })}
        '';
    };


    # Make /etc/hosts writeable
    #environment.etc."hosts".mode = "0644";

    # Enable dbus
    services.dbus.enable = true;

    # Select internationalisation properties.
    i18n = {
        consoleFont = "lat9w-16";
        consoleKeyMap = "sg-latin1";
        defaultLocale = "en_US.UTF-8";
    };


    # List services that you want to enable:


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
        displayManager.sddm = {
            enable = true;
            autoLogin = {
                enable = true;
                user = "${mySecrets.user}";
            };
        };
        desktopManager.plasma5.enable = true;
    };


    # Enable apache
    services.httpd = {
        enable = true;
        documentRoot = "/var/www/web";
        adminAddr = "admin@localhost";
        extraModules = [{
            name = "php7";
            path = "${pkgs.php}/modules/libphp7.so";
        }];
        extraConfig = ''
            <Directory /var/www/web>
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
    boot.kernelPackages = pkgs.linuxPackages // {
        virtualbox = pkgs.linuxPackages.virtualbox.override {
            enableExtensionPack = true;
            pulseSupport = true;
        };
    };
    nixpkgs.config.virtualbox.enableExtensionPack = true;


    # Enable KVM/Qemu
#    virtualisation.libvirtd = {
#        enable = true;
#        enableKVM = true;
#    };


    # Enable Avahi for local domain resoltuion
    services.avahi = {
        enable = true;
        hostName = "${mySecrets.hostname}";
        nssmdns = true;
    };


    # Enable nscd
    services.nscd = {
        enable = true;
    };

    # Enable ntp or rather timesyncd
    services.timesyncd = {
        enable = true;
        servers = [ "0.ch.pool.ntp.org" "1.ch.pool.ntp.org" "2.ch.pool.ntp.org" "3.ch.pool.ntp.org" ];
    };


    # Enable cron
    services.cron = {
        enable = true;
        systemCronJobs = [
            "0 3,9,15,21 * * * root /root/fstrim.sh >> /tmp/fstrim.txt 2>&1"
            "0 2 * * * root /root/backup.sh >> /tmp/backup.txt 2>&1"
            "0 */6 * * * root /root/ssd_level_wear.sh >> /tmp/ssd_level_wear.txt 2>&1"
            "30 * * * * ${mySecrets.user} pass git pull"
            "40 * * * * ${mySecrets.user} pass git push"
        ];
    };


    # Setuid
    security.wrappers."mount.cifs".source = "${pkgs.cifs-utils}/bin/mount.cifs";
    security.wrappers."cdrecord".source = "${pkgs.cdrtools}/bin/cdrecord";


    # Enable sudo
    security.sudo = {
        enable = true;
        wheelNeedsPassword = true;
    };


    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.defaultUserShell = "/var/run/current-system/sw/bin/bash";
    users.extraUsers.${mySecrets.user} = {
        isNormalUser = true;    # creates home, adds to group users, sets default shell
        description = "${mySecrets.user}";
        extraGroups = [ "networkmanager" "vboxusers" "wheel" "audio" "cdrom" "kvm" ]; # wheel is for the sudo group
        uid = 1000;
        initialHashedPassword = "${mySecrets.hashedpasswd}";
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
    services.openvpn.servers = {
        h-b     = { config = '' config /root/.openvpn/h-b/SJ.conf ''; };
        j-l     = { config = '' config /root/.openvpn/j-l/client.conf ''; };
        ks      = { config = '' config /root/.openvpn/ks/subi.conf ''; };
        rp      = { config = '' config /root/.openvpn/rp/client.conf ''; };
        hme-lan = { config = '' config /root/.openvpn/home-lan/subi.conf ''; };
        ibs     = { config = '' config /root/.openvpn/ibs/ibs.conf ''; };
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
        dataDir = "/home/${mySecrets.user}/Desktop/Syncthing";
        user = "${mySecrets.user}";
    };


    # Enable TOR
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


    # The NixOS release to be compatible with for stateful data such as databases.
    # It will e.g. upgrade databases to newer versions and that can't be reverted by Nixos.
    system.stateVersion = "17.09";

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.chromium = {
        enablePepperFlash = true; # Chromium removed support for Mozilla (NPAPI) plugins so Adobe Flash no longer works 
    };

    # Use KDE5 unstable
    nixpkgs.config.packageOverrides = super: let self = super.pkgs; in {
        plasma5_stable = self.plasma5_latest;
        kdeApps_stable = self.kdeApps_latest;
    };


    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    # List of packages that gets installed....
    environment.systemPackages = with pkgs; [
        androidenv.platformTools # contains ADB
        aspell
        aspellDicts.de
        aspellDicts.en
        audacity
        bash-completion
        chromium
        cifs_utils
        cdrtools
        coreutils
        curl
        dcfldd # dd alternative that shows progress and can make different checksums on the fly
        dos2unix
        enca
        ethtool
        exfat
        fatrace
        file
        filezilla
        firefoxWrapper
        ffmpeg
        foo2zjs			# Printer drivers for Oki -> http://foo2hiperc.rkkda.com/
        foomatic-filters
        gcc
        gdb
        ghostscript
        gimp
        git
        gksu
        gnome3.dconf
        gnome3.dconf-editor
        gnome3.zenity
        gnupg		# GnuPG 2 -> provides gpg2 binary
        gparted
        gwenview
        hdparm
        htop
        icedtea8_web
        iftop
        imagemagick
#        inetutils  # problems with whois, so use iputils and whois instead
        inkscape
        iosevka
        iotop
        iperf
        iputils
        jdk
        jq
        jre
# KDE 5
        ark
        dolphin
        kdeFrameworks.kdesu
        kdevelop
        k3b
        kate
        kcalc
        konversation
        ktorrent
        okular
        oxygen
        oxygen-icons5
        oxygenfonts
        plasma-desktop
        plasma-nm
        plasma-workspace
        spectacle # KSnapShot replacement for KDE 5
# End of KDE 5
        kvm
        libreoffice
        libuchardet
        lightning
        links
        lsof
        lxqt.lximage-qt
        mc
        mkpasswd
        mktorrent
        monodevelop
        mplayer
        mpv
        ms-sys
        mumble
        mupdf
        netcat-gnu
        nmap
        nix-repl # do:  :l <nixpkgs> to load the packages, then do qt5.m and hit tab twice
        nox     # Easy search for packages
        nss
        nssTools
        ntfs3g
        opensc
        openssl
        openvpn
        parted
        (pass pkgs)
        pavucontrol
        pciutils
        pcsctools
        pdftk
        pgadmin
        php     # PHP-Cli
        pinentry
        pinentry_qt4
        playonlinux
        poppler_utils # provides command_not_found
        python27Packages.youtube-dl
        psmisc
        pwgen
        qt5Full
#        qtcreator
        qtpass
        quiterss
        recode
        recoll
        smartmontools
        smplayer
        skype
        sox
        sqlite
        sqlitebrowser
        sshpass
        stdenv # build-essential on nixos
#        steam
        subversion
        sudo
#       suisseid-pkcs11
        swt
        sylpheed
        syncthing
        sysfsutils
        system_config_printer
        teamspeak_client
        teamviewer
        tesseract
        thunderbird
        tmux
        unetbootin
        unoconv
        unrar
        unzip
        usbutils
#        virt-viewer
#        virtmanager
#        virtmanager-qt
        vlc
        wget
        which
        whois
        wine
        winetricks
        wireshark
        xpdf    # provides pdftotext
        zip
#        (pkgs.callPackage /home/hyper/Desktop/git-repos/pastesl/pastesl.nix {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/pastesl/master/pastesl.nix") {})
#        (pkgs.callPackage /home/hyper/Desktop/git-repos/pdfForts/pdfForts.nix {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/pdfForts/master/pdfForts.nix") {})
#        (pkgs.callPackage /home/hyper/Desktop/git-repos/jusLinkComposer/jusLinkComposer.nix {})        
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/jusLinkComposer/master/jusLinkComposer.nix") {})
        # Master PDF Editor
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/master-pdf-editor.nix") {})
        # getTechDetails script for collecting the tech details when bug reporting
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/getTechDetails.nix") {})

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
