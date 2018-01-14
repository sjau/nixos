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
    assert mySecrets.user            != "";
    assert mySecrets.passwd          != "";
    assert mySecrets.hashedpasswd    != "";
    assert mySecrets.cifs            != "";
    assert mySecrets.hostname        != "";
    assert mySecrets.smbhome         != "";
    assert mySecrets.smboffice       != "";
    assert mySecrets.ibsuser         != "";
    assert mySecrets.ibspass         != "";
    assert mySecrets.ibsip           != "";

    # Wireguard
    ## Private Key
    assert mySecrets.wg_priv_key     != "";
    ## Home VPN
    assert mySecrets.wg_home_ips     != "";
    assert mySecrets.wg_home_allowed != "";
    assert mySecrets.wg_home_end     != "";
    assert mySecrets.wg_home_pubkey  != "";
    ## Office VPN
    assert mySecrets.wg_office_ips     != "";
    assert mySecrets.wg_office_allowed != "";
    assert mySecrets.wg_office_end     != "";
    assert mySecrets.wg_office_pubkey  != "";

{
    imports =
        [ # Include the results of the hardware scan.
        ./hardware-configuration.nix
        ];

    # Use latest kernel
    # See VirtualBox settings

    # Add more filesystems
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.enableUnstable = true;
#    boot.zfs.devNodes = "/dev";
    services.zfs.autoSnapshot = {
        enable = true;
        #frequent = 9; # keep the latest eight 15-minute snapshots (instead of four)
        #monthly = 1;  # keep only one monthly snapshot (instead of twelve)
    };
    services.zfs.autoScrub = {
        enable = true;
        interval = "daily";
        pools = [ ]; # List of ZFS pools to periodically scrub. If empty, all pools will be scrubbed.
    };
    # Limit ARC size to max. 4 GB, otherwise qemu is unhappy
#    boot.extraModprobeConfig = ''
#        options zfs zfs_arc_min=508185728
#        options zfs zfs_arc_min=4294967296
#    '';

    # Add memtest86
    boot.loader.grub.memtest86.enable = true;

    # Use the GRUB 2 boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    # Define on which hard drive you want to install Grub.
    boot.loader.grub.devices = [
        "/dev/disk/by-id/ata-Samsung_SSD_850_PRO_1TB_S2BBNWAHC23186P"
        "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_M.2_1TB_S33ENX0J201245E"
    ]; # or "nodev" for efi only


    # Load additional hardware stuff
    hardware = {
        # Hardware settings
#        cpu.intel.updateMicrocode = true;
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
#    ibs = makeServer {
#        remotefs = "${mySecrets.ibsip}";
#        userfs = "${mySecrets.ibsuser}";
#        passwordfs = "${mySecrets.ibspass}";
#        xsystemfs = "openvpn-ibs.service";
#        localfs = "/mnt/IBS";
#    };
    office = makeServer {
        remotefs = "${mySecrets.smboffice}";
        userfs = "none";
        passwordfs = "none";
        xsystemfs = "openvpn-j-l.service";
        localfs = "/mnt/jus-law";
    };
    in (builtins.listToAttrs (
        map home [ "Audio" "Shows" "SJ" "Video" "backup" "hyper" "eeePC" "rtorrent" ]
#        ++ map ibs [ "ARCHIV" "DATEN" "INDIGO" "LEAD" "VERWALTUNG" "SCAN" ]
        ++ [( office "Advo" )]))
    // {
        "/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
        "/var/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
    };

    # Create some folders
    system.activationScripts.media = ''
        mkdir -m 0755 -p /mnt/home/{Audio,Shows,SJ,Video,backup,eeePC,hyper,rtorrent}
        mkdir -m 0755 -p /mnt/ibs/{ARCHIV,DATEN,INDIGO,LEAD,VERWALTUNG,SCAN}
        mkdir -m 0755 -p /mnt/jus-law/Advo
    '';



    # Trust hydra. Needed for one-click installations.
    nix.trustedBinaryCaches = [ "http://hydra.nixos.org" ];

    # Setup networking
    networking = {
        # Disable IPv6
        enableIPv6 = false;
        hostName = "${mySecrets.hostname}"; # Define your hostname.
        hostId = "bac8c473";
        #  enable = true;  # Enables wireless. Disable when using network manager
        networkmanager.enable = true;
        firewall.allowPing = true;
        firewall.allowedUDPPorts = [ 5000 5001 21025 21026 22000 22026 ];
        firewall.allowedTCPPorts = [ 5000 5001 22000 ];
        # Netcat: 5000
        # IPerf: 5001
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
        consoleFont = "Lat2-Terminus16";
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
        videoDrivers = [ "intel" ];
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


    # Use KDE5 unstable
    nixpkgs.config.packageOverrides = super: let self = super.pkgs; in {
        plasma5_stable = self.plasma5_latest;
        kdeApps_stable = self.kdeApps_latest;
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
#    services.mysql = {
#        enable = true;
#        dataDir = "/var/mysql";
#        rootPassword = "${mySecrets.passwd}";
#        user = "mysql";
#        package = pkgs.mysql;
#        extraOptions = ''
#            log_error = /var/mysql/mysql_err.log
#            max_allowed_packet = 64M
#        '';
#    };


    # Enable Virtualbox
#    virtualisation.virtualbox.host.enable = true;
#    boot.kernelPackages = pkgs.linuxPackages_testing // {  # use bleeding edge kernel
    boot.kernelPackages = pkgs.linuxPackages_latest; # use latest kernel
#    boot.kernelPackages = pkgs.linuxPackages_latest // {  # use latest kernel
#    boot.kernelPackages = pkgs.linuxPackages // {
#        virtualbox = pkgs.linuxPackages.virtualbox.override {
#            enableExtensionPack = true;
#            pulseSupport = true;
#        };
#    };
#    nixpkgs.config.virtualbox.enableExtensionPack = true;


    # Enable Avahi for local domain resoltuion
    services.avahi = {
        enable = true;
        hostName = "${mySecrets.hostname}";
#        nssmdns = true;
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
#            "0 3,9,15,21 * * * root /root/fstrim.sh >> /tmp/fstrim.txt 2>&1"
            "0 2 * * * root /root/backup.sh >> /tmp/backup.txt 2>&1"
            "0 */6 * * * root /root/ssd_level_wear.sh >> /tmp/ssd_level_wear.txt 2>&1"
            "30 * * * * ${mySecrets.user} pass git pull"
            "40 * * * * ${mySecrets.user} pass git push"
            "*/5 * * * * root autoResilver 'tankSubi' 'usb-TOSHIBA_External_USB_3.0_20170612010552F-0:0, usb-TOSHIBA_External_USB_3.0_2012110725463-0:0'"
            "*/5 * * * * root wgStartFix 'wg_home wg_office'"
            "0 3,9,15,21 * * * root /root/zfs_all"      # Backup rp, ks and ns99
        ];
    };

    systemd.services.stopResilver = {
        description = "Stop Resilvering / Mirroring upon powering down";
        after = [ "zfs.target" ];
        wantedBy = [ "zfs.target" ];
#        wantedBy = [ "multi-user.target" ];
#        bindsTo = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            ExecStart = "/run/current-system/sw/bin/true";
            ExecStop = "/run/current-system/sw/bin/stopResilver 'tankSubi' 'usb-TOSHIBA_External_USB_3.0_20170612010552F-0:0 usb-TOSHIBA_External_USB_3.0_2012110725463-0:0'";
            RemainAfterExit = true;
        };
    };
    systemd.services.stopResilver.enable = true;


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
        extraGroups = [ "networkmanager" "vboxusers" "wheel" "audio" "cdrom" "kvm" "libvirtd" ]; # wheel is for the sudo group
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
            source-sans-pro
            source-code-pro
        ];
    };


    # Enable OpenVPN
    services.openvpn.servers = {
        h-b     = { config = '' config /root/.openvpn/h-b/SJ.conf ''; };
        j-l     = { config = '' config /root/.openvpn/j-l/client.conf ''; };
        ks      = { config = '' config /root/.openvpn/ks/subi.conf ''; };
        rp      = { config = '' config /root/.openvpn/rp/client.conf ''; };
        hme-lan = { config = '' config /root/.openvpn/home-lan/subi.conf ''; };
#        ibs     = { config = '' config /root/.openvpn/ibs/ibs.conf ''; };
    };


    # Enable Wireguard
    networking.wireguard.interfaces = {
        wg_home = {
            ips = [ "${mySecrets.wg_home_ips}" ];
            privateKey = "${mySecrets.wg_priv_key}";
            peers = [ {
                allowedIPs = [ "${mySecrets.wg_home_allowed}" ];
                endpoint = "${mySecrets.wg_home_end}";
                publicKey = "${mySecrets.wg_home_pubkey}";
                persistentKeepalive = 25;
            } ];
        };
        wg_office = {
            ips = [ "${mySecrets.wg_office_ips}" ];
            privateKey = "${mySecrets.wg_priv_key}";
            peers = [ {
                allowedIPs = [ "${mySecrets.wg_office_allowed}" ];
                endpoint = "${mySecrets.wg_office_end}";
                publicKey = "${mySecrets.wg_office_pubkey}";
                persistentKeepalive = 25;
            } ];
            postSetup = [
                # Set Nameserver
                #"/run/current-system/sw/bin/bash -c 'printf \"nameserver 10.20.10.1\" | /run/current-system/sw/bin/resolvconf -a wg_office -m 0'"
                # Set Route to WG-Server
                #"/run/current-system/sw/bin/bash -c 'remoteIP=$(getent servi.home.sjau.ch); remoteIP=${remoteIP% *}; echo "$remoteIP" /tmp/remIP.txt '"
            ];
            postShutdown = [
                # Remove Route to WG-Server
                #
                # Remove Nameserver
                #${pkgs.openresolv}/bin/resolvconf -d wg_office
            ];
        };
    };


    # Enable libvirtd daemon
    virtualisation.libvirtd = {
        enable = true;
#        enableKVM = true;
        qemuPackage = pkgs.qemu_kvm;
    };
    services.spice-vdagentd.enable = true;
    # Make smartcard reader and label printer accessible to everyone, so they can be passed to the VM
    services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="072f", ATTR{idProduct}=="90cc", GROUP="users", MODE="0777"
        SUBSYSTEM=="usb", ATTR{idVendor}=="04f9", ATTR{idProduct}=="2043", GROUP="users", MODE="0777"
    '';


    # Samba
    services.samba = {
        enable = true;
        securityType = "user";
        syncPasswordsByPam = true;  # Enabling this will add a line directly after pam_unix.so.
                                    # Whenever a password is changed the samba password will be updated as well.
                                    # However, you still have to add the samba password once, using smbpasswd -a user.
        extraConfig = ''
            server string = ${mySecrets.hostname}
            netbios name = ${mySecrets.hostname}
            workgroup = WORKGROUP
            socket options = TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE
            security = user
            name resolve order = hosts wins bcast
#            wins support = yes
            guest account = hyper
            map to guest = bad user
        '';
        shares = {
            Desktop = {
                path = "/home/hyper/Desktop";
                browseable = "yes";
                "read only" = "no";
                "create mask" = "0644";
                "directory mask" = "0755";
                "username" = "hyper";
            };
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
    system.stateVersion = "18.03";

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.chromium = {
        enablePepperFlash = true; # Chromium removed support for Mozilla (NPAPI) plugins so Adobe Flash no longer works 
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
        conkeror
        coreutils
        cryptsetup
        curl
        dcfldd # dd alternative that shows progress and can make different checksums on the fly
        dialog
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
        gptfdisk
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
        jpegoptim
        jq
        jre
# KDE 5
        ark
        dolphin
        kdenlive    frei0r  # frei0r provides transition effects
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
        lshw
        lsof
        lxqt.lximage-qt
        manpages
        mc
        mkpasswd
        mktorrent
        monodevelop
        mplayer
        mpv
        ms-sys
#         mupdf
        netcat-gnu
        nix-index
        nix-info
#        nix-index # provides nix-locate
        nix-repl # do:  :l <nixpkgs> to load the packages, then do qt5.m and hit tab twice
        nmap
        nox     # Easy search for packages
        nss
        nssTools
        ntfs3g
        opensc
        openssl
        openvpn
        palemoon
        parted
        (pass pkgs)
        patchelf
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
        pv
        python27Packages.youtube-dl
        psmisc
        pwgen
        qemu
        qt5Full
#        qtcreator
        qtpass
        quiterss
        recode
        recoll
        rfkill
        simplescreenrecorder
        smartmontools
        smplayer
        skype
        sox
        spice
        win-spice
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
        sysstat
        system_config_printer
        teamspeak_client
        tesseract
        thunderbird
        tmux
        unoconv
        unrar
        unzip
        usbutils
        virtmanager
        virt-viewer
        vlc
        wget
        which
        whois
        wine
        winetricks
        wireguard
        wireshark
        xpdf    # provides pdftotext
        zip
        # RNN
        torch
        torchPackages.luarocks
        python27
        python27Packages.cython
        python27Packages.numpy
        python27Packages.ConfigArgParse
        python27Packages.h5py
        python27Packages.six
        python27Packages.pytorch
        python27Packages.torchvision
        torch-hdf5
        torchPackages.cwrap
        torchPackages.paths
#        torchPackages.nn
#        torchPackages.nngraph
        torchPackages.optim
        python27Packages.pip
        python27Packages.setuptools
        cmake
        gcc

        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/pastesl/master/pastesl.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/pdfForts/master/pdfForts.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/jusLinkComposer/master/jusLinkComposer.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/master-pdf-editor.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/getTechDetails.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/autoResilver.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/stopResilver.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/freeCache.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/wgStartFix.nix") {})

        # wgDebug - needed for wg debugging
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/wgDebug.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/wgRouteAdd.nix") {})

        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/batchsigner.nix") {})
#        (python3Packages.callPackage /home/hyper/Desktop/git-repos/OCRmyPDF/ocrmypdf.nix {})
        (python3Packages.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/ocrmypdf.nix") {})

#        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/bennofs/nix-index/master/default.nix") {})

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
