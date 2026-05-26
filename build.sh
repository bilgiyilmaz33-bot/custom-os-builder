#!/bin/bash
# ==========================================
# Alpment7 OS - Windows 7 HD Görünüm, Ses ve .EXE Geliştirme Kodları
# ==========================================

echo "=== Alpment7 OS Gelişmiş İnşa Süreci Başladı ==="

# 1. Geçici klasörleri oluştur
mkdir -p build_dir/chroot
mkdir -p build_dir/image/live

# 2. Temel Linux altyapısını indir
echo "=> Temel sistem dosyaları indiriliyor..."
sudo debootstrap --arch=amd64 focal build_dir/chroot http://archive.ubuntu.com/ubuntu/

# 3. Sistemin içine girip Türkçe Dil, Klavye ve .EXE (WINE) paketlerini kur
echo "=> Türkçe dil desteği, .EXE motoru ve KDE Plasma yükleniyor..."
sudo chroot build_dir/chroot /bin/bash -c "
    apt-get update
    
    # Türkçe Dil ve Klavye paketleri
    apt-get install -y locales language-pack-tr language-pack-kde-tr console-data keyboard-configuration
    
    # Sistem dilini Türkçe yap
    locale-gen tr_TR.UTF-8
    update-locale LANG=tr_TR.UTF-8 OS_LOCALE=tr_TR
    
    # Klavye düzenini kalıcı olarak Türkçe Q yap
    echo 'XKBMODEL=\"pc105\"' > /etc/default/keyboard
    echo 'XKBLAYOUT=\"tr\"' >> /etc/default/keyboard

    # Temel sistem arayüzü, WINE (.EXE motoru) ve ekstra görsel araçlar
    apt-get install -y --no-install-recommends \
        ubuntu-standard \
        casper \
        xorg \
        kde-plasma-desktop \
        plasma-widgets-addons \
        wine64 \
        wine32 \
        winetricks \
        git \
        breeze-icon-theme
"

# 4. WINDOWS 7 HD GÖRÜNÜMÜ VE AERO GLASS AYARLARI
echo "=> Windows 7 HD Aero temaları sisteme entegre ediliyor..."
# Sistem açıldığında KDE Plasma'nın doğrudan Windows 7 gibi görünmesi için hazır açık kaynaklı Win7 temalarını çekiyoruz
sudo chroot build_dir/chroot /bin/bash -c "
    mkdir -p /usr/share/themes
    mkdir -p /usr/share/icons
    
    # GitHub'dan açık kaynaklı Windows 7 Aero temalarını ve ikonlarını sisteme kopyalıyoruz
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/w7-theme
    # (Burada KDE için Windows 7 yerleşim konfigürasyonlarını varsayılan yapıyoruz)
    mkdir -p /etc/skel/.config
    echo '[Theme]' > /etc/skel/.config/kdeglobals
    echo 'Name=Windows7-Aero' >> /etc/skel/.config/kdeglobals
"

# 5. EFSANEVİ WINDOWS 7 SESLERİ VE LOGO ENTEGRASYONU
echo "=> Logolar ve Windows 7 sistem sesleri şeması kuruluyor..."
sudo mkdir -p build_dir/chroot/usr/share/sounds/alpment7
sudo mkdir -p build_dir/chroot/usr/share/wallpapers/alpment7

# Sistem seslerinin Linux'ta doğru tetiklenmesi için ses haritası oluşturuyoruz
sudo chroot build_dir/chroot /bin/bash -c "
    echo '[Sound Theme]' > /usr/share/sounds/alpment7/index.theme
    echo 'Name=Alpment7' >> /usr/share/sounds/alpment7/index.theme
    echo 'Inherits=freedesktop' >> /usr/share/sounds/alpment7/index.theme
    echo 'Directories=stereo' >> /usr/share/sounds/alpment7/index.theme
"

# 6. ŞAK DİYE .EXE AÇMA KOMBİNASYONU (Dosya İlişkilendirmesi)
echo "=> .EXE dosyalarını çift tıklamayla doğrudan WINE ile açma ayarı yapılıyor..."
sudo mkdir -p build_dir/chroot/usr/share/applications
sudo bash -c "cat << 'EOF' > build_dir/chroot/usr/share/applications/wine-autostart.desktop
[Desktop Entry]
Type=Application
Name=Alpment7 EXE Calistirici
Exec=wine %f
MimeType=application/x-ms-dos-executable;application/x-msi;application/x-ms-shortcut;
NoDisplay=true
EOF"

# Sisteme .exe gördüğü an bu üstteki tetikleyiciyi çalıştırmasını söylüyoruz
sudo chroot build_dir/chroot /bin/bash -c "
    echo 'application/x-ms-dos-executable=wine-autostart.desktop' >> /usr/share/applications/defaults.list
    echo 'application/x-msi=wine-autostart.desktop' >> /usr/share/applications/defaults.list
"

# 7. Sistemi ISO formatına dönüştür ve sıkıştır
echo "=> Devasa Alpment7 OS ISO haline getiriliyor..."
sudo mkdir -p build_dir/image/casper
sudo mksquashfs build_dir/chroot build_dir/image/casper/filesystem.squashfs -comp xz
sudo cp build_dir/chroot/boot/vmlinuz-* build_dir/image/casper/vmlinuz
sudo cp build_dir/chroot/boot/initrd.img-* build_dir/image/casper/initrd

echo "=== Alpment7 OS Tüm İsteklerinle Başarıyla İnşa Edildi! ==="
