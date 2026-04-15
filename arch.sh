#!/bin/bash

# =================================================================
# Arch Linux RTX 3070 終極一鍵安裝腳本 (Niri + Blender + Virtualization)
# =================================================================

set -e # 遇到錯誤停止

echo "--- 1. 更新系統並安裝所有軟體包 (Pacman) ---"
# 分類軟體清單
DRIVERS="nvidia-open nvidia-utils cuda nvidia-container-toolkit libva-nvidia-driver intel-ucode"
TOOLS="wget curl git p7zip unrar unzip zip python nodejs npm base-devel"
SYSTEM="gparted openssh neovim ripgrep htop nvtop fastfetch fish mpv pandoc blender"
FONTS="ttf-jetbrains-mono-nerd noto-fonts-cjk fcitx5-im fcitx5-chewing"
DESKTOP="niri xwayland-satellite fuzzel alacritty xdg-desktop-portal wl-clipboard mako hyprlock nautilus gvfs libnautilus-extension polkit-kde-agent xorg-xhost nwg-look"
VIRT="ufw tailscale qemu-desktop libvirt dnsmasq libguestfs virt-manager docker docker-compose"

sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm $DRIVERS $TOOLS $SYSTEM $FONTS $DESKTOP $VIRT

echo "--- 2. 修改 faillock 設定 (防止密碼鎖死) ---"
sudo sed -i 's/^#\?deny = .*/deny = 0/' /etc/security/faillock.conf

echo "--- 3. 設定 /etc/environment (NVIDIA & Wayland 優化) ---"
sudo bash -c 'cat > /etc/environment <<EOF
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
ELECTRON_OZONE_PLATFORM_HINT=auto
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
ENABLE_VULKAN_RENDERER=1
NVD_BACKEND=direct
EOF'

echo "--- 4. 設定 mkinitcpio (預載驅動) ---"
# 加入 i915 (Intel) 與 nvidia 系列模組
sudo sed -i 's/^MODULES=(.*/MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
sudo mkinitcpio -P

echo "--- 5. 安裝 yay (在暫存區編譯) ---"
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  # 不需要手動刪除，重啟後自動消失
fi

echo "--- 6. 使用 yay 安裝其餘軟體 ---"
yay -S --noconfirm google-chrome tty-clock mpvpaper 

echo "--- 7. 啟動所有系統服務 ---"
services=(tailscaled docker ufw)
for svc in "${services[@]}"; do
  sudo systemctl enable --now "$svc"
done

echo "--- 9. 使用者權限設定 ---"
sudo usermod -aG kvm,docker $USER

echo "--- 10. 網路與字體設定 ---"
sudo tailscale up --ssh
fc-cache -fv

echo "--- 11. 從 GitHub 恢復 Dotfiles 設定 ---"
DOTFILES_REPO="https://github.com/st-428/my-config.git"
TEMP_DOTFILES="/tmp/my_dotfiles"

# 1. 抓取倉庫到暫存區
git clone $DOTFILES_REPO $TEMP_DOTFILES

# 2. 同步到 .config (排除 .git 和 nvim，並避開本地重要目錄)
# 注意：$TEMP_DOTFILES/ 後面的斜槓很重要，代表同步「資料夾內的內容」
rsync -av \
  --exclude='.git/' \
  --exclude='nvim/' \
  --exclude='google-chrome/' \
  --exclude='fcitx/' \
  $TEMP_DOTFILES/ $HOME/.config/

echo "--- 12. 清理暫存 ---"
rm -rf $TEMP_DOTFILES

echo "-------------------------------------------------------"
echo "✅ 所有軟體安裝與服務設定完成！"
echo "⚠️  提醒：請確保 GRUB 已加入 nvidia_drm.modeset=1 並更新。"
echo "請打入：sudo cat /sys/module/nvidia_drm/parameters/modeset"
echo "🚀 建議立即執行：sudo reboot"
echo "-------------------------------------------------------"
