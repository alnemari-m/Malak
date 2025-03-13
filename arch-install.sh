#!/bin/bash
#
# Automated Arch Linux Installation Script
# =======================================
# This script automates the installation of Arch Linux.
# IMPORTANT: This script should be run from the Arch Linux live environment.
# WARNING: This script will erase all data on the selected disk.

set -e  # Exit on error

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions for output
print_header() {
    echo -e "\n${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_step() {
    echo -e "${YELLOW}-->${NC} $1"
}

print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

get_input() {
    local prompt="$1"
    local default="$2"
    local input=""
    
    if [ -n "$default" ]; then
        prompt="$prompt [$default]"
    fi
    
    read -p "$prompt: " input
    
    if [ -z "$input" ] && [ -n "$default" ]; then
        input="$default"
    fi
    
    echo "$input"
}

# Welcome message
clear
echo -e "${GREEN}"
echo "=================================================="
echo "       Automated Arch Linux Installation"
echo "=================================================="
echo -e "${NC}"
echo "This script will automatically install Arch Linux."
echo "IMPORTANT: This will ERASE ALL DATA on the selected disk."
echo ""
read -p "Press Enter to continue, or Ctrl+C to abort..."

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Check if booted in UEFI mode
if [ ! -d "/sys/firmware/efi/efivars" ]; then
    print_error "Not booted in UEFI mode. This script only supports UEFI installations."
    exit 1
fi

# Check internet connection
print_header "Checking internet connection"
if ! ping -c 3 archlinux.org &>/dev/null; then
    print_error "No internet connection. Please connect to the internet first."
    exit 1
fi
print_success "Internet connection is working"

# Update system clock
print_header "Updating system clock"
timedatectl set-ntp true
print_success "System clock updated"

# Disk selection
print_header "Disk Selection"
echo "Available disks:"
lsblk -d -p -n -l -o NAME,SIZE,MODEL | grep -v "loop"
echo ""

DISK=$(get_input "Enter the full disk path (e.g., /dev/sda or /dev/nvme0n1)" "")
if [ -z "$DISK" ]; then
    print_error "No disk selected"
    exit 1
fi

if [ ! -b "$DISK" ]; then
    print_error "Invalid disk: $DISK"
    exit 1
fi

echo ""
echo -e "${RED}WARNING: All data on $DISK will be erased!${NC}"
read -p "Are you sure you want to continue? (Type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_error "Installation aborted by user"
    exit 1
fi

# Disk partitioning
print_header "Partitioning disk"
print_step "Creating GPT partition table"
parted -s "$DISK" mklabel gpt

# Determine disk prefix (for naming partitions)
if [[ "$DISK" =~ "nvme" ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

# Create partitions
print_step "Creating EFI System Partition (ESP)"
parted -s "$DISK" mkpart "EFI" fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

print_step "Creating swap partition"
MEMORY_SIZE=$(grep MemTotal /proc/meminfo | awk '{print $2}')
# Convert to MiB and calculate swap size (equal to RAM up to 8GB, half after that)
MEMORY_SIZE_MB=$((MEMORY_SIZE / 1024))
if [ "$MEMORY_SIZE_MB" -le 8192 ]; then
    SWAP_SIZE_MB=$MEMORY_SIZE_MB
else
    SWAP_SIZE_MB=$((8192 + (MEMORY_SIZE_MB - 8192) / 2))
fi
SWAP_END=$((513 + SWAP_SIZE_MB))
parted -s "$DISK" mkpart "swap" linux-swap 513MiB "${SWAP_END}MiB"

print_step "Creating root partition"
parted -s "$DISK" mkpart "root" ext4 "${SWAP_END}MiB" 100%
print_success "Partitioning completed"

# Format partitions
print_header "Formatting partitions"
print_step "Formatting EFI partition (FAT32)"
mkfs.fat -F32 "${PART_PREFIX}1"

print_step "Setting up swap"
mkswap "${PART_PREFIX}2"
swapon "${PART_PREFIX}2"

print_step "Formatting root partition (ext4)"
mkfs.ext4 "${PART_PREFIX}3"
print_success "Formatting completed"

# Mount partitions
print_header "Mounting partitions"
print_step "Mounting root partition"
mount "${PART_PREFIX}3" /mnt

print_step "Creating and mounting EFI directory"
mkdir -p /mnt/boot/efi
mount "${PART_PREFIX}1" /mnt/boot/efi
print_success "Mounting completed"

# Installation configuration
print_header "Installation configuration"

# Timezone selection (with default)
TIMEZONE=$(get_input "Enter your timezone (e.g., America/New_York, Europe/London)" "UTC")

# Locale selection (with default)
LOCALE=$(get_input "Enter your locale (e.g., en_US.UTF-8)" "en_US.UTF-8")

# Hostname
HOSTNAME=$(get_input "Enter hostname for the system" "archlinux")

# User account
USERNAME=$(get_input "Enter username for the new user" "user")

# Install base system
print_header "Installing base system (this may take a while)"
pacstrap /mnt base linux linux-firmware base-devel

# Install necessary packages
print_step "Installing additional necessary packages"
pacstrap /mnt dhcpcd networkmanager sudo vim nano grub efibootmgr

# Generate fstab
print_header "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab
print_success "fstab generated"

# Configure the system
print_header "Configuring the system"

# Create script to run inside chroot
cat > /mnt/root/setup.sh << EOF
#!/bin/bash
set -e

# Time zone
echo "Setting timezone to $TIMEZONE..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
echo "Configuring locale..."
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Network configuration
echo "Configuring network..."
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOL
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOL

# Enable network services
systemctl enable NetworkManager
systemctl enable dhcpcd

# Create user and set passwords
echo "Creating user account..."
useradd -m -G wheel -s /bin/bash $USERNAME

echo "Setting root password..."
echo "root:password" | chpasswd
echo "Setting user password..."
echo "$USERNAME:password" | chpasswd

# Configure sudo
echo "Configuring sudo..."
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Install and configure bootloader
echo "Installing bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "System configuration completed."
EOF

# Make the script executable
chmod +x /mnt/root/setup.sh

# Chroot into the new system and run the setup script
print_step "Configuring system inside chroot..."
arch-chroot /mnt /root/setup.sh

# Clean up
rm /mnt/root/setup.sh

# Unmount partitions
print_header "Finishing installation"
print_step "Unmounting partitions"
umount -R /mnt

print_success "Installation completed successfully!"
echo ""
echo "==================================================="
echo "Installation is complete. You can now reboot into your new Arch Linux system."
echo ""
echo "IMPORTANT:"
echo "1. Default username: $USERNAME"
echo "2. Default password for both root and $USERNAME: password"
echo "3. CHANGE THESE PASSWORDS IMMEDIATELY AFTER FIRST LOGIN!"
echo ""
echo "To reboot, run: systemctl reboot"
echo "==================================================="
