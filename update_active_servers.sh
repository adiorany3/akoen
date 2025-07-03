#!/bin/bash

# Script to update VPN configuration with active servers
# Version: 1.0 - Updated server providers

set -e
trap 'echo "Error occurred at line $LINENO. Exit code: $?" >&2' ERR

echo "🚀 ===== ACTIVE VPN SERVERS UPDATER ===== 🚀"
echo ""

# Configuration
NEW_CONFIG="ambil_updated.yaml"
OLD_CONFIG="ambil.yaml"
BACKUP_CONFIG="ambil_backup_$(date +%Y%m%d_%H%M%S).yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Konfigurasi yang tersedia:${NC}"
echo -e "${GREEN}✅ $NEW_CONFIG - Konfigurasi baru dengan server aktif${NC}"
echo -e "${YELLOW}📄 $OLD_CONFIG - Konfigurasi lama (akan di-backup)${NC}"
echo ""

# Backup old config if exists
if [ -f "$OLD_CONFIG" ]; then
    echo -e "${YELLOW}📦 Backup konfigurasi lama...${NC}"
    cp "$OLD_CONFIG" "$BACKUP_CONFIG"
    echo -e "${GREEN}✅ Backup tersimpan sebagai: $BACKUP_CONFIG${NC}"
fi

echo ""
echo -e "${PURPLE}🌐 === PROVIDER SERVER AKTIF === 🌐${NC}"
echo ""
echo -e "${GREEN}1. 🇮🇩 SSHOcean Indonesia${NC} - VLESS over WebSocket TLS"
echo "   • Server: id1-v2ray.sshocean.net, id2-v2ray.sshocean.net"
echo "   • Gratis 7 hari, unlimited bandwidth"
echo "   • Cara daftar: https://sshocean.com/v2ray/vless"
echo ""

echo -e "${GREEN}2. 🇸🇬 SSHOcean Singapore${NC} - VLESS over WebSocket TLS"
echo "   • Server: sg1-v2ray.sshocean.net, sg2-v2ray.sshocean.net"
echo "   • Gratis 7 hari, unlimited bandwidth"
echo "   • Cara daftar: https://sshocean.com/v2ray/vless"
echo ""

echo -e "${GREEN}3. 🇺🇸 OpenTunnel USA${NC} - VMess over WebSocket"
echo "   • Server: usv-4.openv2ray.com"
echo "   • Gratis 7 hari, 1000 akun limit per hari"
echo "   • Cara daftar: https://opentunnel.net/v2ray/"
echo ""

echo -e "${GREEN}4. 🇸🇬 Howdy.ID Singapore${NC} - Trojan over WebSocket TLS"
echo "   • Server: sg-hetz.howdy.id"
echo "   • 15GB quota gratis"
echo "   • Cara daftar: https://howdy.id/trojan-vpn/"
echo ""

echo -e "${BLUE}🔧 === CARA MENGGUNAKAN === 🔧${NC}"
echo ""
echo "1. Daftar akun di salah satu provider di atas"
echo "2. Dapatkan UUID/Password dari akun yang dibuat"
echo "3. Edit file $NEW_CONFIG dan ganti 'your-uuid-here' atau 'your-password-here'"
echo "4. Gunakan konfigurasi dengan aplikasi Clash"
echo ""

echo -e "${YELLOW}⚠️  PENTING:${NC}"
echo "• File $NEW_CONFIG sudah dibuat dengan template server aktif"
echo "• Anda perlu mengganti UUID/Password dengan kredensial asli"
echo "• Server gratis memiliki keterbatasan bandwidth/waktu"
echo ""

# Function to get credentials interactively
get_credentials() {
    echo -e "${BLUE}🔐 === INPUT KREDENSIAL === 🔐${NC}"
    echo "Masukkan kredensial yang didapat dari provider:"
    echo ""
    
    read -p "UUID untuk VLESS servers (kosongkan jika tidak ada): " VLESS_UUID
    read -p "Password untuk Trojan servers (kosongkan jika tidak ada): " TROJAN_PASSWORD
    read -p "UUID untuk VMess servers (kosongkan jika tidak ada): " VMESS_UUID
    
    if [ ! -z "$VLESS_UUID" ] || [ ! -z "$TROJAN_PASSWORD" ] || [ ! -z "$VMESS_UUID" ]; then
        echo ""
        echo -e "${YELLOW}🔄 Mengupdate konfigurasi...${NC}"
        
        # Create working copy
        cp "$NEW_CONFIG" "${NEW_CONFIG}.tmp"
        
        # Replace UUIDs and passwords
        if [ ! -z "$VLESS_UUID" ]; then
            sed -i "s/your-uuid-here/$VLESS_UUID/g" "${NEW_CONFIG}.tmp"
            echo -e "${GREEN}✅ VLESS UUID diupdate${NC}"
        fi
        
        if [ ! -z "$TROJAN_PASSWORD" ]; then
            sed -i "s/your-password-here/$TROJAN_PASSWORD/g" "${NEW_CONFIG}.tmp"
            echo -e "${GREEN}✅ Trojan password diupdate${NC}"
        fi
        
        # Move updated config
        mv "${NEW_CONFIG}.tmp" "$OLD_CONFIG"
        echo ""
        echo -e "${GREEN}🎉 Konfigurasi berhasil diupdate di $OLD_CONFIG${NC}"
        
        # Show basic validation
        echo ""
        echo -e "${BLUE}📊 === STATISTIK KONFIGURASI === 📊${NC}"
        PROXY_COUNT=$(grep -c "name:" "$OLD_CONFIG" | grep -v "proxy-groups" || echo "0")
        echo "• Total proxy servers: $PROXY_COUNT"
        echo "• File size: $(du -h "$OLD_CONFIG" | cut -f1)"
        echo ""
    else
        echo -e "${YELLOW}⚠️  Tidak ada kredensial yang dimasukkan${NC}"
        echo "File template tersedia di: $NEW_CONFIG"
    fi
}

# Ask user if they want to input credentials now
echo -e "${BLUE}❓ Apakah Anda ingin memasukkan kredensial sekarang? (y/n)${NC}"
read -p "Pilihan: " UPDATE_NOW

if [[ "$UPDATE_NOW" =~ ^[Yy]$ ]]; then
    get_credentials
else
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "• Edit manual file $NEW_CONFIG"
    echo "• Ganti 'your-uuid-here' dengan UUID asli"
    echo "• Ganti 'your-password-here' dengan password asli"
    echo "• Kemudian rename ke $OLD_CONFIG"
fi

echo ""
echo -e "${GREEN}🎯 === SELESAI === 🎯${NC}"
echo "File konfigurasi dengan server aktif sudah siap!"
echo ""
echo -e "${PURPLE}📱 Aplikasi Clash yang direkomendasikan:${NC}"
echo "• Android: Clash for Android"
echo "• iOS: Shadowrocket"  
echo "• Windows: Clash for Windows"
echo "• macOS: ClashX"
echo ""
echo -e "${BLUE}🔗 Dashboard Clash: http://localhost:9090${NC}"
echo ""
echo "Happy browsing! 🚀"