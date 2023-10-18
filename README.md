# winesapOS <img src="https://user-images.githubusercontent.com/10150374/158224898-bdb4ad3a-ad09-478c-a09d-d313feeb8713.png" width=15% height=15%>

***Game with Linux anywhere, no installation required!***

![Build status](https://github.com/LukeShortCloud/winesapOS/actions/workflows/main.yml/badge.svg)

![winesapOS_3_Desktop_Screenshot 720p](https://github.com/LukeShortCloud/winesapOS/assets/10150374/bf74b5dd-b162-4cef-a04c-43eac8de8a3e)

winesapOS makes it easy to setup Linux and play games off an internal or portable external drive.

This project provides an opinionated installation of Linux. It can be used on a flash drive, SD card, HDD, SSD, NVMe, or any other storage device. Both internal and external devices are fully supported. The [release images](https://github.com/LukeShortCloud/winesapOS/releases) are based on Arch Linux and the KDE Plasma desktop environment to align with what Valve's [Steam Deck](https://store.steampowered.com/steamdeck/) uses. Software for various games launchers are pre-installed. Additional drivers are installed to support Macs with Intel processors.

Want to help support our work? Consider helping out with open feature and bug [GitHub issues](https://github.com/LukeShortCloud/winesapOS/issues). Our [CONTRIBUTING.md](CONTRIBUTING.md) guide provides all of the information you need to get started as a winesapOS contributor.

**TABLE OF CONTENTS**

* [winesapOS](#winesapos)
   * [macOS Limitations](#macos-limitations)
   * [Features](#features)
       * [General](#general)
       * [Apple Intel Mac Support](#apple-intel-mac-support)
       * [Community Collaboration](#community-collaboration)
       * [winesapOS Repository](#winesapos-repository)
       * [Comparison with SteamOS](#comparison-with-steamos)
   * [Usage](#usage)
      * [Requirements](#requirements)
      * [Setup](#setup)
          * [Release Builds](#release-builds)
          * [Custom Builds](#custom-builds)
          * [Differences Between Performance, Secure, and Minimal Images](#differences-between-performance-secure-and-minimal-images)
              * [Secure Image](#secure-image)
          * [Passwords](#passwords)
          * [Mac Boot](#mac-boot)
          * [Ventoy](#ventoy)
      * [Upgrades](#upgrades)
          * [Minor Upgrades](#minor-upgrades)
          * [Major Upgrades](#major-upgrades)
      * [Uninstall](#uninstall)
   * [Tips](#tips)
      * [Getting Started](#getting-started)
      * [Steam Deck Game Mode](#steam-deck-game-mode)
      * [No Sound (Muted Audio)](#no-sound-muted-audio)
      * [Btrfs Backups](#btrfs-backups)
      * [VPN (ZeroTier)](#vpn-zerotier)
   * [Troubleshooting](#troubleshooting)
       * [Release Image Zip Files](#release-image-zip-files)
       * [Root File System Resizing](#root-file-system-resizing)
       * [Read-Only File System](#read-only-file-system)
       * [Wi-Fi or Bluetooth Not Working](#wi-fi-or-bluetooth-not-working)
       * [Some Package Updates are Ignored](#some-package-updates-are-ignored)
       * [Available Storage Space is Incorrect](#available-storage-space-is-incorrect)
       * [First-Time Setup Log Files](#first-time-setup-log-files)
       * [Legacy BIOS Boot Not Working](#legacy-bios-boot-not-working)
       * [Two or More Set Ups of winesapOS Cause an Unbootable System](#two-or-more-set-ups-of-winesapos-cause-an-unbootable-system)
       * [Snapshot Recovery](#snapshot-recovery)
       * [Reinstalling winesapOS](#reinstalling-winesapos)
   * [Frequently Asked Questions (FAQ)](#frequently-asked-questions-faq)
   * [Contributors](#contributors)
   * [User Surveys](#user-surveys)
   * [History](#history)
   * [License](#license)

## macOS Limitations

These are reasons why macOS is inferior compared to Linux when it comes to gaming.

- No 32-bit support. The latest version of macOS is now 64-bit only meaning legacy games will not run.
- As of May 2023, out of the top [100 most popular games](https://store.steampowered.com/charts/mostplayed) on Steam, [91% are playable on Linux](https://www.protondb.com/dashboard) and only [33% are playable on macOS](https://www.pcgamingwiki.com/wiki/List_of_OS_X_64-bit_games).
- The Apple M1 Arm-based processor has limited graphics capabilities and that are [comparable to integrated graphics offered by AMD and Intel](https://arstechnica.com/gadgets/2020/11/hands-on-with-the-apple-m1-a-seriously-fast-x86-competitor/). These Macs are not designed to be gaming computers.
    - Intel x86_64 games played through the Rosetta 2 compatibility layer have over a [20% performance penalty](https://www.macrumors.com/2020/11/15/m1-chip-emulating-x86-benchmark/).
    - On Apple Silicon, OpenGL is only provided by the [Metal for WebGL translation layer](https://github.com/KhronosGroup/MoltenVK/issues/203#issuecomment-1525594425).
- Steam Play's Proton is only [supported on Linux](https://github.com/ValveSoftware/Proton/wiki/Requirements) ([not macOS](https://github.com/ValveSoftware/Proton/issues/1344)).
- Old and incomplete implementations of [OpenGL 4.1 and OpenCL 1.2](https://support.apple.com/en-us/101525).
- No native Vulkan support.
    - MoltenVK is [incomplete due to missing functionality in Apple's Metal API](https://github.com/KhronosGroup/MoltenVK/issues/203).
- Linux has better gaming support because it supports 32-bit applications, OpenGL 4.6, and Vulkan.
- [CrossOver Mac](https://www.codeweavers.com/crossover), a commercial Wine product, is one of the few ways to run games on macOS but has some limitations.
    - It costs money and requires a new license yearly (or a very expensive lifetime license).
    - 32-bit Windows application support on 64-bit only macOS versions is still buggy.
    - It is based on an old version of Wine.
    - Linux has [kernel-level optimizations](https://www.phoronix.com/scan.php?page=news_item&px=FUTEX2-Bits-In-Locking-Core) for Wine.

## Features

### General

- **Any computer with an AMD or Intel processor can run winesapOS.**
- **Portability.**
    - A drive is bootable on both BIOS and UEFI systems.
    - Applications are installed using Flatpaks, a universal package manager for Linux, where possible.
- **Persistent storage.** Unlike traditional Linux live media, all storage is persistent and kept upon reboots.
    - Upon the first boot, the root partition is expanded to utilize all available space.
- **Supportability.** Linux is easy to troubleshoot remotely.
    - Access:
        - [Chrome Remote Desktop](https://remotedesktop.google.com/) via [Google Chrome](https://www.google.com/chrome/) can be used to provide remote access similar to Windows RDP.
        - SSH can be accessed via clients on the same [ZeroTier VPN](https://www.zerotier.com/) network.
        - [tmate](https://tmate.io/) makes sharing SSH sessions without VPN connections easy.
    - Tools:
        - [ClamAV](https://www.clamav.net/), and the GUI front-end [Clamtk](https://github.com/dave-theunsub/clamtk), is an open source anti-virus scanner.
        - [QDirStat](https://github.com/shundhammer/qdirstat) provides a graphical user interface to view storage space usage.
- **Usability.** Software for typical day-to-day use is provided.
    - [AppImagePool](https://github.com/prateekmedia/appimagepool) for a GUI AppImage package manager.
    - [BalenaEtcher](https://www.balena.io/etcher/) for an image flashing utility.
    - [bauh](https://github.com/vinifmor/bauh) for a GUI package manager.
    - [Blueman](https://github.com/blueman-project/blueman) for a Bluetooth pairing client.
    - [Bottles](https://usebottles.com/) for installing any Windows program.
    - [Cheese](https://wiki.gnome.org/Apps/Cheese) for a webcam software.
    - [Discord](https://discord.com/) for a gaming chat client.
    - [Dolphin](https://apps.kde.org/dolphin/) (KDE Plasma), [Nemo](https://github.com/linuxmint/nemo) (Cinnamon), or [Nautilus](https://wiki.gnome.org/action/show/Apps/Files?action=show&redirect=Apps%2FNautilus) (GNOME) for a file manager.
    - [FileZilla](https://filezilla-project.org/) for a FTP client.
    - [Firefox ESR](https://support.mozilla.org/en-US/kb/switch-to-firefox-extended-support-release-esr) for a stable web browser.
    - [Firewall](https://firewalld.org/) (secure image) provides a GUI for managing firewalld.
    - [Flatseal](https://github.com/tchx84/Flatseal) for managing Flatpaks.
    - [Google Chrome](https://www.google.com/chrome/) for a newer web browser.
    - [GParted](https://gparted.org/) for managing storage partitions.
    - [Gwenview](https://apps.kde.org/gwenview/) (KDE Plasma), [Pix](https://community.linuxmint.com/software/view/pix) (Cinnamon), or [Eye of GNOME](https://wiki.gnome.org/Apps/EyeOfGnome) for an image gallery application.
    - [KeePassXC](https://keepassxc.org/) for a cross-platform password manager.
    - [LibreOffice](https://www.libreoffice.org/) provides an office suite.
    - [Open Broadcaster Software (OBS) Studio](https://obsproject.com/) for a recording and streaming utility.
    - [PeaZip](https://peazip.github.io/) for an archive/compression utility.
    - [qBittorrent](https://www.qbittorrent.org/) for a torrent client.
    - [Spectacle](https://apps.kde.org/spectacle/) for a screenshot utility.
    - [usbmuxd](https://github.com/libimobiledevice/usbmuxd) with backported patches to properly support iPhone file transfers and Internet tethering on T2 Macs.
    - [VeraCrypt](https://www.veracrypt.fr/en/Home.html) for a cross-platform encryption utility.
    - [VLC](https://www.videolan.org/) for a media player.
    - [ZeroTier GUI](https://github.com/tralph3/ZeroTier-GUI) for a VPN utility for online LAN gaming.
- **Gaming support** out-of-the-box.
    - Game launchers:
        - [Steam](https://store.steampowered.com/).
        - [Heroic Games Launcher](https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher) for Epic Games Store games.
        - [Lutris](https://lutris.net/) for all other games.
        - [Prism Launcher](https://prismlauncher.org/) for vanilla and modded Minecraft: Java Edition.
        - [Bottles](https://usebottles.com/) for all Windows programs.
        - [EmuDeck](https://www.emudeck.com/) for video game console emulators.
    - Wine:
        - [Wine GE](https://github.com/GloriousEggroll/wine-ge-custom) and [Wine Staging](https://github.com/wine-staging/wine-staging) for running Windows applications and games without a game launcher.
        - [Proton GE](https://github.com/GloriousEggroll/proton-ge-custom) is installed along with the ProtonUp-Qt package manager for it. This provides better Windows games compatibility in Steam.
    - [GameMode](https://github.com/FeralInteractive/gamemode) is available to be used to speed up games.
    - [Gamescope](https://github.com/Plagman/gamescope) for helping play older games with frame rate or resolution issues.
    - [MangoHUD](https://github.com/flightlessmango/MangoHud) for benchmarking OpenGL and Vulkan games.
    - [GOverlay](https://github.com/benjamimgois/goverlay) is a GUI for managing Vulkan overlays including MangoHUD, ReplaySorcery, and vkBasalt.
    - [Ludusavi](https://github.com/mtkennerly/ludusavi) is a game save files manager.
    - [ProtonUp-Qt](https://github.com/DavidoTek/ProtonUp-Qt) for managing Steam Play compatibility tools.
    - [ZeroTier VPN](https://www.zerotier.com/) can be used to play LAN-only games online with friends.
    - Open source OpenGL and Vulkan drivers are installed for AMD, Intel, VirtualBox,and VMware graphics.
- **Controller support** for most controllers.
    - All official PlayStation and Xbox controllers are supported.
    - All generic DirectInput and XInput controllers are supported.
    - [AntiMicroX](https://github.com/AntiMicroX/antimicrox) is provided for configuring controller input for non-Steam games.
    - [game-devices-udev](https://codeberg.org/fabiscafe/game-devices-udev) is provided for more controller support
- **Steam Deck look and feel**.
    - [Gamescope Session](https://github.com/ChimeraOS/gamescope-session) is provied to replicate the "Game Mode" from the Steam Deck.
    - Desktop Steam client runs with the Steam Deck UI in windowed mode.
    - KDE Plasma desktop environment uses Valve's Vapor theme.
- **Minimize writes** to the drive to improve its longevity.
    - Root file system is mounted with the options `noatime` and `nodiratime` to not write the access times for files and directories.
    - Temporary directories with heavy writes (`/tmp/`, `/var/log/`, and `/var/tmp/`) are mounted as RAM-only file systems.
    - [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) is configured to use volatile (RAM-only) storage for all system logs.
    - Swappiness level is set to 1% (down from the default of 60%) as recommended by CryoByte33's [CryoUtilities](https://github.com/CryoByte33/steam-deck-utilities).
- **Full backups** via Btrfs.
    - [Snapper](https://github.com/openSUSE/snapper) takes 10 hourly, 12 monthly, and 1 annual snapshots.
    - Snapper takes a backup whenever the `pacman` package manager is used.
    - [grub-btrfs](https://github.com/Antynea/grub-btrfs) automatically generates a GRUB menu entry for all of the Btrfs backups.
- **No automatic operating system updates.** Updates should always be intentional and planned.
- **Most file systems supported.** Access any storage device, anywhere.
    - APFS
    - Bcachefs
    - Btrfs
    - CIFS/SMB
    - EROFS
    - ext2, ext3, and ext4
    - exFAT
    - F2FS
    - FAT12, FAT16, and FAT32
    - FATX16 and FATX32
    - HFS and HFS+
    - NFS
    - NTFS
    - ReiserFS
    - SSDFS
    - XFS
    - ZFS
- **Battery optimizations.**
    - The [auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq) service provides automatic power management.
- **Fully automated installation.**

### Apple Intel Mac Support

**All Intel Macs are supported.** Linux works on most Macs out-of-the-box these days. Drivers are pre-installed for newer hardware where native Linux support is missing.

| Hardware | Supported | Third-Party Driver(s) |
| -------- | --------- | --------- |
| Keyboard | Yes | [linux-t2](https://github.com/NoaHimesaka1873/linux-t2-arch) |
| Mouse | Yes | [linux-t2](https://github.com/NoaHimesaka1873/linux-t2-arch) |
| NVMe | Yes | [linux-t2](https://github.com/NoaHimesaka1873/linux-t2-arch) |
| Sound | Yes | [linux-t2](https://github.com/NoaHimesaka1873/linux-t2-arch) and [apple-t2-audio-config](https://github.com/kekrby/t2-better-audio) |
| Touch Bar | Yes | [linux-t2](https://github.com/NoaHimesaka1873/linux-t2-arch) and touchbard |
| Fans | Yes | [mbpfan](https://github.com/linux-on-mac/mbpfan) |
| Bluetooth | Yes | [linux-t2](https://github.com/NoaHimesaka1873/linux-t2-arch) and apple-bcm-firmware |
| Wi-Fi | Yes | [broadcom-wl](https://github.com/antoineco/broadcom-wl) and apple-bcm-firmware |

### Community Collaboration

We are actively working alongside these projects to help provide wider SteamOS 3 and/or Steam Deck support to the masses:

- [Batocera](https://batocera.org/)
- [ChimeraOS](https://chimeraos.org/)

### winesapOS Repository

As of winesapOS 3.1.0, we now provide our own repository with some AUR packages pre-built. This repository works on Arch Linux, Manjaro, and SteamOS 3. It is enabled on winesapOS by default. Depending on what distribution you are on, here is how it can be enabled:

-  Arch Linux or Manjaro:
    ```
    sudo sed -i s'/\[core]/[winesapos]\nServer = https:\/\/winesapos.lukeshort.cloud\/repo\/$repo\/$arch\n\n[core]/'g /etc/pacman.conf
    sudo pacman -S -y -y
    ```
-  SteamOS 3:
    ```
    sudo sed -i s'/\[jupiter-rel]/[winesapos]\nServer = https:\/\/winesapos.lukeshort.cloud\/repo\/$repo\/$arch\n\n[jupiter-rel]/'g /etc/pacman.conf
    sudo pacman -S -y -y
    ```

Enable the GPG key to be used by importing it and then locally signing the key to trust it.

```
sudo pacman-key --recv-keys 1805E886BECCCEA99EDF55F081CA29E4A4B01239
sudo pacman-key --init
sudo pacman-key --lsign-key 1805E886BECCCEA99EDF55F081CA29E4A4B01239
```

### Comparison with SteamOS

| Features | SteamOS 3 | winesapOS 3 |
| --- | --- | --- |
| SteamOS packages | Required | Optional |
| Arch Linux packages | Old | New |
| Boot compatibility | UEFI | UEFI and legacy BIOS |
| Graphics drivers | AMD | AMD, Intel, NVIDIA, Parallels, VirtualBox, and VMware |
| Audio server | PipeWire | PipeWire |
| Read-only file system | Yes | No |
| Encrypted file system | No | Yes (secure image) |
| File system backup type | A/B partitions | Btrfs snapshots |
| Number of possible file system backups | 1 | Unlimited |
| Package managers (CLI) | pacman, yay, flatpak | pacman, yay, flatpak, snap, and nix |
| Preferred package manager (CLI) | flatpak | flatpak |
| Package managers (GUI) | Discover (flatpak) | Discover (flatpak and pacman), bauh (pacman, yay/AUR, flatpak, and snap), and AppImagePool (AppImage) |
| Update type | Image-based | Package manager |
| Number of installed packages | Small | Large |
| Game launchers | Steam | Steam, Heroic Games Launcher, Lutris, and Prism Launcher |
| Linux kernels | Neptune (5.13) | Neptune (5.13), Linux LTS (6.1), and Linux T2 (Latest) |
| Additional Framework laptop drivers | No | Yes |
| Additional Intel Mac drivers | No | Yes |
| Additional Microsoft Surface drivers | No | Yes |
| Desktop environment | KDE Plasma | KDE Plasma |
| Desktop theme | Vapor | Vapor |
| AMD FSR | Global | Global |
| Gamescope | Global | Global |
| Wine | Proton | Proton, GE-Proton, Wine Staging, and Wine-GE |
| Game controller support | Large | Large |
| exFAT flash drive storage | No | Yes (16 GiB on the performance and secure images) |

winesapOS was the first Linux distribution to be based on SteamOS 3. Historically, here are the first forks of SteamOS 3:

| Distro | First Preview | First Public Release |
| --- | --- | --- |
| [winesapOS](https://github.com/LukeShortCloud/winesapOS) | [2022-03-06](https://github.com/LukeShortCloud/winesapOS/commit/2488cf702084d414ec5319a55cfbee1b86e2b05b) | [2022-03-10](https://github.com/LukeShortCloud/winesapOS/tree/3.0.0-beta.0) |
| [SteamOS for PS4](https://wololo.net/2022/03/28/release-steamos-3-0-for-ps4-unofficial/) | [2022-03-09](https://twitter.com/NazkyYT/status/1501670690453438471?cxt=HHwWjoC-oa3igNcpAAAA) | [2022-03-25](https://twitter.com/NazkyYT/status/1507284235765182465?cxt=HHwWgsCjhdnB-eopAAAA) |
| [HoloISO](https://github.com/HoloISO/holoiso) | [2022-04-21](https://github.com/HoloISO/holoiso/commit/b04bccfb78567c9958f376659703b58e87ecd359) | [2022-05-01](https://github.com/HoloISO/holoiso/releases/tag/beta0) |

## Usage

### Requirements

Minimum:

- Processor = Single-core AMD or Intel processor.
- RAM = 2 GiB.
- Graphics = AMD, Intel, or NVIDIA, Parallels Desktop, VirtualBox, or VMware Fusion/Workstation virtual graphics device.
- Storage
    - Minimal image = 8 GB USB 3.2 Gen 1 (USB 3.0) flash drive.
    - Performance and secure image = 64 GB USB 3.2 Gen 1 (USB 3.0) flash drive.

Recommended:

- Processor = Quad-core AMD or Intel processor.
- RAM = 16 GiB.
- Graphics = AMD discrete graphics card.
- Storage
    - Internal = 512 GB NVMe SSD.
    - External = 512 GB USB 3.2 Gen 2 (USB 3.1) SSD.

### Setup

#### Release Builds

1. Download the latest release from [here](https://winesapos.lukeshort.cloud/repo/iso/).
    - Performance (recommended) = Requires 40 GiB of free space to download and extract.
    - Minimal (for users low on storage space or who want control over what is installed) = Requires 12 GiB of free space to download and extract.
    - Secure (for advanced users only) = Requires 50 GiB of free space to download and extract.
    - Internal drives (PC only, does not work on Macs) = If you want to setup winesapOS using winesapOS, use the minimal image and follow through the next steps (2 and 3) to extract and flash the image. Then boot into the storage device and download the image you want to setup. Follow steps 2 and 3 again to flash the image onto a different storage device.
        - Copying partitions using GParted from a storage device with winesapOS already installed is not recommended as it requires rebuilding the GRUB configuration. We will not provide support for that and instead recommend using balenaEtcher or `dd` to flash the entire image instead.
            - For balenaEtcher, when you "Select target" there is an option to "Show hidden" storage devices. It will let you flash an image to any drive except the one it is physically running on.
    - If you want even more control over the how the image is built, consider doing a [custom build](#custom-builds) instead.
2. Extract the `winesapos-<VERSION>-<TYPE>.img.zip` archive.
3. Use the image...
    1. on a PC or Mac.
        - Flash the image to an internal or external storage device. **WARNING:** This will delete any existing data on that storage device.
            - On Linux, macOS, and Windows, the [balenaEtcher](https://www.balena.io/etcher/) GUI utility can be used to flash the image.
            - On Linux and macOS, the `dd` CLI utility can be used to flash the image.
            - Ventoy is not supported because winesapOS is not a traditional live media. Support for this will be added in the future.
    2. with Parallels Desktop on macOS.
        - Convert the raw image to the VDI format. Then convert the VDI image to HDD.
            - Using the qemu-img and prl_convert CLI:
                ```
                qemu-img convert -f raw -O vdi winesapos-<VERSION>-<TYPE>.img winesapos-<VERSION>-<TYPE>.vdi
                prl_convert winesapos-<VERSION>-<TYPE>.vdi --allow-no-os --stand-alone-disk --dst=winesapos-<VERSION>-<TYPE>.hdd
                ```
        - Parallels Desktop > Install Windows or another OS from a DVD or image file > Image File > select a file... > (select the winesapOS HDD file) > Continue > Please select your operating system: > More Linux > Other Linux > OK > Name: winesapOS > Create
    3. with VMware Fusion on macOS.
        - Convert the raw image to the VMDK format.
            - Using the VirtualBox CLI:
                ```
                VBoxManage convertfromraw --format VMDK winesapos-<VERSION>-<TYPE>.img winesapos-<VERSION>-<TYPE>.vmdk
                ```
            - Using the qemu-img CLI:
                ```
                qemu-img convert -f raw -O vmdk winesapos-<VERSION>-<TYPE>.img winesapos-<VERSION>-<TYPE>.vmdk
                ```
            - Using [StarWind V2V Converter](https://www.starwindsoftware.com/starwind-v2v-converter) on Windows.
        - VMware Fusion > Virtual Machine Library > + > New... > Create a custom virtual machine > Continue > Linux > Other Linux 5.x kernel 64-bit > Continue > Specify the boot firmware: UEFI > Continue > Use an existing virtual disk > Continue > Custom Settings > Hard Disk (SCSI) > Disk size: (increase to at least 64 GB) > Apply > Show All > Processors & Memory > Processors: 2 processor cores > Memory: 4096 MB > Show All > Display > Accelerate 3D Graphis: Yes > Shared graphics memory: (set this to the highest possible value)
    4. with VMware Workstation on Linux or Windows.
        - Convert the raw image to the VMDK format.
        - VMware Workstation > Create a New Virtual Machine > Custom (advanced) > Next > Hardware compatibility: (select the latest version) > Next > I will install the operating system later. > Next > Guest Operating System: 2. Linux > Version: Other Linux 5.x kernel 64-bit > Next > Name: winesapOS > Next > Number of processors: 2 > Next > Memory for this virtual machine: 4096 MB > Next > Use network address translation (NAT) > Next > SCSI controller: LSI Logic (Recommended) > Next > Virtual Disk Type: SCSI (Recommended) > Next > Use an existing virtual disk > Next > File name: (select the winesapOS VMDK file) > Keep Existing Format > Customize Hardware... > Hard Disk (SCSI) > Expand Disk... > Maximum disk size (GB): (increase to at least 64 GB) > Expand > OK > Display > Accelerate 3D graphics: Yes > Graphics Memory: (set this to the highest possible value) > Close > Finish > Close
    5. with VirtualBox.
        - Convert the raw image to the VDI format.
            - Using the VirtualBox CLI:
                ```
                VBoxManage convertfromraw --format VDI winesapos-<VERSION>-<TYPE>.img winesapos-<VERSION>-<TYPE>.vdi
                ```
            - Using the qemu-img CLI:
                ```
                qemu-img convert -f raw -O vdi winesapos-<VERSION>-<TYPE>.img winesapos-<VERSION>-<TYPE>.vdi
                ```
            - Using [StarWind V2V Converter](https://www.starwindsoftware.com/starwind-v2v-converter) on Windows.
        - Virtual Box > New > Name: winesapOS, Type: Linux, Version: Arch Linux (64-bit) > Next > Base Memory: 4096 MB, Processors: 2, Enable EFI: Yes > Next > Use an Existing Virtual Hard Disk File > Add > Choose > Next > Finish > File > Tools > Virtual Media Manager > Size: (increase to at least 32 GB) > Apply > OK > winesapOS > Settings > General > Advanced > Shared Clipboard: Bidirectional, Drag'n'Drop: Bidirectional > OK > winesapOS > Settings > Display > Screen > Video Memory: 128 MB, Graphics Controller: VMSVGA, Extended Features: Enable 3D Acceleration
        - **NOTICE:** VirtualBox 3D acceleration for Linux guests does not fully work. This issue is not specific to winesapOS. Consider using VMware Fusion or VMware Workstation instead.

Default accounts have a password set that mirror the username:

- winesapOS (major version >= 3)

| Username | Password |
| --- | --- |
| winesap | winesap |
| root | root |

- Mac Linux Gaming Stick (major version <= 2)

| Username | Password |
| --- | --- |
| stick | stick |
| root | root |

Upon first login, the "winesapOS First-Time Setup" wizard will launch. It will help setup graphics drivers, the locale, and time zone. The desktop shortcut is located at `/home/winesap/.winesapos/winesapos-setup.desktop` and can be manually ran again.

#### Custom Builds

Instead of using a release build which is already made, advanced users may want to create a custom build. This only requires 1 GiB of free space to download the live Arch Linux environment. It also allows using environment variables to configure the build differently than the default release builds.

1.  [Download](https://archlinux.org/download/) and setup the latest Arch Linux ISO onto a flash drive that has at least 1 GB of storage.

    1a.  We also support building winesapOS with Manjaro even though we do not provide release images for it. [Download](https://manjaro.org/download/) either the Plasma, Cinnamon, or GNOME desktop edition of Manjaro.

2.  Boot into the flash drive.
3.  Update the known packages cache and install git.

    ```
    pacman -S -y
    pacman -S git
    ```

4.  Clone the [stable](https://github.com/LukeShortCloud/winesapOS/tree/stable) branch and go to the "scripts" directory.

    ```
    git clone --branch stable https://github.com/lukeshortcloud/winesapos.git
    cd ./winesapos/scripts/
    ```

5.  Configure [environment variables](https://github.com/LukeShortCloud/winesapOS/blob/stable/CONTRIBUTING.md#environment-variables) to customize the build. At the very least, allow the build to work on bare-metal and define what ``/dev/<DEVICE>`` block device to install to. ***BE CAREFUL AS THIS WILL DELETE ALL EXISTING DATA ON THAT DEVICE!***

    ```
    export WINESAPOS_BUILD_IN_VM_ONLY=false
    lsblk
    export WINESAPOS_DEVICE=<DEVICE>
    ```

6.  Run the build.

    ```
    sudo -E ./winesapos-install.sh
    ```

7.  Check for any test failures (there should be no output from this command).

    ```
    grep -P 'FAIL$' /winesapos/etc/winesapos/winesapos-install.log
    ```

For more detailed information on the build process, we recommend reading the entire [CONTRIBUTING.md](CONTRIBUTING.md) guide.

#### Differences Between Performance, Secure, and Minimal Images

These are the main differences between the performance, secure, and minimal images. The performance is focused on speed and ease-of-use. The secure image is recommended for advanced Linux users. The minimal image is focused on using a small amount of storage space with only the core operating system packages needed to run a basic GUI desktop.

| Feature | Performance | Secure | Minimal |
| ------- | ----------- | ------ | ------- |
| CPU Mitigations | No | Yes | No |
| Encryption | No | Yes (LUKS) | No |
| Firewall | No | Yes (Firewalld) | No |
| Linux Kernel Updates | No | Yes | No |
| Passwords Require Reset | No | Yes | No |
| 16 GiB exFAT portable storage | Yes | Yes | No |

##### Secure Image

If using the secure image, the default LUKS encryption key is `password` which should be changed after the first boot. Do not do this before the first boot as the default password is used to unlock the partition for it be resized to fill up the entire storage device. Change the LUKS encryption key for the fifth partition.

```
$ sudo cryptsetup luksChangeKey /dev/<DEVICE>5
```

The user account password for ``winesap`` (or ``stick`` on older versions) and ``root`` are the same as the username. They are set to expire immediately. Upon first login, you will be prompted to enter a new password. Here is how to change it:

1. Enter the default password of ``winesap``.
2. The prompt will say "Changing password for winesap." Enter the default password of ``winesap`` again.
3. The prompt will now say "New password". Enter a new password.
4. The prompt will finally say "Retype new password". Enter the new password again. The password has been updated and the KDE Plasma desktop will now load.

The `root` user account is locked until the password is changed. It is recommended to change this immediately to allow for recovery to work.

```
$ sudo passwd root
```

#### Passwords

| Username | Password |
| -------- | -------- |
| root | root |
| winesap | winesap |

On the secure image, the LUKS encryption key is `password`. The password for LUKS and the `root` account should be changed immediately.

```
$ sudo cryptsetup luksChangeKey /dev/<DEVICE>5
$ sudo passwd root
```

#### Mac Boot

Boot the Mac into an external drive by pressing and releasing the power button. Then hold down the `OPTION` key (or the `ALT` key on a Windows keyboard) to access the Mac bootloader. Select the "EFI Boot" device.

**IMPORTANT** Any [Mac with an Apple T2 Security Chip](https://support.apple.com/en-us/HT208862), which are all Macs made in and after 2018, needs to [allow booting from external storage](https://support.apple.com/en-us/HT208198):

1. Turn on the Mac and immediately hold both the `COMMAND` and `r` keys to enter recovery mode.
2. Utilities > Startup Security Utility
    - Secure Boot = No Security (Does not enforce any requirements on the bootable OS.)
    - External Boot = Allow booting from external media (Does not restrict the ability to boot from any devices.)

#### Ventoy

winesapOS release images are in a raw format which does not work out-of-the-box with Ventoy. These can be modified to work with Ventoy by using the [Linux vDisk boot plugin](https://www.ventoy.net/en/plugin_vtoyboot.html).

1. Create a virtual machine for winesapOS. View the [setup](#setup) guide for instructions on how to use VirtualBox, VMware Fusion, or VMware Player/Workstation.
2. [Download](https://github.com/ventoy/vtoyboot/releases) the latest `vtoyboot` ISO and attach it to the virtual machine.
3. Mount the ISO in the virtual machine and then run the `vtoyboot.sh` command. This will convert the operating system to be useable via Ventoy.
4. Shutdown the virtual machine and then rename the virtual machine image to `winesapos.vtoy`.

The image can now be used by Ventoy.

### Upgrades

#### Minor Upgrades

Upgrades are supported and recommended between all minor releases of winesapOS. For example, it is supported to go from 3.0.0 to 3.2.1.

Where it makes sense, features are backported from newer versions of winesapOS. Bug and security fixes are also included to fix problems either with winesapOS itself or with upstream changes in SteamOS. Even if a user never upgrades winesapOS, users will continue to get regular system upgrades from SteamOS.

Before upgrading, please read the full [UPGRADE.md](https://github.com/LukeShortCloud/winesapOS/blob/stable/UPGRADES.md) notes. This showcases what updates will happen automatically and what updates may need to be manually applied.

Development builds do not support upgrades. Here are the releases that we do support upgrades on:

| Release | Upgrades Supported |
| ------- | ------------------ |
| Stable | Yes |
| Release Candidate (RC) | Yes |
| Beta | No |
| Alpha | No |

Here is how to upgrade winesapOS:

- GUI = Launch the "winesapOS Upgrade" desktop shortcut.
- CLI = Launch the winesapOS upgrade script from the stable branch.

    ```
    curl https://raw.githubusercontent.com/LukeShortCloud/winesapOS/stable/scripts/winesapos-upgrade.sh | sudo -E zsh
    ```

#### Major Upgrades

Open `Terminator` and run these two commands to do a major upgrade from Mac Linux Gaming Stick 2 to winesapOS 3:

```
echo stick > /tmp/winesapos_user_name.txt
curl https://raw.githubusercontent.com/LukeShortCloud/winesapOS/stable/scripts/winesapos-upgrade.sh | sudo -E zsh
```

### Uninstall

If desired, it is possible to remove winesapOS specific files and configuration and switch back to upstream Arch Linux using an uninstall script. It will not remove anything that is related to improved hardware compatibility.

```
curl https://raw.githubusercontent.com/LukeShortCloud/winesapOS/stable/scripts/winesapos-uninstall.sh | sudo -E zsh
```

## Tips

### Getting Started

- Test booting up the drive first before buying speakers, a Bluetooth adapter, a Wi-Fi adapter, and/or other hardware. Depending on the Mac, the built-in hardware may work out-of-the-box.
- Plug additional hardware into a USB hub. Connect the USB hub to the computer before booting.
- Do NOT move the USB hub after plugging it in and booting up Linux. It can easily disconnect leading to a corrupt file system.
- Consider buying an SSD instead of a flash drive for a longer life-span, more storage, and faster speeds.
- Delete old Btrfs backups when the drive is running low on storage space.

    ```
    $ sudo snapper list
    $ sudo snapper delete <SNAPSHOT_NUMBER>
    ```

- Enable Proton for all Windows games. This will allow them to run in Linux. For more information about Proton, [read this starter guide](https://www.gamingonlinux.com/2019/07/a-simple-guide-to-steam-play-valves-technology-for-playing-windows-games-on-linux). Check the compatibility rating for games on Steam by using [ProtonDB](https://www.protondb.com/).

    ```
    Settings > Steam Play > Enable Steam Play for Support Titles > Use this tool instead of game-specific selections from Steam > Compatibility tool: > (select the latest "Proton" version available) > OK
    ```

### Steam Deck Game Mode

On the LightDM login screen for the "winesap" user, the wrench icon in the top-right can be used to change the session from "Plasma (X11)" to "Steam Big Picture". This provides the same experience as having a Steam Deck in "Game Mode" by launching Steam with Gamescope Session. Using this on devices that are not the Steam Deck will have varied results. For example, configuring TDP for other devices will not work as the Steam client is hardcoded to only work on the Steam Deck.

Known issues:

- NVIDIA is not supported due to limitations in their driver. Only AMD and Intel graphics cards will work.
- "Steam Desktop" must be launched from KDE Plasma first. This downloads the required bootstrap files needed for the Steam client to work.

Alternatively, Steam can be launched from KDE Plasma using one of these desktop shortcuts:

- Steam Deck = Launches the Steam Deck UI as a windowed application. It can be set to fullscreen once opened. The desktop environment is still running in the background, unlike with Gamescope Session where Steam is the only GUI process running.
- Steam (Runtime) = Launches the traditional Steam client for Linux desktop as a windowed application.

### No Sound (Muted Audio)

When Mac hardware is detected, all sound is muted on boot because on newer Macs the experimental sound driver is extremely loud. This means that any sound volume changes will be reset on the next boot. Here is how the mute configuration can be disabled to allow the sound volume to be saved:

-  winesapOS (major version >= 3)

    - Disable and stop the user (not system) ``mute`` service.

        ```
        $ systemctl --user disable --now mute.service
        ```
- Mac Linux Gaming Stick (major version <= 2)

    - Move or delete the PulseAudio configuration.

        ```
        $ mv /home/stick/.config/pulse/default.pa ~/
        ```

### Btrfs Backups

Both the root `/` and `/home` directory have automatic backups/snapshots configured by Snapper. A new backup will be taken hourly (up to 10), every month (up to 12), and every year (up to 1). The root directory will also have a backup taken whenever `pacman` is used to install or remove a package.

During boot, GRUB will have a "SteamOS snapshots" section that will allow booting from a root directory snapshot. This will not appear on first boot because no backups have been taken yet. After a backup has been taken, the GRUB configuration file needs to be regenerated to scan for the new backups.

Manually rebuild the GRUB configuration file to load the latest snapshots:

```
$ sudo grub-mkconfig -o /boot/grub/grub.cfg
```

View the available backups:

```
$ sudo snapper -c root list
$ sudo snapper -c home list
```

Manually create a new backup:

```
$ sudo snapper -c <CONFIG> create
```

Manually delete a backup:

```
$ sudo snapper -c <CONFIG> delete <BACKUP_NUMBER>
```

### VPN (ZeroTier)

A VPN is required for LAN gaming online. Hamachi is reported to no longer work on newer versions of [Arch Linux](https://aur.archlinux.org/packages/logmein-hamachi/) and [Ubuntu](https://community.logmein.com/t5/LogMeIn-Hamachi-Discussions/Hamachi-randomly-disconnects-on-Ubuntu-20-04/td-p/222430). Instead, use the free and open source ZeroTier VPN service.

**Host**

1. Only one person needs to create a [ZeroTier account](https://my.zerotier.com/).
2. They must then create a [ZeroTier network](https://www.stratospherix.com/support/setupvpn_01.php).
    1. Log into [ZeroTier Central](https://my.zerotier.com/).
    2. Select "[Networks](https://my.zerotier.com/network)".
    3. Select "Create A Network".
    4. Select the "Network ID" or "Name" of the new network to modify the settings.
        - Either (1) set the "Access Control" to "Public" or (2) use this settings page to manually authorize connected clients to be able to communicate on the network.
        - Take note of the "Network ID". Send this string to your friends who will connect to the VPN.

**Clients**

1. Start the ZeroTier VPN service.

    ```
    $ sudo systemctl enable --now zerotier-one
    ```

2. Connect to the ZeroTier network.

    ```
    $ sudo zerotier-cli join <NETWORK_ID>
    ```

## Troubleshooting

### Release Image Zip Files

**Challenge: the release image fails to be extracted from the zip file.**

**Solutions:**

1. **Verify the integrity of the downloaded zip files.**

    - Linux:

        ```
        sha512sum --check winesapos-<VERSION>-<TYPE>.sha512sum.txt
        ```

    - Windows (open Command Prompt as Administrator):

        ```
        C:\Windows\system32>CertUtil.exe -hashfile C:\Users\<USER>\Downloads\winesapos-<VERSION>-<TYPE>.sha512sum.txt SHA512
        ```

2. **Not enough free space.** Ensure you have 12 GiB (minimal image), 40 GiB (performance image), or 50 GiB (secure image) of free space before downloading the zip files.
3. **If using PeaZip, it sometimes fails to extract to the current directory.** Try extracting to a different directory.

### Root File System Resizing

**Challenge: the root file system does not resize itself to use all available space on the storage device.**

**Solution:**

1. Re-enable the resize service, reboot, and then view the service log. Open up a [GitHub Issue](https://github.com/LukeShortCloud/winesapOS/issues) with the full log output.

    ```
    sudo systemctl enable winesapos-resize-root-file-system
    sudo reboot
    ```

    ```
    sudo journalctl --unit winesapos-resize-root-file-system
    ```

### Read-Only File System

If using an external USB drive, it is possible to get errors about a `Read-only file system`. This is a hardware issue and indicates that the USB drive has been disconnected even if only for a fraction of a second. Short-term, reboot winesapOS to fix these errors. Long-term, try using a different USB port and/or drive and make sure that the drive does not move while in use. For the best experience, we recommend using an internal drive.

### Wi-Fi or Bluetooth Not Working

If Wi-Fi or Bluetooth is not showing up or connecting, try the following workarounds:

-  Fully shutdown Windows by holding the "SHIFT" key while selecting "Shut down", selecting to "Reboot", or by running the command ``shutdown /s /f /t 0``.
-  In the BIOS, set the winesapOS storage device to be the first boot device.

### Some Package Updates are Ignored

**Challenge: Pacman has packages listed in its  `IgnorePkg` configuration.**

**Solution:**

1. Use the official tool to [upgrade winesapOS](#upgrades).
    - The performance and minimal images prevent updates to Linux kernels updates to prevent breaking third-party kernel modules.
    - The secure image only prevents updates to packages that Arch Linux and SteamOS provide conflicting packages to.

### Available Storage Space is Incorrect

**Challenge: the amount of reported free space seems too small or large.**

**Solutions:**

1. Btrfs is used as the root file system on winesapOS. The most reliable way to view the amount of storage in-use on Btrfs is with this command.

    ```
    sudo btrfs filesystem df /
    ```

2. Snapper is used to take Btrfs snapshots/backups (1) every time Pacman installs, upgrades, or removes a package and (2) every month. Refer to the [Btrfs Backups](#btrfs-backups) section for more information on how to manage those snapshots.

### First-Time Setup Log Files

If the first-time setup fails or needs debugging, the last log file can be found and copied to the desktop by running these two commands:

```
$ sudo cp "/etc/winesapos/$(sudo ls -1 /etc/winesapos/ | grep setup | tail -n 1)" /home/winesap/Desktop/
$ sudo chown winesap:winesap "/home/winesap/Desktop/$(ls -1 ~/Desktop/ | grep setup_)"
```

### Legacy BIOS Boot Not Working

Older motherboards that do not support GPT partition layouts will not be able to boot winesapOS. Manually converting winesapOS from GPT to MBR and re-installing the GRUB boot loader does not fix this issue.

### Two or More Set Ups of winesapOS Cause an Unbootable System

**Challenge: winesapOS uses labels for file system mounts which confuses the system if more than one label is found.**

**Solution:**

1. **Change the file system label and UUID of at least the root file system** on one of the winesapOS drives. It is recommended to change all of the labels on that same drive. **This can cause an unbootable system.** Manually review the contents of `/etc/fstab` to ensure it is correct.

    ```
    # Labels can be changed on mounted file systems.
    lsblk -o name,label
    export DEVICE=vda
    sudo -E exfatlabel /dev/${DEVICE}2 wos-drive0
    sudo -E fatlabel /dev/${DEVICE}3 WOS-EFI0
    sudo sed -i s'/LABEL=WOS-EFI/LABEL=WOS-EFI0/'g /etc/fstab
    sudo -E e2label /dev/${DEVICE}4 winesapos-boot0
    sudo sed -i s'/LABEL=winesapos-boot/LABEL=winesapos-boot0/'g /etc/fstab
    sudo btrfs filesystem label / winesapos-root0
    sudo btrfs filesystem show /
    sudo sed -i s'/LABEL=winesapos-root/LABEL=winesapos-root0/'g /etc/fstab
    lsblk -o name,label
    ```

    ```
    # UUIDs can only be changed on unmounted file systems.
    # It is recommended to do these steps from a different live Linux environment.
    lsblk -o name,uuid
    sudo exfatlabel -i /dev/${DEVICE}2 $(uuidgen | cut -d- -f2,3)
    sudo mlabel -N $(uuidgen | cut -d- -f2,3) /dev/${DEVICE}3
    sudo e2fsck -f /dev/${DEVICE}4
    sudo tune2fs -U $(uuidgen) /dev/${DEVICE}4
    sudo btrfstune -U $(uuidgen) /dev/${DEVICE}5
    lsblk -o name,uuid
    ```

    ```
    # GRUB needs to be updated with the new UUIDs.
    sudo chroot <MOUNTED_ROOT_AND_BOOT_DIRECTORY> grub-mkconfig -o /boot/grub/grub.cfg
    ```

### Snapshot Recovery

**Challenges:**

1. winesapOS upgrade fails.
2. Old files need to be recovered.

**Solution:**

1. At the GRUB boot menu select "SteamOS snapshots" and then the desired backup to load. The filesystem will be read-only by default. It can be set to enable writes with this command:

    ```
    $ sudo btrfs property set -ts /.snapshots/<BTRFS_SNAPSHOT_ID> ro false
    ```

For more advanced recovery using ``overlayfs`` on-top of a read-only filesystem, refer to this [grub-btrfs GitHub issue](https://github.com/Antynea/grub-btrfs/issues/92).

### Reinstalling winesapOS

Reinstalling winesapOS on-top of an existing winesapOS installation can cause issues. This is because the partitions are perfectly aligned which leads to overlapping data. Even wiping the partition table is not enough. For the best results, it is recommended to completely wipe at least the first 29 GiB of the storage device. **WARNING:** This will delete any existing data on that storage device.

```
dd if=/dev/zero of=/dev/<DEVICE> bs=1M count=29000
```

## Frequently Asked Questions (FAQ)

- **Is this the Mac Linux Gaming Stick project?**
    - Yes. Version 1 and 2 of the project were called Mac Linux Gaming Stick. In version 3, we rebranded to winesapOS.
- **How do you pronounce winesapOS?**
    - `wine`-`sap`-`o`-`s`.
- **What is the relevance of the word "winesap" in winesapOS?**
    - It is a type of apple which signifies how we develop on Macs and ship drivers for them. It also has the word "wine" in it which is the [name of the project](https://www.winehq.org/) used to enable Windows gaming on Linux.
- **What makes this different than adding persistent storage to a live CD with [Universal USB Installer or YUMI](https://www.pendrivelinux.com/)?**
    - Having persistent storage work via these hacky methods can be hit-or-miss depending on the distribution. winesapOS was built from the ground-up to have persistent storage. It also features automatic backups, various gaming tools, has support for Macs, and more.
- **Are Arm Macs supported?**
    - No. In general, Linux support for them are still a work-in-progress.
- **Is winesapOS a Linux distribution?**
    - Yes. We provide customized packages, a package repository, various optimizations, and our own upgrade process. winesapOS is a fork of SteamOS 3 (which is a fork of Arch Linux).
- **Do I have to install winesapOS?**
    - No. No installation is required. Flash a [release image](https://github.com/LukeShortCloud/winesapOS/releases) to a drive and then boot from it. Everything is already installed and configured.
- **What if winesapOS was abandoned?**
    - We have no intentions on ever abandoning winesapOS. Even if that happened, since this is an opinionated installation of an Arch Linux distribution, it will continue to get normal operating system updates. The [uninstall](#uninstall) script can also be used to switch back to upstream Arch Linux.
- **Can anyone build winesapOS?**
    - Yes. Refer to the [CONTRIBUTING.md](CONTRIBUTING.md) documentation.
- **Can winesapOS be built with a different Linux distribution?**
    - Yes. We support Arch Linux, Manjaro, and SteamOS as build targets. As of winesapOS 3, SteamOS 3 is the default target that is used for our releases.
- **Is winesapOS affiliated with Valve?**
    - No. We are an independent project that is using SteamOS 3 packages and source code.

## Contributors

Here are community contributors who have helped the winesapOS project.

**Founder:**

- [LukeShortCloud](https://github.com/LukeShortCloud)

**Code:**

- [Thijzer](https://github.com/Thijzer)

**Documentation:**

- [soredake](https://github.com/soredake)

**Financial:**

- Mike Artz
- [Linux Gaming Central](https://linuxgamingcentral.com/)

## User Surveys

These are anonymous surveys done with Linux gaming community members. Most, but not all, are winesapOS users.

----

Favorite (non-Valve) handheld PC brand:

* AYANEO = 50%
* GPD = 33.3%
* ONEXPlayer = 0%
* Other = 16.7%

6 votes.

There were no comments about what the "Other" brand is so that is unknown.

https://twitter.com/LukeShortCloud/status/1649078025634598912

----

Favorite desktop environments:

- GNOME = 40%
- Plasma by KDE = 40%
- Xfce = 4%
- Other = 16%

25 votes.

"Other" included specific mentions from the community about Cinnamon (for its similarity to Windows) and Sway (for its tiling features).

https://twitter.com/LukeShortCloud/status/1659279345926516737

----

Should winesapOS rebase SteamOS 3 on-top of Arch Linux?

* Yes = 78.9%
* No = 21.2%

19 votes.

We did make this change and our operating system has been more stable and secure ever since.

https://twitter.com/LukeShortCloud/status/1528762193004466177

## History

| Release Version/Tag | Project Name | Operating System | Desktop Environment | Release Images |
| ------------------- | ------------ | ---------------- | ------------------- | -------------- |
| 3.2.0-alpha.0 | winesapOS | SteamOS 3 | KDE Plasma | Performance, Secure, and Minimal |
| 3.0.0-beta.0 | winesapOS | SteamOS 3 | KDE Plasma | Performance and Secure |
| 3.0.0-alpha.0 | winesapOS | Arch Linux | KDE Plasma | Performance and Secure |
| 2.2.0 | Mac Linux Gaming Stick | Manjaro | Cinnamon | Performance and Secure |
| 2.0.0 | Mac Linux Gaming Stick | Manjaro | Cinnamon | Performance |
| 1.0.0 | Mac Linux Gaming Stick | Ubuntu 20.04 | Cinnamon | None |

## License

GPLv3
