# =============================================
#	      Arch-Linux Installer
#
#  *******************************************
#  * DO NOT JUST RUN THIS SCRIPT!!!!!!!!!!!! *
#  * This repartitions the device its run on *
#  * And can lead to a complete wipe of your *
#  * system. Please read. You've been warned *
#  *******************************************
#
#  - script to install arch linux 
#    on an efi system
#
#  - great for installs on clean efi enabled
#    virtual machines and newer computers
#
#      REQUIRES (For current settings)
#      ===============================
#    - Bootable medium with Arch UEFI Image
#    - Clean partition
#    - If drive isn't "sda" change DRIVE variable
#    - At LEAST 49GB space
#    - An internet connection. (Ethernet or through VM)
#
#>>> USE: ./install_arch_efi.sh
#
#      ***AFTER you boot into Arch
#	      live media enviornment
#      ***Secure copy from your
#	      host machine, chmod, and run.
# ============================================

# Variables
DRIVE=/dev/sda		# change this if drive is different
EFI=1               # EFI will have fixed size (512 MB) 
SWAP=2
SWAP_SIZE=8		    # size in GB
ROOT=3
ROOT_SIZE=40		# size in GB
SIG=2094763 		# Sections In a Gigabyte

USER=slick
HOSTNAME=archie


printf "*******************************************************\n"
printf "*                                                     *\n"
printf "* This script is not a joke! It WILL wipe your system *\n"
printf "*   DO NOT run this unless you have read through it,  *\n"
printf "*     I'ts not really that long and is one file.      *\n"
printf "*                                                     *\n"
printf "*       Press [CTRL + C] to EXIT PROCESS NOW!         *\n"
printf "*    Press [ENTER] to start the install process...    *\n"
printf "*                                                     *\n"
printf "*******************************************************\n"

echo

read -p "Press [ENTER] to start."

# update system clock
timedatectl set-ntp true

# partition disks
echo "label: gpt" | sudo sfdisk $DRIVE
printf ",%d,U,*\n,%d,S\n,%d" $(( $SIG / 2 )) $(( $SWAP_SIZE * $SIG )) $(( $ROOT_SIZE * $SIG )) | sfdisk $DRIVE
#   Partition Scheme
#
#   - Single drive split to 3 partitions
#
#       * 1st: EFI File System      [512 MB]
#       * 2nd: Linux Swap Partition   [8 GB]
#       * 3rd: Linux File System     [40 GB]

# format the disks / activate swap
mkfs.fat -F32 $DRIVE$EFI
mkfs.ext4 $DRIVE$ROOT
mkswap $DRIVE$SWAP
swapon $DRIVE$SWAP

# mount root partition
mount $DRIVE$ROOT /mnt

# install base level packages
pacstrap /mnt base base-devel linux linux-firmware vim networkmanager man

# generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# create chroot.sh file
if [[ -f chroot.sh ]]; then
	rm chroot.sh
fi
touch chroot.sh
echo "# Main Variables" > chroot.sh
echo "EFI=$EFI" >> chroot.sh
printf "DRIVE=%s\n\n" $DRIVE >> chroot.sh
echo "# Variables for Auto Setup" >> chroot.sh
echo "username=$USER" >> chroot.sh
printf "hostname=%s\n\n" $HOSTNAME >> chroot.sh
echo "# sync hardware clock" >> chroot.sh
printf "hwclock --systohc\n\n" >> chroot.sh
echo "# set locale" >> chroot.sh
printf "sed -i \"s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/\" /etc/locale.gen\n" >> chroot.sh
printf "locale-gen\n" >> chroot.sh
echo "ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime" >> chroot.sh
echo "# give system a hostname" >> chroot.sh
echo "if [[ ! -f /etc/hostname ]]; then" >> chroot.sh
printf "\ttouch /etc/hostname\n" >> chroot.sh
echo "fi" >> chroot.sh
printf "echo \$hostname > /etc/hostname\n\n" >> chroot.sh
echo "# set up hosts file" >> chroot.sh
printf 'printf \"127.0.0.1\\tlocalhost\\n::1\\t\\tlocalhost\\n127.0.1.1\\t%%s\\n\" $hostname > /etc/hosts\n' >> chroot.sh
printf "\n" >> chroot.sh
echo "# enable network manager" >> chroot.sh
printf "systemctl enable NetworkManager\n" >> chroot.sh
printf "pacman -S --noconfirm openssh\n\n" >> chroot.sh
echo "# install bootloader" >> chroot.sh
echo "pacman -S --noconfirm grub efibootmgr dosfstools os-prober mtools" >> chroot.sh
echo "mkdir /boot/EFI" >> chroot.sh
echo "mount \$DRIVE\$EFI /boot/EFI" >> chroot.sh
echo "grub-install --efi-directory=/boot/EFI \$DRIVE" >> chroot.sh
printf "grub-mkconfig -o /boot/grub/grub.cfg\n\n" >> chroot.sh
printf "echo\n\n" >> chroot.sh
echo "printf \"Set Root Password\n==================\n\"" >> chroot.sh
echo "passwd" >> chroot.sh
echo "useradd -mg users -G wheel -s /bin/bash \$username" >> chroot.sh
echo "echo" >> chroot.sh
echo "printf \"Set User %s's Password\n======================\n\"" $USER >> chroot.sh
echo "passwd \$username" >> chroot.sh
echo "# set up new user in sudo" >> chroot.sh
printf "sed -i \"s/# %%wheel ALL=(ALL) ALL/%%wheel ALL=(ALL) ALL/\" /etc/sudoers\n\n" >> chroot.sh
echo "exit" >> chroot.sh

# send and run config script on new system
cp chroot.sh /mnt
chmod 755 /mnt/chroot.sh
arch-chroot /mnt ./chroot.sh

# finish and reboot
printf "\nInstall Complete!\n\n"
read -p "[Press ENTER to reboot.]"
reboot

