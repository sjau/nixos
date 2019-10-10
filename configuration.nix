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

    # Auth SSH Key
    assert mySecrets.auth_ssh_key1      != "";
    assert mySecrets.auth_ssh_key2      != "";

    assert mySecrets.user               != "";
    assert mySecrets.passwd             != "";
    assert mySecrets.hashedpasswd       != "";
    assert mySecrets.cifs               != "";
    assert mySecrets.hostname           != "";
    assert mySecrets.smbhome            != "";
    assert mySecrets.smboffice          != "";
    assert mySecrets.ibsuser            != "";
    assert mySecrets.ibspass            != "";
    assert mySecrets.ibsip              != "";

    # Wireguard
    ## Private Key
    assert mySecrets.wg_priv_key        != "";
    ## Home VPN
    assert mySecrets.wg_home_ips        != "";
    assert mySecrets.wg_home_allowed    != "";
    assert mySecrets.wg_home_end        != "";
    assert mySecrets.wg_home_pubkey     != "";
    ## Jus-Law VPN
    assert mySecrets.wg_jl_ips          != "";
    assert mySecrets.wg_jl_allowed      != "";
    assert mySecrets.wg_jl_end          != "";
    assert mySecrets.wg_jl_pubkey       != "";
    ## h&b Data VPN
    assert mySecrets.wg_hb_ips          != "";
    assert mySecrets.wg_hb_allowed      != "";
    assert mySecrets.wg_hb_end          != "";
    assert mySecrets.wg_hb_pubkey       != "";
    # ONS
    assert mySecrets.wg_ons_ips         != "";
    assert mySecrets.wg_ons_allowed     != "";
    assert mySecrets.wg_ons_end         != "";
    assert mySecrets.wg_ons_pubkey      != "";

    # SSMTP
    assert mySecrets.ssmtp_mailto       != "";
    assert mySecrets.ssmtp_user         != "";
    assert mySecrets.ssmtp_pass         != "";
    assert mySecrets.ssmtp_host         != "";
    assert mySecrets.ssmtp_domain       != "";
    assert mySecrets.ssmtp_root         != "";


{
    imports =
        [   # Include the results of the hardware scan.
            ./hardware-configuration.nix
            # Fix DisplayLink: see https://gist.github.com/eyJhb/b44a6de738965a3e895f456be2683b50  https://github.com/NixOS/nixpkgs/issues/62871
            /root/DisplayLink/displaylink.nix
        ];

    # Use latest kernel
    # See VirtualBox settings

    # Add more filesystems
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.enableUnstable = true;
    services.zfs.autoScrub = {
        enable = true;
        interval = "monthly";
        pools = [ ]; # List of ZFS pools to periodically scrub. If empty, all pools will be scrubbed.
    };

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

    # Remote ZFS Unlock
    boot.initrd.network = {
        enable = true;
        ssh = {
            enable = true;
            port = 2222;
            hostECDSAKey = /root/initrd-ssh-key;
            authorizedKeys = [ "${mySecrets.auth_ssh_key1}" "${mySecrets.auth_ssh_key2}" ];
        };
        postCommands = ''
            echo "zfs load-key -a; killall zfs" >> /root.profile
        '';
    };
    boot.initrd.kernelModules = [ "r8169" "cdc_ncm" "xhci_hcd" "usbnet" "intel_xhci_usb_role_switch" "usbcore" "usb_common" ];
#    boot.kernelParams = [ "ip=dhcp" ];
        

    # Clean /tmp at boot
    boot.cleanTmpDir = true;


    # Load additional hardware stuff
    hardware = {
        # Hardware settings
        cpu.intel.updateMicrocode = true;
        enableAllFirmware = true;
        pulseaudio.enable = true;
        pulseaudio.package = pkgs.pulseaudioFull;
        opengl.driSupport32Bit = true;  # Required for Steam
        pulseaudio.support32Bit = true; # Required for Steam
        bluetooth.enable = true;
    };

    # Filsystem and remote dirs - thx to sphalerite, clever and Shados
    fileSystems = let 
    makeServer = { remotefs, userfs, passwordfs, xsystemfs, localfs }: name: {
        name = "${localfs}/${name}";
        value = {
            device = "//${remotefs}/${name}";
            fsType = "cifs";
#            options = [ "noauto" "user" "uid=1000" "gid=100" "username=${userfs}" "password=${passwordfs}" "iocharset=utf8" "x-systemd.requires=${xsystemfs}" ];
            options = [ "noauto" "user" "uid=1000" "gid=100" "username=${userfs}" "password=${passwordfs}" "iocharset=utf8" "x-systemd.automount" "x-systemd.idle-timeout=60" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s" ];
        };
    };
    home = makeServer {
        remotefs = "${mySecrets.smbhome}";
        userfs = "${mySecrets.user}";
        passwordfs = "${mySecrets.cifs}";
        xsystemfs = "wireguard-wg_home.service";
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
        xsystemfs = "wireguard-wg_jl.service";
        localfs = "/mnt/jus-law";
    };
    in (builtins.listToAttrs (
        map home [ "Audio" "Shows" "Video" "hyper" "Plex" ]
#        ++ map ibs [ "ARCHIV" "DATEN" "INDIGO" "LEAD" "VERWALTUNG" "SCAN" ]
        ++ [( office "Advo" )]))
    // {
#        "/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
        "/var/tmp" = { device = "tmpfs" ; fsType = "tmpfs"; };
    };

    # Create some folders
    system.activationScripts.media = ''
        mkdir -m 0755 -p /mnt/home/{Audio,Shows,SJ,Video,backup,eeePC,hyper,rtorrent,Plex}
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
        useDHCP = true;
        firewall.allowPing = true;
        firewall.allowedUDPPorts = [ 2222 5000 5001 21025 21026 21027 22000 22026 5959 45000 8384 5900 ];
        firewall.allowedTCPPorts = [ 2222 5000 5001 21027 22000 5959 45000 6080 8384 5900 ];
        # Early SSH / initrd
        # Netcat: 5000
        # IPerf: 5001
        # Syncthing: 21025 21026 21027 22000 22026 - WUI: 8384
        # SPICE/VNC: 5900
        # WebSockify: 5959
        # nginx: 4500
        extraHosts = ''
            188.40.139.2    ns99
            10.8.0.8        ns
            176.9.139.175   hetzi manager.roleplayer.org # Hetzner EX4 Roleplayer
            10.8.0.97       scriptcase
            10.8.20.79      raspimam
            10.8.20.80      mam

            127.0.0.1       subi.home.sjau.ch subi
            10.10.11.7      vpn-data.jus-law.ch
            10.10.20.7      wg-data.jus-law.ch

            10.100.200.7    vpn-data.heer-baumgartner.ch

            176.31.121.75   kimsufi ks.jus-law.ch
            51.15.190.68    ons ons.jus-law.ch

            # Get Ad/Tracking server list from https://github.com/sjau/adstop
            ${builtins.readFile (builtins.fetchurl { name = "blocked_hosts.txt"; url = "https://raw.githubusercontent.com/sjau/adstop/master/hosts"; })}
            0.0.0.0       protectedinfoext.biz
        '';
    };

# ${builtins.readFile (builtins.fetchurl { name = "blocked_hosts.txt"; url = "https://raw.githubusercontent.com/sjau/adstop/master/hosts"; })}

    # Resolved - DNS Server
#    services.resolved = {
#        enable = true;
#        fallbackDns = [ "10.0.0.1" "10.10.10.1" "10.100.100.1" "8.8.4.4" "8.8.8.8" ];
#    };


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
        videoDrivers = [ "intel" "modesetting" "displaylink" ];
#        videoDrivers = [ "intel" "modesetting" ];
        layout = "ch";
        xkbOptions = "eurosign:e";
        synaptics = {
            enable = false;
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


    # Setup a "sendmail"
    networking.defaultMailServer = {
        directDelivery = true;
        authUser = "${mySecrets.ssmtp_user}";
        authPass = "${mySecrets.ssmtp_pass}";
        hostName = "${mySecrets.ssmtp_host}";
        domain = "${mySecrets.ssmtp_domain}";
        root = "${mySecrets.ssmtp_root}";
        useSTARTTLS = true;
        useTLS = true;
    };


    # Enable apache
    services.httpd = {
        enable = false;
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

#    services.networking.websockify = {
#        enable = true;
#        sslCert = "/https-cert.pem";
#        sslKey = "/https-key.pem";
#        portMap = {
#            "5959" = 5900;
#        };
#    };

    services.nginx = {
        enable = true;
        virtualHosts."subi.home.sjau.ch" = {
            forceSSL = true;
            root = "/var/www/";
            locations."/spice/" = {
                index = "index.php index.html index.htm spice.html";
            };
            locations."/websockify/" = {
                proxyWebsockets = true;
                proxyPass = "https://127.0.0.1:5959";
                extraConfig = ''
                    # VNC connection timeout
                    proxy_read_timeout 61s;

                    # Disable cache
                    proxy_buffering off;
                '';
            };
            sslCertificate = "/https-cert.pem";
            sslCertificateKey = "/https-key.pem";
            listen =[ { addr = "*"; port = 45000; ssl = true; } ];
        };
    };
    services.phpfpm.pools = {
        mypool = {
            listen = "127.0.0.1:9000";
            phpPackage = pkgs.php;
            user = "nobody";
            extraConfig = ''
                pm = dynamic
                pm.max_children = 5
                pm.start_servers = 2
                pm.min_spare_servers = 1
                pm.max_spare_servers = 3
                pm.max_requests = 500
            '';
        };
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
#    virtualisation.virtualbox = {
#        host = {
#            enable = true;
#            enableExtensionPack = true;
#        };
#        guest.enable = true;
#    };
    boot = {
        kernelPackages = pkgs.linuxPackages_latest;
    };


    # Enable Docker
    virtualisation.docker = {
        enable = true;
    };

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

    # Custom files in /etc
    environment.etc = {
        "easysnap/easysnap.hourly".text = ''
            # Format: local ds ; local encryption ds ; raw sending ; intermediay sending; export pool; remote user@host ; remote ds ; number of snapshots ; free disk warning

            # Servi
            tankServers/encZFS/home-server/Nixos;tankServers/encZFS;;y;y;root@10.200.0.1;tankServi/encZFS/Nixos;4380;200
            tankServers/encZFS/home-server/Media;tankServers/encZFS;;y;y;root@10.200.0.1;tankServi/encZFS/Media;4380;200
            tankMediaBU/encZFS/Plex;tankMediaBU/encZFS;;y;y;root@servi.home.sjau.ch;tankMedia/encZFS/Plex;4380;100

            # Remote Servers
            tankServers/encZFS/online-net-server;tankServers/encZFS;;y;y;root@ons.jus-law.ch;tankOnline/encZFS/Nixos;4380;200
            tankServers/encZFS/ovh-cloud-ssd-server;tankServers/encZFS;;y;y;root@ov.jus-law.ch;tankOVH/encZFS/Nixos;4380;200

            # Roleplayer Server
            tankServers/encZFS/roleplayer-server/Debian;;;y;y;root@ispc.roleplayer.org;tankRP/Debian;2190;200
            tankServers/encZFS/roleplayer-server/Debian/home;;;y;y;root@ispc.roleplayer.org;tankRP/Debian/home;2190;200
            tankServers/encZFS/roleplayer-server/Debian/var;;;y;y;root@ispc.roleplayer.org;tankRP/Debian/var;2190;200
            tankServers/encZFS/roleplayer-server/Debian/var/vmail;;;y;y;root@ispc.roleplayer.org;tankRP/Debian/var/vmail;2190;200
            tankServers/encZFS/roleplayer-server/Debian/var/www;;;y;y;root@ispc.roleplayer.org;tankRP/Debian/var/www;2190;200
            tankServers/encZFS/roleplayer-server/manager.roleplayer.org;;;y;y;root@ispc.roleplayer.org;tankRP/manager.roleplayer.org;2190;200
        '';
        "easysnap/easysnap.hourly".mode = "0644";
        # Make /etc/hosts writeable
        "hosts".mode = "0644";
    };

    # Enable cron
    services.cron = {
        enable = true;
        mailto = "${mySecrets.ssmtp_mailto}";
        systemCronJobs = [
            # Make sure network card is set to 1gpbs
            "*/5 * * * *    root    ethtool -s enp2s0f1 autoneg on"
            # Run ZFS Trim every night
            "1 23 * * *     root    zpool trim tankSubi"
#            "0 3,9,15,21 * * * root /root/fstrim.sh >> /tmp/fstrim.txt 2>&1"
            "0 2 * * *      root    /root/backup.sh >> /tmp/backup.txt 2>&1"
            "0 */6 * * *    root    /root/ssd_level_wear.sh >> /tmp/ssd_level_wear.txt 2>&1"
            "30 * * * *     ${mySecrets.user}   pass git pull > /dev/null 2>&1"
            "40 * * * *     ${mySecrets.user}   pass git push > /dev/null 2>&1"
            "*/5 * * * *    root    autoResilver 'tankSubi' 'usb-TOSHIBA_External_USB_3.0_20170612010552F-0:0'"
            "*/5 22-03 * * * root   autoResilver 'tankSubi' 'usb-TOSHIBA_External_USB_3.0_2012110725463-0:0'"
            "25 4 * * *     root    stopResilver 'tankSubi' 'usb-TOSHIBA_External_USB_3.0_20170612010552F-0:0 usb-TOSHIBA_External_USB_3.0_2012110725463-0:0'"
            "3 0 * * *      root    '/root/.acme.sh/acme.sh' --cron --home '/root/.acme.sh' > /dev/null"
            ### Easy Snap
            "*/15 * * * *   root    /home/hyper/Desktop/git-repos/easysnap/easysnap frequent"
            "0 * * * *      root    /home/hyper/Desktop/git-repos/easysnap/easysnap hourly"
            "0 0 * * *      root    /home/hyper/Desktop/git-repos/easysnap/easysnap daily"
            "0 0 * * 1      root    /home/hyper/Desktop/git-repos/easysnap/easysnap weekly"
            "0 0 1 * *      root    /home/hyper/Desktop/git-repos/easysnap/easysnap monthly"
            "35 * * * *     root    /home/hyper/Desktop/git-repos/easysnap/easysnapRecv hourly"
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

    
#    systemd.services.wireguard-wg_home.serviceConfig.Restart = "on-failure";
#    systemd.services.wireguard-wg_home.serviceConfig.RestartSec = "5s";
#    systemd.services.wireguard-wg_jl.serviceConfig.Restart = "on-failure";
#    systemd.services.wireguard-wg_jl.serviceConfig.RestartSec = "5s";
#    systemd.services.wireguard-wg_ons.serviceConfig.Restart = "on-failure";
#    systemd.services.wireguard-wg_ons.serviceConfig.RestartSec = "5s";
    

    # Setuid
    security.wrappers."mount.cifs".source = "${pkgs.cifs-utils}/bin/mount.cifs";
    security.wrappers."cdrecord".source = "${pkgs.cdrtools}/bin/cdrecord";
    security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice_gtk}/bin/spice-client-glib-usb-acl-helper.real";

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
        extraGroups = [ "networkmanager" "vboxusers" "wheel" "audio" "cdrom" "kvm" "libvirtd" "adbusers" "docker" ]; # wheel is for the sudo group
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
#    services.openvpn.servers = {
#        h-b     = { config = '' config /root/.openvpn/h-b/SJ.conf ''; };
#        j-l     = { config = '' config /root/.openvpn/j-l/client.conf ''; };
#        ks      = { config = '' config /root/.openvpn/ks/subi.conf ''; };
#        rp      = { config = '' config /root/.openvpn/rp/client.conf ''; };
#        hme-lan = { config = '' config /root/.openvpn/home-lan/subi.conf ''; };
#        ibs     = { config = '' config /root/.openvpn/ibs/ibs.conf ''; };
#    };


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
        wg_ons = {
            ips = [ "${mySecrets.wg_ons_ips}" ];
            privateKey = "${mySecrets.wg_priv_key}";
            peers = [ {
                allowedIPs = [ "${mySecrets.wg_ons_allowed}" ];
                endpoint = "${mySecrets.wg_ons_end}";
                publicKey = "${mySecrets.wg_ons_pubkey}";
                persistentKeepalive = 25;
            } ];
        };
        wg_jl = {
            ips = [ "${mySecrets.wg_jl_ips}" ];
            privateKey = "${mySecrets.wg_priv_key}";
            peers = [ {
                allowedIPs = [ "${mySecrets.wg_jl_allowed}" ];
                endpoint = "${mySecrets.wg_jl_end}";
                publicKey = "${mySecrets.wg_jl_pubkey}";
                persistentKeepalive = 25;
            } ];
        };
        wg_hb = {
            ips = [ "${mySecrets.wg_hb_ips}" ];
            privateKey = "${mySecrets.wg_priv_key}";
            peers = [ {
                allowedIPs = [ "${mySecrets.wg_hb_allowed}" ];
                endpoint = "${mySecrets.wg_hb_end}";
                publicKey = "${mySecrets.wg_hb_pubkey}";
                persistentKeepalive = 25;
            } ];
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
        KERNEL=="zd*", SUBSYSTEM=="block", GROUP="users", MODE="0660"
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
#            name resolve order = hosts wins bcast
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
        configDir = "/home/${mySecrets.user}/.config/syncthing";
        user = "${mySecrets.user}";
        openDefaultPorts = true;
        guiAddress = "0.0.0.0:8384";
    };


    # Enable TOR
    services.tor = {
        enable = true;
        client.enable = true;
        controlPort = 9051;
    };


    # Enable sysstat
    services.sysstat = {
        enable = true;
    };

    # Enable Locate
    services.locate = {
        enable = true;
        prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/mnt/home" "/mnt/ibs" "/mnt/IBS" "/mnt/jus-law" "/mnt/rp" "/mnt/tankServers" "/mnt/tb40" "/mnt/wd40tb" ];
    };


    # Time.
    time.timeZone = "Europe/Zurich";


    # Add the NixOS Manual on virtual console 8
    services.nixosManual.showManual = true;

    # Setup bash completion
    programs.bash.enableCompletion = true;


    # Setup nano
    programs.nano.nanorc = ''
        set nowrap
        set tabstospaces
        set tabsize 4
        set constantshow
        # include /usr/share/nano/sh.nanorc
    '';

    # Setup ADB
    programs.adb.enable = true;
    nixpkgs.config.android_sdk.accept_license = true;

    # The NixOS release to be compatible with for stateful data such as databases.
    # It will e.g. upgrade databases to newer versions and that can't be reverted by Nixos.
    system.stateVersion = "19.03";

    nixpkgs.config.allowUnfree = true;
#    nixpkgs.config.allowBroken = true;

    nixpkgs.config.chromium = {
  #      enablePepperFlash = true; # Chromium removed support for Mozilla (NPAPI) plugins so Adobe Flash no longer works 
    };


    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    # List of packages that gets installed....
    environment.systemPackages = with pkgs; [
#        androidenv.platformTools # contains ADB
#        android-studio
        aspell
        aspellDicts.de
        aspellDicts.en
        audacity
        bash-completion
        bind        # provides dig and nslookup
        bluedevil
        bluez
        bluez-tools
        cargo
        chromium
        cifs_utils
        cdrtools
        cmake
        conkeror
        coreutils
        cryptsetup
        curl
        dcfldd # dd alternative that shows progress and can make different checksums on the fly
        dialog
        displaylink
        directvnc
        dmidecode
        dos2unix
        dstat
        easysnap
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
        hunspellDicts.de-ch
        icedtea8_web
        iftop
        imagemagick
#        inetutils  # problems with whois, so use iputils and whois instead
#        inkscape
        iosevka
        iotop
        iperf
        iputils
        jdk
        jpegoptim
        jq
        jre
# KDE 5
        akregator
        ark
        dolphin
        kdenlive    frei0r  # frei0r provides transition effects
        kdeFrameworks.kdesu
#        kdevelop
        k3b
        kate
        kcalc
        konversation
#        ktorrent
        okular
        oxygen
        oxygen-icons5
        oxygenfonts
        plasma-desktop
        plasma-nm
        plasma-workspace
        spectacle # KSnapShot replacement for KDE 5
        kdeApplications.kdialog
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
        mdadm
        mediainfo
        mkpasswd
        mktorrent
#        monodevelop
        mplayer
        mpv
        ms-sys
#         mupdf
        netcat-gnu
        ninja
        nix-index
        nix-info
#        nix-index # provides nix-locate
        nix-prefetch-github
#        nix-repl # do:  :l <nixpkgs> to load the packages, then do qt5.m and hit tab twice
        nmap
        nox     # Easy search for packages
        nss
        nssTools
        ntfs3g
        opensc
        openssl
        openvpn
#        palemoon
        pandoc
        parted
        (pass pkgs)
        patchelf
        pavucontrol
        pciutils
        pcsctools
        pdftk
#        pgadmin
        php     # PHP-Cli
        pinentry
        pinentry_qt4
        pkgconfig
#        playonlinux
        poppler_utils # provides command_not_found
        pv
        python27Packages.youtube-dl
        python37Packages.websockify
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
        rustc
        simplescreenrecorder
        smartmontools
        smplayer
#        skype
        sox
        spice
        spice-gtk
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
        telnet
        tesseract
        thunderbird
        tightvnc
        tmux
        unoconv
        unrar
        unzip
        usbutils
        virt-viewer
        virtmanager
        virtualbox
        vlc
        wget
        which
        whois
        wine
        winetricks
        wireguard
        wireshark
        woeusb
        xpdf    # provides pdftotext
        zip

        # easysnap
        (pkgs.callPackage /home/hyper/Desktop/git-repos/nix-expressions/easysnap.nix {})

        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/pastesl/master/pastesl.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/pdfForts/master/pdfForts.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/jusLinkComposer/master/jusLinkComposer.nix") {})
#        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/master-pdf-editor.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/getTechDetails.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/autoResilver.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/stopResilver.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/freeCache.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/checkHosts.nix") {})
        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/checkVersion.nix") {})

        (pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/sjau/nix-expressions/master/batchsigner.nix") {})
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
