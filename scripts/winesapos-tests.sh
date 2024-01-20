#!/bin/zsh

WINESAPOS_DEBUG_TESTS="${WINESAPOS_DEBUG_TESTS:-false}"
if [[ "${WINESAPOS_DEBUG_TESTS}" == "true" ]]; then
    set -x
else
    set +x
fi

echo "Tests start time: $(date)"

current_shell=$(cat /proc/$$/comm)
if [[ "${current_shell}" != "zsh" ]]; then
    echo "winesapOS scripts require zsh but ${current_shell} detected. Exiting..."
    exit 1
fi

# Load default environment variables.
. ./env/winesapos-env-defaults.sh

WINESAPOS_DEVICE="${WINESAPOS_DEVICE:-vda}"

if [[ "${WINESAPOS_CREATE_DEVICE}" == "true" ]];
    then DEVICE="$(cat /tmp/winesapos-device.txt)"
else
    DEVICE="/dev/${WINESAPOS_DEVICE}"
fi

failed_tests=0
winesapos_test_failure() {
    failed_tests=$(expr ${failed_tests} + 1)
    echo FAIL
}

if [[ "${WINESAPOS_BUILD_CHROOT_ONLY}" == "false" ]]; then
    DEVICE_WITH_PARTITION="${DEVICE}"
    echo ${DEVICE} | grep -q -P "^/dev/(nvme|loop)"
    if [ $? -eq 0 ]; then
        # "nvme" and "loop" devices separate the device name and partition number by using a "p".
        # Example output: /dev/loop0p
        DEVICE_WITH_PARTITION="${DEVICE}p"
    fi

    DEVICE_WITH_PARTITION_SHORT=$(echo ${DEVICE_WITH_PARTITION} | cut -d/ -f3)

    # Required to change the default behavior to Zsh to fail and exit
    # if a '*' glob is not found.
    # https://github.com/LukeShortCloud/winesapOS/issues/137
    setopt +o nomatch

    echo "Testing partitions..."
    parted_print=$(parted ${DEVICE} print)

    echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}1 is not formatted..."
    echo ${parted_print} | grep -P "^ 1 " | grep -q -P "kB\s+primary"
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    if [[ "${WINESAPOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
        echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}2 is formatted as exFAT..."
        # 'parted' does not support finding if a partition is exFAT formatted.
        # 'lsblk -f' does but that does not work inside of a container.
        # https://github.com/LukeShortCloud/winesapOS/issues/507
        echo ${parted_print} | grep -P "^ 2 " | grep -q -P "GB\s+primary"
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi

        echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}2 has the 'msftdata' partition flag..."
        parted ${DEVICE} print | grep -q msftdata
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    fi

    if [[ "${WINESAPOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
        echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}3 is formatted as FAT32..."
        echo ${parted_print} | grep -P "^ 3 " | grep -q fat
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    else
        echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}2 is formatted as FAT32..."
        echo ${parted_print} | grep -P "^ 2 " | grep -q fat
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    fi

    if [[ "${WINESAPOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
        echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}4 is formatted as ext4..."
        echo ${parted_print} | grep -P "^ 4 " | grep -q ext4
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    else
        echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}3 is formatted as ext4..."
        echo ${parted_print} | grep -P "^ 3 " | grep -q ext4
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    fi

    if [[ "${WINESAPOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
        echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}5 is formatted as Btrfs..."
        if [[ "${WINESAPOS_ENCRYPT}" == "true" ]]; then
            parted /dev/mapper/cryptroot print | grep -q -P "^ 1 .*btrfs"
            if [ $? -eq 0 ]; then
                echo PASS
            else
                winesapos_test_failure
            fi
        else
            echo ${parted_print} | grep -P "^ 5 " | grep -q btrfs
            if [ $? -eq 0 ]; then
                echo PASS
            else
                winesapos_test_failure
            fi
        fi
    else
        echo -n "\t\tChecking that ${DEVICE_WITH_PARTITION}4 is formatted as Btrfs..."
        if [[ "${WINESAPOS_ENCRYPT}" == "true" ]]; then
            parted /dev/mapper/cryptroot print | grep -q -P "^ 1 .*btrfs"
            if [ $? -eq 0 ]; then
                echo PASS
            else
                winesapos_test_failure
            fi
        else
            echo ${parted_print} | grep -P "^ 4 " | grep -q btrfs
            if [ $? -eq 0 ]; then
                echo PASS
            else
                winesapos_test_failure
            fi
        fi
    fi

    # Due to the GitHub Actions environment not supporting UEFI,
    # this feature and test will not work.
    # https://github.com/LukeShortCloud/winesapOS/issues/664
    if [[ "${WINESAPOS_GITHUB_ACTIONS_TESTS}" == "false" ]]; then
        echo -n "Checking that the UEFI boot name is winesapOS..."
        chroot ${WINESAPOS_INSTALL_DIR} efibootmgr | grep winesapOS
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    fi

    echo -n "Testing partitions complete.\n\n"

    echo "Testing /etc/fstab mounts..."

    echo "Debug output of fstab contents below..."
    cat ${WINESAPOS_INSTALL_DIR}/etc/fstab

    echo "\t\tChecking that each mount exists in /etc/fstab...\n"
    for i in \
      "^(\/dev\/loop|\/dev\/mapper\/cryptroot|LABEL\=).*\s+/\s+btrfs\s+rw,noatime,nodiratime,compress-force=zstd:1,discard" \
      "^(\/dev\/loop|\/dev\/mapper\/cryptroot|LABEL\=).*\s+/home\s+btrfs\s+rw,noatime,nodiratime,compress-force=zstd:1" \
      "^(\/dev\/loop|\/dev\/mapper\/cryptroot|LABEL\=).*\s+/swap\s+btrfs\s+rw,noatime,nodiratime,compress-force=zstd:1" \
      "^(none|tmpfs)\s+/tmp\s+tmpfs\s+rw.*\s+0\s+0" \
      "^(none|tmpfs)\s+/var/log\s+tmpfs\s+rw.*\s+0\s+0" \
      "^(none|tmpfs)\s+/var/tmp\s+tmpfs\s+rw.*\s+0\s+0"
        do echo -n "\t\t${i}..."
        grep -q -P "${i}" ${WINESAPOS_INSTALL_DIR}/etc/fstab
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    done

    if [[ "${WINESAPOS_DISTRO}" == "steamos" ]]; then
        fstab_efi="^(\/dev\/loop|LABEL\=).*\s+/efi\s+vfat\s+rw"
    else
        fstab_efi="^(\/dev\/loop|LABEL\=).*\s+/boot/efi\s+vfat\s+rw"
    fi
    echo -n "\t\t${fstab_efi}..."
    grep -q -P "${fstab_efi}" ${WINESAPOS_INSTALL_DIR}/etc/fstab
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
    echo -n "Testing /etc/fstab mounts complete.\n\n"

    echo "Testing Btrfs subvolumes..."

    echo -n "\t\tChecking that the Btrfs subvolumes exist...\n"
    for i in \
      ".snapshots" \
      "home" \
      "home/\.snapshots" \
      "swap"
        do echo -n "\t\t${i}..."
        btrfs subvolume list ${WINESAPOS_INSTALL_DIR} | grep -q -P " ${i}$"
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    done

    echo -n "Testing Btrfs subvolumes complete.\n\n"
fi

echo -n "\t\tChecking that the swappiness level has been decreased..."
grep -P -q "^vm.swappiness=1" ${WINESAPOS_INSTALL_DIR}/etc/sysctl.d/00-winesapos.conf
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo "Testing user creation..."

echo -n "\t\tChecking that the 'winesap' user exists..."
grep -P -q "^${WINESAPOS_USER_NAME}:" ${WINESAPOS_INSTALL_DIR}/etc/passwd
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -n "\t\tChecking that the home directory for the 'winesap' user exists..."
if [ -d ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/ ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -n "Testing user creation complete.\n\n"

echo "Testing package repositories..."

echo -n "\tChecking that the winesapOS repository was added..."
if [[ "${WINESAPOS_ENABLE_TESTING_REPO}" == "false" ]]; then
    grep -q -P "^\[winesapos\]" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
else
    grep -q -P "^\[winesapos-testing\]" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
fi

echo -n "\tChecking that the winesapOS GPG key was added..."
chroot ${WINESAPOS_INSTALL_DIR} pacman-key --list-keys | grep -q 1805E886BECCCEA99EDF55F081CA29E4A4B01239
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -n "\tChecking that the Chaotic AUR repository was added..."
grep -q -P "^\[chaotic-aur\]" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -n "\tChecking that the Chaotic AUR GPG key was added..."
chroot ${WINESAPOS_INSTALL_DIR} pacman-key --list-keys | grep -q 3056513887B78AEB
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo "Testing package repositories complete."

echo "Testing package installations..."

function pacman_search() {
    chroot ${WINESAPOS_INSTALL_DIR} pacman -Qsq ${1} &> /dev/null
}

function pacman_search_loop() {
    for i in ${@}
        do echo -n "\t${i}..."
        pacman_search "${i}"
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    done
}

echo "\tChecking that the base system packages are installed..."
pacman_search_loop \
  accountsservice \
  efibootmgr \
  flatpak \
  fprintd \
  grub \
  inetutils \
  iwd \
  jq \
  lightdm \
  mkinitcpio \
  networkmanager

if [[ "${WINESAPOS_BUILD_CHROOT_ONLY}" == "false" ]]; then
    echo "\tChecking that the Linux kernel packages are installed..."
    if [[ "${WINESAPOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_search_loop linux-t2 linux-t2-headers linux61 linux61-headers linux-firmware
    elif [[ "${WINESAPOS_DISTRO}" == "arch" ]]; then
        pacman_search_loop linux-t2 linux-t2-headers linux-lts linux-lts-headers linux-firmware
    elif [[ "${WINESAPOS_DISTRO}" == "steamos" ]]; then
        pacman_search_loop linux-t2 linux-t2-headers linux-firmware linux-steamos linux-steamos-headers
    fi
fi

if [[ "${WINESAPOS_INSTALL_GAMING_TOOLS}" == "true" ]]; then
    echo "\tChecking that gaming tools are installed..."
    pacman_search_loop \
      gamemode \
      lib32-gamemode \
      gamescope \
      gamescope-session-git \
      gamescope-session-steam-git \
      goverlay-git \
      game-devices-udev \
      heroic-games-launcher-bin \
      lutris \
      mangohud \
      lib32-mangohud \
      opengamepadui-bin \
      openrazer-daemon \
      oversteer \
      replay-sorcery-git \
      vkbasalt \
      lib32-vkbasalt \
      wine-staging \
      winetricks \
      zenity \
      zerotier-one \
      zerotier-gui-git

    if [[ "${WINESAPOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_search_loop \
          steam-manjaro \
          steam-native
    else
        pacman_search_loop \
          steam \
          steam-native-runtime
    fi

    for i in \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/EmuDeck.AppImage
        do echo -n "\t\tChecking if the file ${i} exists..."
        if [ -f "${i}" ]; then
          echo PASS
        else
          winesapos_test_failure
        fi
    done

    echo -n "Checking if the razerd daemon is enabled..."
    chroot ${WINESAPOS_INSTALL_DIR} systemctl --quiet is-enabled razerd
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
fi

echo "\tChecking that the desktop environment packages are installed..."
pacman_search_loop \
  xorg-server \
  xorg-server \
  xorg-xinit \
  xterm \
  xf86-input-libinput

if [[ "${WINESAPOS_DISTRO}" == "steamos" ]]; then
    pacman_search_loop \
      lib32-mesa-steamos \
      mesa-steamos
else
    pacman_search_loop \
      lib32-mesa \
      mesa \
      xf86-video-nouveau
fi

if [[ "${WINESAPOS_DE}" == "cinnamon" ]]; then
    pacman_search_loop \
      cinnamon \
      maui-pix \
      xorg-server \
      xed

    if [[ "${WINESAPOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_search_loop \
            cinnamon-sounds \
            cinnamon-wallpapers \
            manjaro-cinnamon-settings \
            manjaro-settings-manager$ \
            adapta-maia-theme \
            kvantum-manjaro
    fi
elif [[ "${WINESAPOS_DE}" == "gnome" ]]; then
    pacman_search_loop \
      gnome \
      gnome-tweaks

    if [[ "${WINESAPOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_search_loop \
          manjaro-gnome-settings \
	  manjaro-settings-manager
    fi
elif [[ "${WINESAPOS_DE}" == "plasma" ]]; then
    pacman_search_loop \
      plasma-meta \
      plasma-nm \
      plasma-wayland-session \
      dolphin \
      ffmpegthumbs \
      gwenview \
      kdegraphics-thumbnailers \
      konsole \
      kate \
      kio-fuse \
      packagekit-qt5 \
      plasma5-themes-vapor-steamos

    if [[ "${WINESAPOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_search_loop \
            manjaro-kde-settings \
            manjaro-settings-manager-kcm \
            manjaro-settings-manager-knotifier \
            breath-classic-icon-themes \
            breath-wallpapers \
            plasma5-themes-breath \
            sddm-breath-theme
    fi
fi

if [[ "${WINESAPOS_AUTO_LOGIN}" == "true" ]]; then
    echo -n "\tChecking that auto login is enabled..."
    grep -q "autologin-user = ${WINESAPOS_USER_NAME}" ${WINESAPOS_INSTALL_DIR}/etc/lightdm/lightdm.conf
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that auto login session is Plasma (X11)..."
    grep -q "autologin-session = plasma" ${WINESAPOS_INSTALL_DIR}/etc/lightdm/lightdm.conf
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
fi

echo -n "\tChecking that the KDE Plasma Xorg session is enabled by default..."
grep -q -P "^XSession=plasma$" ${WINESAPOS_INSTALL_DIR}/var/lib/AccountsService/users/${WINESAPOS_USER_NAME}
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo "\tChecking that Bluetooth packages are installed..."
pacman_search_loop bluez bluez-utils blueman bluez-qt5
echo "\tChecking that Bluetooth packages are installed complete."

echo -n "\tChecking that the 'bluetooth' service is enabled..."
chroot ${WINESAPOS_INSTALL_DIR} systemctl --quiet is-enabled bluetooth.service
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -n "Testing package installations complete.\n\n"

echo "Testing Mac drivers installation..."
echo -e "\tChecking that the 'apple-bce' driver is loaded on boot..."
grep MODULES ${WINESAPOS_INSTALL_DIR}/etc/mkinitcpio.conf | grep -q apple-bce
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -e "\tChecking that the 'apple-touchbar' driver will load automatically..."
grep -q "install apple-touchbar" ${WINESAPOS_INSTALL_DIR}/etc/modprobe.d/winesapos-mac.conf
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -e "\tChecking that the 'radeon' driver will not load for specific older GPUs..."
grep -q "options radeon si_support=0" ${WINESAPOS_INSTALL_DIR}/etc/modprobe.d/winesapos-amd.conf
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -e "\tChecking that the AMDGPU workaround is configured..."
grep -q "options amdgpu noretry=0" ${WINESAPOS_INSTALL_DIR}/etc/modprobe.d/winesapos-amd.conf
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -e "\tChecking that GRUB is configured to workaround Mac Wi-Fi issues..."
grep -q "pcie_ports=compat" ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -e "\tChecking that 'linux-t2' is installed..."
pacman_search linux-t2
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -e "\tChecking that 'usbmuxd' is installed..."
pacman_search usbmuxd
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -e "\tChecking that newer udev rules for 'usbmuxd' are installed..."
grep -q "make sure iBridge (T1)" ${WINESAPOS_INSTALL_DIR}/usr/lib/udev/rules.d/39-usbmuxd.rules
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo -e "Testing Mac drivers installation complete.\n\n"

echo "Testing that all files have been copied over..."

for i in \
  ${WINESAPOS_INSTALL_DIR}/etc/systemd/user/winesapos-mute.service \
  ${WINESAPOS_INSTALL_DIR}/usr/local/bin/winesapos-mute.sh \
  ${WINESAPOS_INSTALL_DIR}/usr/local/bin/winesapos-resize-root-file-system.sh \
  ${WINESAPOS_INSTALL_DIR}/etc/systemd/system/winesapos-resize-root-file-system.service \
  ${WINESAPOS_INSTALL_DIR}/etc/systemd/system/lightdm.service.d/lightdm-restart-policy.conf \
  ${WINESAPOS_INSTALL_DIR}/etc/snapper/configs/root \
  ${WINESAPOS_INSTALL_DIR}/etc/winesapos/VERSION \
  ${WINESAPOS_INSTALL_DIR}/etc/winesapos/winesapos-install.log
    do echo -n "\t${i}..."
    if [ -f ${i} ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
done

echo -n "Testing that all files have been copied over complete.\n\n"

echo "Testing that services are enabled..."

for i in \
  auto-cpufreq \
  cups \
  lightdm \
  lightdm-success-handler \
  NetworkManager \
  winesapos-resize-root-file-system \
  snapd \
  snapper-cleanup-hourly.timer \
  snapper-timeline.timer \
  systemd-timesyncd
    do echo -n "\t${i}..."
    chroot ${WINESAPOS_INSTALL_DIR} systemctl --quiet is-enabled ${i}
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
done

if [[ "${WINESAPOS_APPARMOR}" == "true" ]]; then
    echo -n "\tapparmor..."
    chroot ${WINESAPOS_INSTALL_DIR} systemctl --quiet is-enabled apparmor
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
fi

echo -n "Testing that services are enabled complete.\n\n"

if [[ "${WINESAPOS_BUILD_CHROOT_ONLY}" == "false" ]]; then
    echo "Testing the bootloader..."

    echo -n "\tChecking that GRUB 2 has been installed..."
    dd if=${DEVICE} bs=512 count=1 2> /dev/null | strings | grep -q GRUB
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that the '/boot/grub/grub.cfg' file exists..."
    if [ -f ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n " \tChecking that the generic '/boot/efi/EFI/BOOT/BOOTX64.EFI' file exists..."
    if [ -f ${WINESAPOS_INSTALL_DIR}/boot/efi/EFI/BOOT/BOOTX64.EFI ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that the GRUB terminal is set to 'console'..."
    grep -q "terminal_input console" ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that the GRUB timeout has been set to 10 seconds..."
    grep -q "set timeout=10" ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that the GRUB timeout style been set to 'menu'..."
    grep -q "set timeout_style=menu" ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that GRUB is configured to save the default kernel..."
    grep savedefault ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg | grep -v "function savedefault" | grep -q savedefault
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo "\tChecking that GRUB has command line arguments for faster input device polling..."
    for i in usbhid.jspoll=1 usbhid.kbpoll=1 usbhid.mousepoll=1
        do echo -n "\t${i}..."
        grep -q "${i}" ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    done
    echo "\tChecking that GRUB has command line arguments for faster input device polling complete."

    echo -n "\tChecking that GRUB has the command line argument for the 'none' I/O scheduler..."
    grep -q "elevator=none" ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that GRUB has the command line argument to enable older Intel iGPUs..."
    grep -q 'i915.force_probe=*' ${WINESAPOS_INSTALL_DIR}/boot/grub/grub.cfg
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that the Vimix theme for GRUB exists..."
    if [ -f ${WINESAPOS_INSTALL_DIR}/boot/grub/themes/Vimix/theme.txt ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that the Vimix theme for GRUB is enabled..."
    grep -q -P "^GRUB_THEME=/boot/grub/themes/Vimix/theme.txt" ${WINESAPOS_INSTALL_DIR}/etc/default/grub
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that GRUB is set to use resolutions supported by our theme..."
    grep -q -P "^GRUB_GFXMODE=1280x720,auto" ${WINESAPOS_INSTALL_DIR}/etc/default/grub
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi

    echo -n "\tChecking that GRUB is set to use the text GFX payload for better boot compatibility..."
    grep -q -P "^GRUB_GFXPAYLOAD_LINUX=text" ${WINESAPOS_INSTALL_DIR}/etc/default/grub
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
    echo "Testing the bootloader complete."
fi

echo "Testing that 'yay' is installed..."
echo -n "\tChecking for the 'yay' binary..."
if [ -f ${WINESAPOS_INSTALL_DIR}/usr/bin/yay ]; then
    echo PASS
else
    winesapos_test_failure
fi

if [[ "${WINESAPOS_DISTRO}" == "steamos" ]]; then
    if [[ "${WINESAPOS_DISTRO_DETECTED}" == "steamos" ]]; then
        echo "\tChecking that the 'yay-git' package is installed..."
        pacman_search_loop yay-git
        echo "\tChecking that the 'yay-git' package is installed complete."
    elif [[ "${WINESAPOS_DISTRO_DETECTED}" == "arch" ]]; then
        echo "\tChecking that the 'yay' package is installed..."
        pacman_search_loop yay
        echo "\tChecking that the 'yay' package is installed complete."
    fi
fi

echo "Testing that 'yay' is complete..."

echo -n "Checking that 'pacman-static' is installed..."
if [ -f ${WINESAPOS_INSTALL_DIR}/usr/local/bin/pacman-static ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo "Testing desktop shortcuts..."
for i in \
  ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/appimagepool.desktop \
  ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/bauh.desktop \
  ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/blueman-manager.desktop \
  ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/firefox-esr.desktop \
  ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/terminator.desktop
    do echo -n "\t\tChecking if the file ${i} exists..."
    if [ -f "${i}" ]; then
      echo PASS
    else
      winesapos_test_failure
    fi
done

if [[ "${WINESAPOS_INSTALL_GAMING_TOOLS}" == "true" ]]; then

    for i in \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/decky_installer.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/io.github.benjamimgois.goverlay.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/ludusavi.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/org.berarma.Oversteer.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/razercfg.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/steam.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/steam_deck_runtime.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/steamtinkerlaunch.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/zerotier-gui.desktop
        do echo -n "\t\tChecking if the file ${i} exists..."
        if [ -f "${i}" ]; then
          echo PASS
        else
          winesapos_test_failure
        fi
    done

    for i in \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/heroic_games_launcher.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/lutris.desktop
        do echo -n "\t\tChecking if gamemoderun is configured for file ${i}..."
        grep -q -P "^Exec=/usr/bin/gamemoderun " "${i}"
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    done

fi

if [[ "${WINESAPOS_INSTALL_PRODUCTIVITY_TOOLS}" == "true" ]]; then
    for i in \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/balenaEtcher.AppImage \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/clamtk.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/gparted.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/qdirstat.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/org.kde.spectacle.desktop \
      ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/veracrypt.desktop
        do echo -n "\t\tChecking if the file ${i} exists..."
        if [ -f "${i}" ]; then
          echo PASS
        else
          winesapos_test_failure
        fi
    done
fi

if [[ "${WINESAPOS_FIREWALL}" == "true" ]]; then
    i="${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/firewall-config.desktop"
    echo -n "\t\tChecking if the file ${i} exists..."
    if [ -f "${i}" ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
fi

if [[ "${WINESAPOS_DE}" == "cinnamon" ]]; then
    x=("${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/nemo.desktop" "${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/org.kde.pix.desktop")
elif [[ "${WINESAPOS_DE}" == "gnome" ]]; then
    x=("${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/org.gnome.eog.desktop" "${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/org.gnome.Nautilus.desktop")
elif [[ "${WINESAPOS_DE}" == "plasma" ]]; then
    x=("${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/org.kde.dolphin.desktop" "${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/Desktop/org.kde.gwenview.desktop")
fi

for y in $x;
    do echo -n "\t\tChecking if the file ${y} exists..."
    if [ -f "${y}" ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
done
echo "Testing desktop shortcuts complete."

echo -n "Testing that Oh My Zsh is installed..."
if [ -f ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/.zshrc ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo "Testing that Oh My Zsh is installed complete."

echo -n "Testing that the mkinitcpio hooks are loaded in the correct order..."
if [[ "${WINESAPOS_ENCRYPT}" == "true" ]]; then
    grep -q "HOOKS=(base udev block keyboard keymap autodetect modconf encrypt filesystems fsck)" ${WINESAPOS_INSTALL_DIR}/etc/mkinitcpio.conf
    hooks_result="$?"
else
    grep -q "HOOKS=(base udev block keyboard autodetect modconf filesystems fsck)" ${WINESAPOS_INSTALL_DIR}/etc/mkinitcpio.conf
    hooks_result="$?"
fi
if [ "${hooks_result}" -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo "Testing that the mkinitcpio hooks are loaded in the correct order complete."

echo -n "Testing that ParallelDownloads is enabled in Pacman..."
grep -q -P "^ParallelDownloads" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo "Testing that ParallelDownloads is enabled in Pacman complete."

echo -n "Testing that Pacman is configured to use 'wget'..."
grep -q 'XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u' ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo -n "Testing that Pacman is configured to use 'wget' complete."

echo "Testing that the machine-id was reset..."
echo -n "\t\tChecking that the /etc/machine-id file is empty..."
if [[ "$(cat ${WINESAPOS_INSTALL_DIR}/etc/machine-id)" == "" ]]; then
    echo PASS
else
    winesapos_test_failure
fi
echo -n "\t\tChecking that /var/lib/dbus/machine-id is a symlink..."
if [[ -L ${WINESAPOS_INSTALL_DIR}/var/lib/dbus/machine-id ]]; then
    echo PASS
else
    winesapos_test_failure
fi
echo "Testing that the machine-id was reset complete."

if [[ "${WINESAPOS_INSTALL_PRODUCTIVITY_TOOLS}" == "true" ]]; then
    echo "Testing that the offline ClamAV databases were downloaded..."
    for i in bytecode daily main; do
        echo -n "\t${i}..."
        if [[ -f ${WINESAPOS_INSTALL_DIR}/var/lib/clamav/${i}.cvd ]]; then
            echo PASS
        else
            if [[ -f ${WINESAPOS_INSTALL_DIR}/var/lib/clamav/${i}.cld ]]; then
                echo PASS
            else
                winesapos_test_failure
            fi
        fi
    done
    echo "Testing that the offline ClamAV databases were downloaded complete."
fi

if [[ "${WINESAPOS_FIREWALL}" == "true" ]]; then
    echo -n "Testing that the firewall has been installed..."
    if [[ -f ${WINESAPOS_INSTALL_DIR}/usr/bin/firewalld ]]; then
        echo PASS
    else
        winesapos_test_failure
    fi
fi

WINESAPOS_CPU_MITIGATIONS="${WINESAPOS_CPU_MITIGATIONS:-false}"
if [[ "${WINESAPOS_CPU_MITIGATIONS}" == "false" ]]; then
    echo -n "Testing that CPU mitigations are disabled in the Linux kernel..."
    grep -q "mitigations=off" ${WINESAPOS_INSTALL_DIR}/etc/default/grub
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
fi

WINESAPOS_DISABLE_KERNEL_UPDATES="${WINESAPOS_DISABLE_KERNEL_UPDATES:-true}"
if [[ "${WINESAPOS_DISABLE_KERNEL_UPDATES}" == "true" ]]; then
    echo -n "Testing that Pacman is configured to disable Linux kernel updates..."
    if [[ "${WINESAPOS_DISTRO}" == "manjaro" ]]; then
        grep -q "IgnorePkg = linux61 linux61-headers linux-t2 linux-t2-headers filesystem" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    elif [[ "${WINESAPOS_DISTRO}" == "arch" ]]; then
        grep -q "IgnorePkg = linux-lts linux-lts-headers linux-t2 linux-t2-headers filesystem" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    elif [[ "${WINESAPOS_DISTRO}" == "steamos" ]]; then
        if [[ "${WINESAPOS_DISTRO_DETECTED}" == "steamos" ]]; then
            grep -q "IgnorePkg = linux-t2 linux-t2-headers linux-steamos linux-steamos-headers linux-firmware-neptune linux-firmware-neptune-rtw-debug grub filesystem" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
            if [ $? -eq 0 ]; then
                echo PASS
            else
                winesapos_test_failure
            fi
        else
            grep -q "IgnorePkg = linux-t2 linux-t2-headers linux-steamos linux-steamos-headers linux-firmware-neptune linux-firmware-neptune-rtw-debug filesystem" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
            if [ $? -eq 0 ]; then
                echo PASS
            else
                winesapos_test_failure
            fi
        fi
    fi
else
    if [[ "${WINESAPOS_DISTRO}" == "steamos" ]]; then
        if [[ "${WINESAPOS_DISTRO_DETECTED}" == "steamos" ]]; then
            echo -n "Testing that Pacman is configured to disable conflicting SteamOS package updates..."
            grep -q "IgnorePkg = linux-lts linux-lts-headers linux-firmware-neptune linux-firmware-neptune-rtw-debug grub filesystem" ${WINESAPOS_INSTALL_DIR}/etc/pacman.conf
            if [ $? -eq 0 ]; then
                echo PASS
            else
                winesapos_test_failure
            fi
        fi
    fi
fi

echo -n '\tChecking that the locale has been set...'
chroot ${WINESAPOS_INSTALL_DIR} locale --all-locales | grep -i "en_US.utf8"
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -n "\tChecking that the hostname is set..."
grep -q -P "^winesapos$" ${WINESAPOS_INSTALL_DIR}/etc/hostname
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -n "\tChecking that the hosts file is configured..."
grep -q -P "^127.0.1.1    winesapos$" ${WINESAPOS_INSTALL_DIR}/etc/hosts
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo "\tChecking that all the packages from the AUR have been installed by yay..."
pacman_search_loop \
    appimagelauncher \
    appimagepool-appimage \
    auto-cpufreq \
    bauh \
    cloud-guest-utils \
    firefox-esr \
    hfsprogs \
    mbpfan-git \
    oh-my-zsh-git \
    paru \
    python-crudini \
    python-iniparse \
    python-tests \
    snapd

if [[ "${WINESAPOS_INSTALL_PRODUCTIVITY_TOOLS}" == "true" ]]; then
    pacman_search_loop \
      clamav \
      gparted \
      qdirstat
fi

if [[ "${WINESAPOS_DISTRO_DETECTED}" != "manjaro" ]]; then
    pacman_search_loop \
      lightdm-settings \
      zsh
    if [[ "${WINESAPOS_APPARMOR}" == "true" ]]; then
        pacman_search_loop \
          apparmor \
          krathalans-apparmor-profiles-git
    fi
else
    pacman_search_loop \
      zsh
    if [[ "${WINESAPOS_APPARMOR}" == "true" ]]; then
        pacman_search_loop \
          apparmor \
          apparmor-profiles
    fi
fi
echo "\tChecking that all the packages from the AUR have been installed by yay done."

echo 'Testing that the PipeWire audio library is installed...'
echo "\tChecking that PipeWire packages are installed..."
pacman_search_loop \
  pavucontrol \
  libpipewire \
  lib32-libpipewire \
  pipewire-alsa \
  pipewire-jack \
  lib32-pipewire-jack \
  pipewire-pulse \
  pipewire-v4l2 \
  lib32-pipewire-v4l2 \
  wireplumber
echo "\tChecking that PipeWire packages are installed complete."

echo "\tChecking that PipeWire services are enabled..."
for i in \
  winesapos-mute.service \
  pipewire.service \
  pipewire-pulse.service
    do echo -n "\t${i}..."
    ls "${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/.config/systemd/user/default.target.wants/${i}" &> /dev/null
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
done
echo "\tChecking that PipeWire services are enabled complete."
echo 'Testing that the PipeWire audio library is installed complete.'

echo 'Testing that support for all file systems is installed...'
pacman_search_loop \
  apfsprogs-git \
  btrfs-progs \
  cifs-utils \
  dosfstools \
  e2fsprogs \
  erofs-utils \
  exfatprogs \
  f2fs-tools \
  fatx \
  hfsprogs \
  jfsutils \
  linux-apfs-rw-dkms-git \
  mtools \
  nfs-utils \
  ntfs-3g \
  reiserfsprogs \
  reiserfs-defrag \
  ssdfs-tools \
  xfsprogs \
  zfs-dkms \
  zfs-utils

echo -n "\tChecking for the existence of '/etc/modules-load.d/winesapos-file-systems.conf'..."
ls ${WINESAPOS_INSTALL_DIR}/etc/modules-load.d/winesapos-file-systems.conf &> /dev/null
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo 'Testing that support for all file systems is installed complete.'

if [[ "${WINESAPOS_DISTRO}" == "steamos" ]]; then
    if [[ "${WINESAPOS_DE}" == "plasma" ]]; then
        echo "Testing that the Vapor theme has been configured for Konsole..."
        grep -q "DefaultProfile=Vapor.profile" ${WINESAPOS_INSTALL_DIR}/etc/xdg/konsolerc
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
        echo "Testing that the Vapor theme has been configured for Konsole complete."
    fi
fi

echo -n "\tChecking that the correct operating system was installed..."
grep -q "ID=${WINESAPOS_DISTRO}" ${WINESAPOS_INSTALL_DIR}/etc/os-release
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo -n "\tChecking that the sudoers file for 'winesap' is correctly configured..."
if [[ "${WINESAPOS_SUDO_NO_PASSWORD}" == "true" ]]; then
    grep -q "${WINESAPOS_USER_NAME} ALL=(root) NOPASSWD:ALL" ${WINESAPOS_INSTALL_DIR}/etc/sudoers.d/${WINESAPOS_USER_NAME}
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
elif [[ "${WINESAPOS_SUDO_NO_PASSWORD}" == "false" ]]; then
    grep -q "${WINESAPOS_USER_NAME} ALL=(root) ALL" ${WINESAPOS_INSTALL_DIR}/etc/sudoers.d/${WINESAPOS_USER_NAME}
    if [ $? -eq 0 ]; then
        grep -q "${WINESAPOS_USER_NAME} ALL=(root) NOPASSWD: /usr/bin/dmidecode" ${WINESAPOS_INSTALL_DIR}/etc/sudoers.d/${WINESAPOS_USER_NAME}
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    else
        winesapos_test_failure
    fi
fi

echo -n "\tChecking that the sudo timeout has been increased..."
grep -q "Defaults:${WINESAPOS_USER_NAME} passwd_tries=20,timestamp_timeout=-1" ${WINESAPOS_INSTALL_DIR}/etc/sudoers.d/${WINESAPOS_USER_NAME}
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo "Testing that winesapOS desktop applications exist..."
for i in \
  /home/${WINESAPOS_USER_NAME}/.winesapos/winesapos-setup.sh \
  /home/${WINESAPOS_USER_NAME}/.winesapos/winesapos-setup.desktop \
  /home/${WINESAPOS_USER_NAME}/.config/autostart/winesapos-setup.desktop \
  /home/${WINESAPOS_USER_NAME}/Desktop/winesapos-setup.desktop \
  /home/${WINESAPOS_USER_NAME}/.winesapos/winesapos-upgrade-remote-stable.sh \
  /home/${WINESAPOS_USER_NAME}/.winesapos/winesapos-upgrade.desktop \
  /home/${WINESAPOS_USER_NAME}/Desktop/winesapos-upgrade.desktop \
  /home/${WINESAPOS_USER_NAME}/.winesapos/winesapos_logo_icon.png;
    do echo -n "\t${i}..."
    ls "${WINESAPOS_INSTALL_DIR}${i}" &> /dev/null
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
done
echo "Testing that winesapOS desktop applications exist complete."

if [[ "${WINESAPOS_ENABLE_KLIPPER}" == "false" ]]; then
    echo "Testing that Klipper has been disabled..."
    echo "\tChecking that Klipper settings are configured..."
    for i in "KeepClipboardContents = false" "MaxClipItems = 1" "PreventEmptyClipboard = false";
	do echo -n -e "\t${i}..."
	grep -q -P "^${i}" ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/.config/klipperrc
        if [ $? -eq 0 ]; then
            echo PASS
        else
            winesapos_test_failure
        fi
    done
    echo -n "\tChecking that the Klipper directory is mounted as a RAM file system..."
    grep -q "ramfs    /home/${WINESAPOS_USER_NAME}/.local/share/klipper    ramfs    rw,nosuid,nodev    0 0" ${WINESAPOS_INSTALL_DIR}/etc/fstab
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
    echo "Testing that Klipper has been disabled complete."
fi

echo "Checking that the default text editor has been set..."
grep -q "EDITOR=nano" ${WINESAPOS_INSTALL_DIR}/etc/environment
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo "Checking that the default text editor has been set complete."

echo "Checking that NetworkManager is using IWD as the backend..."
grep -q "wifi.backend=iwd" ${WINESAPOS_INSTALL_DIR}/etc/NetworkManager/conf.d/wifi_backend.conf
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi

echo "Checking that the ${WINESAPOS_USER_NAME} user name has been set in desktop shortcuts for the setup and upgrade..."
for i in winesapos-setup.desktop winesapos-upgrade.desktop;
    do echo -n -e "\t${i}..."
    grep -q "/home/${WINESAPOS_USER_NAME}" ${WINESAPOS_INSTALL_DIR}/home/${WINESAPOS_USER_NAME}/.winesapos/${i}
    if [ $? -eq 0 ]; then
        echo PASS
    else
        winesapos_test_failure
    fi
done
echo "Checking that the ${WINESAPOS_USER_NAME} user name has been set in desktop shortcuts for the setup and upgrade done."

echo "Checking that the proprietary Broadcom Wi-Fi drivers are available for offline use..."
ls -1 ${WINESAPOS_INSTALL_DIR}/var/lib/winesapos/ | grep -q broadcom-wl-dkms
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo "Checking that the proprietary Broadcom Wi-Fi drivers are available for offline use complete."

echo "Checking that a symlink was created for the 'deck' usesr for compatibility purposes..."
ls -lah ${WINESAPOS_INSTALL_DIR}/home/deck | grep -P "^lrwx"
if [ $? -eq 0 ]; then
    echo PASS
else
    winesapos_test_failure
fi
echo "Checking that a symlink was created for the 'deck' usesr for compatibility purposes complete."

echo "Tests end time: $(date)"

if (( ${failed_tests} == 0 )); then
    exit 0
else
    exit ${failed_tests}
fi
