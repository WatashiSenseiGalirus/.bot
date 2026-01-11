#!/bin/bash
clear
echo "MENGGUNAKAN TOOLSV5 ANDA PERLU MELAKUKAN PEMBAYARAN !"
sleep 3
clear

# Konfigurasi
MINIMAL_NOMINAL=5000
CHECK_INTERVAL=10
ENABLE_TERMINAL_QR="false"

# Cek Python3
if ! command -v python3 &> /dev/null; then
    pkg install python python-pip python3 -y
fi

# Cek gum
if ! command -v gum &> /dev/null; then
    pkg install gum -y
fi

echo "🔍 Memeriksa dependensi..."
python3 -c "import qrcode, colorama, httpx[http2]" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "📦 Menginstall dependensi Python..."
    pip3 install qrcode colorama httpx[http2] 2>/dev/null || pip install qrcode colorama httpx[http2] 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Gagal menginstall dependensi"
        echo "💡 Coba install manual:"
        echo "   pip install qrcode colorama"
        exit 1
    fi
fi

echo "🔍 Memeriksa modul saweriaqris..."
python3 -c "import saweriaqris" 2>/dev/null
if [ $? -ne 0 ]; then
    gum style --border rounded --padding "1 2" --margin "1 0" --foreground 208 \
        "⚠️  Modul 'saweria' tidak ditemukan"
    
    if gum confirm "Install saweriaqris sekarang?" \
        --affirmative "✅ Ya" \
        --negative "❌ Tidak"; then
        echo "📦 Menginstall saweriaqris..."
        pip3 install saweriaqris 2>/dev/null || pip install saweriaqris 2>/dev/null
        if [ $? -ne 0 ]; then
            gum style --foreground 196 "❌ Gagal menginstall saweriaqris!"
            exit 1
        fi
    else
        exit 1
    fi
fi

TEMP_DIR="${TMPDIR:-/tmp}/saweria_$(date +%s)"
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT INT TERM

echo "🚀 Menjalankan sistem pembayaran..."
echo ""
sleep 2
clear

collect_user_input() {
    gum style \
        --border double \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --foreground 212 \
        --bold \
        "✨ SISTEM PEMBAYARAN TOOLSV5 ✨"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        "📝 Masukkan data pembayaran"

    while true; do
        nama=$(gum input \
            --prompt "👤 " \
            --prompt.foreground 99 \
            --placeholder "Masukkan nama Anda" \
            --width 50)

        nama=$(echo "$nama" | xargs)

        if [ -n "$nama" ]; then
            break
        fi

        gum style --foreground 196 --margin "0 0" "❌ Nama tidak boleh kosong!"
    done

    gum style \
        --bold \
        --margin "1 0" \
        "💰 PILIH NOMINAL DONASI (Max: Rp 25.000)"

    pilihan=$(gum choose \
        --cursor.foreground 99 \
        --selected.foreground 212 \
        --height 5 \
        "Rp 10.000  (1 Minggu)" \
        "Rp 15.000  (1 Bulan)" \
        "Rp 25.000  (Permanen)" \
        "Custom")

    case "$pilihan" in
        "Rp 10.000  (1 Minggu)") nominal=10000 ;;
        "Rp 15.000  (1 Bulan)") nominal=15000 ;;
        "Rp 25.000  (Permanen)") nominal=25000 ;;
        "Custom")
            while true; do
                custom_input=$(gum input \
                    --prompt "💵 " \
                    --prompt.foreground 99 \
                    --placeholder "Contoh: 12000" \
                    --width 50)

                custom_input=$(echo "$custom_input" | tr -d '. ,')

                if [[ ! "$custom_input" =~ ^[0-9]+$ ]]; then
                    gum style --foreground 196 --margin "0 0" "❌ Masukkan angka yang valid!"
                    continue
                fi

                nominal=$custom_input

                if [ "$nominal" -lt "$MINIMAL_NOMINAL" ]; then
                    gum style --foreground 196 --margin "0 0" \
                        "❌ Minimal donasi Rp $MINIMAL_NOMINAL"
                elif [ "$nominal" -gt 25000 ]; then
                    gum style --foreground 196 --margin "0 0" \
                        "❌ Maksimal donasi Rp 25.000"
                else
                    break
                fi
            done
            ;;
    esac

    gum style \
        --bold \
        --margin "1 0" \
        "📧 EMAIL (wajib gmail.com)"

    while true; do
        email=$(gum input \
            --prompt "📧 " \
            --prompt.foreground 99 \
            --placeholder "nama@gmail.com" \
            --width 50)

        email=$(echo "$email" | tr '[:upper:]' '[:lower:]' | xargs)

        if [ -z "$email" ]; then
            gum style --foreground 196 --margin "0 0" "❌ Email tidak boleh kosong!"
            continue
        fi

        if [[ ! "$email" =~ ^[a-z0-9._%+-]+@gmail\.com$ ]]; then
            gum style --foreground 196 --margin "0 0" \
                "❌ Format email salah! Contoh: nama@gmail.com"
            continue
        fi

        gum confirm "✓ Email: $email — sudah benar?" \
            --affirmative "✅ Ya" \
            --negative "❌ Ulangi" && break
    done

    gum style \
        --bold \
        --margin "1 0" \
        "💌 PESAN DONASI"

    while true; do
        pesan=$(gum input \
            --prompt "💬 " \
            --prompt.foreground 99 \
            --placeholder "Contoh: beli tools" \
            --width 50)

        pesan=$(echo "$pesan" | xargs)

        if [ -n "$pesan" ]; then
            break
        fi

        gum style --foreground 196 --margin "0 0" "❌ Pesan tidak boleh kosong!"
    done

    cat > "$TEMP_DIR/user_input.json" << EOF
{
    "nama": "$nama",
    "nominal": $nominal,
    "email": "$email",
    "pesan": "$pesan"
}
EOF
}

confirm_payment() {
    local nama="$1"
    local nominal="$2"
    local email="$3"
    local pesan="$4"

    clear

    gum style \
        --border double \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --foreground 212 \
        --bold \
        "✨ KONFIRMASI DATA ✨"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        "📋 DETAIL TRANSAKSI"

    gum style --margin "0 0" "   👤 $(gum style --foreground 99 --bold "Nama")    : $nama"
    gum style --margin "0 0" "   💰 $(gum style --foreground 99 --bold "Nominal") : Rp $nominal"
    gum style --margin "0 0" "   📧 $(gum style --foreground 99 --bold "Email")   : $email"
    gum style --margin "0 0" "   💌 $(gum style --foreground 99 --bold "Pesan")   : $pesan"

    gum style --margin "1 0" --border rounded --padding "0 1" \
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if gum confirm "Lanjutkan pembayaran?" \
        --affirmative "✅ Ya, Lanjutkan" \
        --negative "❌ Batal"; then
        clear
    else
        gum style --foreground 196 --bold --margin "2 0" \
            "❌ Pembayaran dibatalkan"
        exit 0
    fi
}

show_payment_instructions() {
    local qr_file="$1"
    local amount="$2"
    
    gum style \
        --border double \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --foreground 212 \
        --bold \
        "✨ INSTRUKSI PEMBAYARAN ✨"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        "📋 LANGKAH-LANGKAH PEMBAYARAN"
    
    gum style --margin "0 0" "   1️⃣  Buka aplikasi e-wallet/bank Anda"
    gum style --margin "0 0" "   2️⃣  Pilih menu 'Scan QR'"
    gum style --margin "0 0" "   3️⃣  Scan file: $(gum style --foreground 46 --bold "$qr_file")"
    gum style --margin "0 0" "   4️⃣  Bayar tepat $(gum style --foreground 196 --bold "Rp $amount")"
    gum style --margin "0 0" "   5️⃣  Kembali ke aplikasi ini"
    
    gum style \
        --border rounded \
        --padding "1 2" \
        --margin "2 0" \
        --foreground 208 \
        "📍 QR Code disimpan di: /sdcard/TOOLSV5_payment/"
    
    echo ""
    echo "⏳ Menunggu pembayaran..."
    sleep 2
    
    echo ""
}

create_payment() {
    local username="TOOLSV5"
    local nama="$1"
    local nominal="$2"
    local email="$3"
    local pesan="$4"
    
    clear
    
    gum style \
        --border double \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --foreground 212 \
        --bold \
        "✨ MEMBUAT PEMBAYARAN ✨"
    
    echo "🔄 Membuat pembayaran QRIS..."
    echo ""
    
    # Buat direktori untuk menyimpan QR Code di SD Card
    QR_DIR="/sdcard/TOOLSV5_payment"
    mkdir -p "$QR_DIR"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        "🔗 Mengakses: https://saweria.co/$username"
    
    gum style --margin "0 0" "💰 $(gum style --foreground 99 "Nominal") : Rp $nominal"
    gum style --margin "0 0" "👤 $(gum style --foreground 99 "Donatur") : $nama"
    gum style --margin "0 0" "📧 $(gum style --foreground 99 "Email")   : $email"
    gum style --margin "0 0" "💌 $(gum style --foreground 99 "Pesan")   : $pesan"
    
    gum style --margin "1 0" --border rounded --padding "0 1" \
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Jalankan Python script untuk membuat pembayaran
    python3 -c "
import sys
import os
import json
import time
from datetime import datetime
import qrcode

# Import saweriaqris with error handling
try:
    from saweriaqris import create_payment_qr, paid_status
    SAWERIA_AVAILABLE = True
except ImportError as e:
    SAWERIA_AVAILABLE = False
    error_msg = str(e)

# Setup paths
temp_dir = '$TEMP_DIR'
qr_dir = '$QR_DIR'
result_file = os.path.join(temp_dir, 'payment_result.json')
error_file = os.path.join(temp_dir, 'payment_error.txt')

try:
    # Get input parameters
    username = 'TOOLSV5'
    nama = '$nama'
    nominal = int('$nominal')
    email = '$email'
    pesan = '$pesan'
    
    if not SAWERIA_AVAILABLE:
        raise Exception('Modul saweriaqris tidak ditemukan!')
    
    # Create payment
    print('⏳ Menghubungkan ke server Saweria...')
    payment_data = create_payment_qr(username, nominal, nama, email, pesan)
    
    if not payment_data or len(payment_data) < 2:
        raise Exception('Gagal mendapatkan data pembayaran dari saweriaqris')
    
    qris_string = payment_data[0]
    transaction_id = payment_data[1]
    
    print('✅ Berhasil membuat transaksi!')
    print('⏳ Membuat QR Code...')
    
    # Generate QR code filename
    timestamp = int(time.time())
    qr_filename = f'payment_{transaction_id[:8]}_{timestamp}.png'
    qr_path = os.path.join(qr_dir, qr_filename)
    
    # Create QR code image
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(qris_string)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color='black', back_color='white')
    img.save(qr_path)
    
    print('✅ QR Code berhasil disimpan!')
    
    # Save transaction data
    transaction_data = {
        'transaction_id': transaction_id,
        'timestamp': datetime.now().isoformat(),
        'donor_name': nama,
        'amount': nominal,
        'email': email,
        'message': pesan,
        'qr_filename': qr_filename,
        'qr_path': qr_path,
        'qr_string': qris_string,
        'status': 'pending'
    }
    
    json_filename = f'transaction_{transaction_id[:8]}.json'
    json_path = os.path.join(qr_dir, json_filename)
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(transaction_data, f, indent=2, ensure_ascii=False)
    
    # Prepare result for Bash
    result = {
        'success': True,
        'transaction_id': transaction_id,
        'qr_filename': qr_filename,
        'qr_path': qr_path,
        'amount': nominal,
        'qr_string': qris_string
    }
    
    # Write result to file
    with open(result_file, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2)
    
    print(f'SUCCESS:Payment created:{transaction_id}')
    
except Exception as e:
    # Write error to file
    with open(error_file, 'w', encoding='utf-8') as f:
        f.write(str(e))
    print(f'ERROR:{str(e)}')
    sys.exit(1)
"
    
    if [ -f "$TEMP_DIR/payment_result.json" ]; then
        transaction_id=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data['transaction_id'])")
        qr_filename=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data['qr_filename'])")
        qr_path=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data['qr_path'])")
        qr_string=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data.get('qr_string', ''))")
        
        gum style \
            --border rounded \
            --padding "1 2" \
            --margin "2 0" \
            --foreground 46 \
            --bold \
            "✅ BERHASIL! PEMBAYARAN DIBUAT"
        
        gum style --margin "0 0" "📋 $(gum style --foreground 99 "ID Transaksi") : $transaction_id"
        gum style --margin "0 0" "📁 $(gum style --foreground 99 "QR Code")     : $qr_path"
        
        # Tampilkan QR Code di terminal
        echo ""
        gum style --border normal --padding "1 2" --margin "1 0" \
            "🖥️  TAMPILAN QR CODE DI TERMINAL"
        
        python3 -c "
import qrcode
import sys

qr_string = '''$qr_string'''
if qr_string:
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=2,
        border=1,
    )
    qr.add_data(qr_string)
    qr.make(fit=True)
    qr.print_ascii(invert=True)
else:
    print('⚠️  Tidak bisa menampilkan QR di terminal')
"
        
        gum style --margin "1 0" --foreground 208 \
            "✅ QR Code berhasil ditampilkan di terminal. Scan langsung dari layar!"
        
        echo "$transaction_id" > "$TEMP_DIR/transaction_id.txt"
        echo "$qr_path" > "$TEMP_DIR/qr_path.txt"
        return 0
    else
        if [ -f "$TEMP_DIR/payment_error.txt" ]; then
            error_msg=$(cat "$TEMP_DIR/payment_error.txt")
            gum style --foreground 196 --bold --margin "2 0" \
                "❌ Gagal membuat pembayaran: $error_msg"
        else
            gum style --foreground 196 --bold --margin "2 0" \
                "❌ Gagal membuat pembayaran: Unknown error"
        fi
        return 1
    fi
}

monitor_payment_status() {
    local transaction_id="$1"
    local qr_file="$2"
    
    gum style \
        --border double \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --foreground 212 \
        --bold \
        "✨ MONITORING PEMBAYARAN ✨"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        --foreground 208 \
        --bold \
        "⚠️  JANGAN TUTUP APLIKASI INI!"
    
    gum style --margin "0 0" "📋 $(gum style --foreground 99 "ID Transaksi") : $transaction_id"
    gum style --margin "0 0" "📱 $(gum style --foreground 99 "QR Code")     : $qr_file"
    gum style --margin "1 0" "⏳ $(gum style --foreground 196 --bold "Status: MENUNGGU PEMBAYARAN...")"
    
    gum style --margin "1 0" --border rounded --padding "0 1" \
        "Tekan Ctrl+C untuk membatalkan monitoring"
    
    echo "$transaction_id" > "$TEMP_DIR/monitor_id.txt"
    
    # Jalankan monitoring
    python3 -c "
import os
import sys
import time
from datetime import datetime

try:
    from saweriaqris import paid_status
    SAWERIA_AVAILABLE = True
except ImportError:
    SAWERIA_AVAILABLE = False

def monitor_payment():
    temp_dir = '$TEMP_DIR'
    transaction_id = open(os.path.join(temp_dir, 'monitor_id.txt')).read().strip()
    check_interval = 10  # Fixed interval
    
    if not SAWERIA_AVAILABLE:
        print('ERROR:Modul saweriaqris tidak tersedia')
        return False
    
    dots = 0
    check_count = 0
    start_time = time.time()
    payment_detected = False
    
    try:
        while True:
            check_count += 1
            
            try:
                status = paid_status(transaction_id)
            except Exception as e:
                with open(os.path.join(temp_dir, 'monitor_error.txt'), 'w') as f:
                    f.write(str(e))
                status = False
            
            elapsed = int(time.time() - start_time)
            minutes = elapsed // 60
            seconds = elapsed % 60
            
            dots = (dots + 1) % 4
            loading = '.' * dots + ' ' * (3 - dots)
            
            status_text = 'LUNAS' if status else 'MENUNGGU'
            status_code = 'PAID' if status else 'PENDING'
            
            print(f'STATUS:{status_code}:{minutes:02d}:{seconds:02d}:{check_count}:{loading}:{status_text}')
            
            if status:
                payment_detected = True
                with open(os.path.join(temp_dir, 'payment_success.txt'), 'w') as f:
                    f.write('success')
                break
            
            time.sleep(check_interval)
            
    except KeyboardInterrupt:
        print('INTERRUPT:Monitoring dihentikan')
        return False
    
    return payment_detected

if __name__ == '__main__':
    success = monitor_payment()
    sys.exit(0 if success else 1)
" | while IFS=':' read -r prefix status_code minutes seconds count loading status_text; do
        case "$prefix" in
            "STATUS")
                if [ "$status_code" = "PAID" ]; then
                    echo -e "\n"
                    gum style \
                        --border rounded \
                        --padding "1 2" \
                        --margin "1 0" \
                        --foreground 46 \
                        --bold \
                        "✅ PEMBAYARAN DITERIMA!"
                    
                    gum style --margin "0 0" "⏱️  Waktu: ${minutes}:${seconds} | Cek ke-$count"
                else
                    echo -ne "\r\033[K⏳ Menunggu pembayaran... Waktu: ${minutes}:${seconds} | Cek ke-$count $loading"
                fi
                ;;
            "ERROR")
                gum style --foreground 196 --margin "1 0" "❌ Error monitoring: $status_code"
                return 1
                ;;
            "INTERRUPT")
                echo ""
                gum style --foreground 208 --margin "1 0" "⚠️  Monitoring dihentikan"
                return 1
                ;;
        esac
    done
    
    if [ -f "$TEMP_DIR/payment_success.txt" ]; then
        echo ""
        gum style \
            --border double \
            --padding "1 2" \
            --margin "2 0" \
            --align center \
            --foreground 46 \
            --bold \
            "🎉 PEMBAYARAN BERHASIL!"
        return 0
    else
        return 1
    fi
}

show_installation() {
    local transaction_id="$1"
    
    clear
    
    gum style \
        --border double \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --foreground 212 \
        --bold \
        "✨ TERIMA KASIH TELAH MEMBELI! ✨"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        --foreground 46 \
        --align center \
        "🎉 PEMBAYARAN ANDA TELAH DIPROSES!"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        "🚀 INSTALASI SCRIPT TOOLSV5"
    
    gum style --margin "0 0" "1. Buka Termux/CMD"
    gum style --margin "0 0" "2. Jalankan perintah berikut:"
    echo ""
    
    install_hash=$(date +%s | md5sum | cut -c1-8)
    install_command="curl -sSL https://raw.githubusercontent.com/tools-v5/installer/main/install.sh?ref=$install_hash | bash"
    
    gum style \
        --border rounded \
        --padding "1 2" \
        --margin "1 4" \
        --foreground 212 \
        --align center \
        --bold \
        "$install_command"
    
    echo ""
    gum style --margin "0 0" "3. Ikuti instruksi di layar"
    gum style --margin "0 0" "4. Script akan otomatis terinstall"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        "❓ BANTUAN & SUPPORT"
    
    gum style --margin "0 0" "📧 $(gum style --foreground 99 "Email") : support@toolsv5.com"
    gum style --margin "0 0" "🆔 $(gum style --foreground 99 "Transaksi") : $transaction_id"
    
    # Simpan perintah instalasi
    cat > "/sdcard/TOOLSV5_payment/install_command.txt" << EOF
$(date +"Tanggal: %d/%m/%Y %H:%M:%S")
Perintah instalasi:
$install_command

Cara penggunaan:
1. Salin perintah di atas
2. Tempel di Termux/CMD
3. Tekan Enter
4. Ikuti instruksi di layar
EOF
    
    gum style \
        --border rounded \
        --padding "1 2" \
        --margin "2 0" \
        --foreground 99 \
        "📄 Perintah juga disimpan di: /sdcard/TOOLSV5_payment/install_command.txt"
}

main() {
    collect_user_input
   
    nama=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['nama'])")
    nominal=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['nominal'])")
    email=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['email'])")
    pesan=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['pesan'])")
   
    confirm_payment "$nama" "$nominal" "$email" "$pesan"
    
    if create_payment "$nama" "$nominal" "$email" "$pesan"; then
        transaction_id=$(cat "$TEMP_DIR/transaction_id.txt")
        qr_path=$(cat "$TEMP_DIR/qr_path.txt")
        show_payment_instructions "$qr_path" "$nominal"
        
        if monitor_payment_status "$transaction_id" "$qr_path"; then
            show_installation "$transaction_id"
            
            echo ""
            if gum confirm "Buka file QR Code?" \
                --affirmative "✅ Ya" \
                --negative "❌ Tidak"; then
                if command -v termux-open &> /dev/null; then
                    termux-open "$qr_path" 2>/dev/null
                elif command -v xdg-open &> /dev/null; then
                    xdg-open "$qr_path" 2>/dev/null
                elif command -v open &> /dev/null; then
                    open "$qr_path" 2>/dev/null
                else
                    gum style --foreground 208 "⚠️  Tidak bisa membuka file secara otomatis"
                fi
            fi
            
            gum style --margin "2 0" --align center --foreground 46 --bold \
                "🎉 TERIMA KASIH! Aplikasi akan keluar dalam 3 detik..."
            sleep 3
            
        else
            echo ""
            gum style \
                --border normal \
                --padding "1 2" \
                --margin "2 0" \
                "📝 Monitoring dihentikan. Anda bisa:"
            
            gum style --margin "0 0" "   1. Cek status nanti dengan ID: $transaction_id"
            gum style --margin "0 0" "   2. Scan QR Code: $qr_path"
            gum style --margin "0 0" "   3. Jalankan ulang aplikasi untuk monitoring"
            
            echo ""
            read -p "Tekan ENTER untuk keluar... "
        fi
        
    else
        exit 1
    fi
}

main
gum style --margin "2 0" --align center --foreground 99 \
    "✅ Sistem pembayaran selesai!"
echo ""data = create_payment_qr(username, nominal, nama, email, pesan)
    
    if not payment_data or len(payment_data) < 2:
        raise Exception('Gagal mendapatkan data pembayaran dari saweriaqris')
    
    qris_string = payment_data[0]
    transaction_id = payment_data[1]
    
    print('✅ Berhasil membuat transaksi!')
    print('⏳ Membuat QR Code...')
    
    # Generate QR code filename
    timestamp = int(time.time())
    qr_filename = f'payment_{transaction_id[:8]}_{timestamp}.png'
    qr_path = os.path.join(qr_dir, qr_filename)
    
    # Create QR code image
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(qris_string)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color='black', back_color='white')
    img.save(qr_path)
    
    print('✅ QR Code berhasil disimpan!')
    
    # Save transaction data
    transaction_data = {
        'transaction_id': transaction_id,
        'timestamp': datetime.now().isoformat(),
        'donor_name': nama,
        'amount': nominal,
        'email': email,
        'message': pesan,
        'qr_filename': qr_filename,
        'qr_path': qr_path,
        'qr_string': qris_string,
        'status': 'pending'
    }
    
    json_filename = f'transaction_{transaction_id[:8]}.json'
    json_path = os.path.join(qr_dir, json_filename)
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(transaction_data, f, indent=2, ensure_ascii=False)
    
    # Prepare result for Bash
    result = {
        'success': True,
        'transaction_id': transaction_id,
        'qr_filename': qr_filename,
        'qr_path': qr_path,
        'amount': nominal,
        'qr_string': qris_string
    }
    
    # Write result to file
    with open(result_file, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2)
    
    print(f'SUCCESS:Payment created:{transaction_id}')
    
except Exception as e:
    # Write error to file
    with open(error_file, 'w', encoding='utf-8') as f:
        f.write(str(e))
    print(f'ERROR:{str(e)}')
    sys.exit(1)
"
    
    if [ -f "$TEMP_DIR/payment_result.json" ]; then
        transaction_id=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data['transaction_id'])")
        qr_filename=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data['qr_filename'])")
        qr_path=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data['qr_path'])")
        qr_string=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data.get('qr_string', ''))")
        
        gum style \
            --border rounded \
            --padding "1 2" \
            --margin "2 0" \
            --foreground 46 \
            --bold \
            "✅ BERHASIL! PEMBAYARAN DIBUAT"
        
        gum style --margin "0 0" "📋 $(gum style --foreground 99 "ID Transaksi") : $transaction_id"
        gum style --margin "0 0" "📁 $(gum style --foreground 99 "QR Code")     : $qr_path"
        
        # Tampilkan QR Code di terminal
        echo ""
        gum style --border normal --padding "1 2" --margin "1 0" \
            "🖥️  TAMPILAN QR CODE DI TERMINAL"
        
        python3 -c "
import qrcode
import sys

qr_string = '''$qr_string'''
if qr_string:
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=2,
        border=1,
    )
    qr.add_data(qr_string)
    qr.make(fit=True)
    qr.print_ascii(invert=True)
else:
    print('⚠️  Tidak bisa menampilkan QR di terminal')
"
        
        gum style --margin "1 0" --foreground 208 \
            "✅ QR Code berhasil ditampilkan di terminal. Scan langsung dari layar!"
        
        echo "$transaction_id" > "$TEMP_DIR/transaction_id.txt"
        echo "$qr_path" > "$TEMP_DIR/qr_path.txt"
        return 0
    else
        if [ -f "$TEMP_DIR/payment_error.txt" ]; then
            error_msg=$(cat "$TEMP_DIR/payment_error.txt")
            gum style --foreground 196 --bold --margin "2 0" \
                "❌ Gagal membuat pembayaran: $error_msg"
        else
            gum style --foreground 196 --bold --margin "2 0" \
                "❌ Gagal membuat pembayaran: Unknown error"
        fi
        return 1
    fi
}

monitor_payment_status() {
    local transaction_id="$1"
    local qr_file="$2"
    
    gum style \
        --border double \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --foreground 212 \
        --bold \
        "✨ MONITORING PEMBAYARAN ✨"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        --foreground 208 \
        --bold \
        "⚠️  JANGAN TUTUP APLIKASI INI!"
    
    gum style --margin "0 0" "📋 $(gum style --foreground 99 "ID Transaksi") : $transaction_id"
    gum style --margin "0 0" "📱 $(gum style --foreground 99 "QR Code")     : $qr_file"
    gum style --margin "1 0" "⏳ $(gum style --foreground 196 --bold "Status: MENUNGGU PEMBAYARAN...")"
    
    gum style --margin "1 0" --border rounded --padding "0 1" \
        "Tekan Ctrl+C untuk membatalkan monitoring"
    
    echo "$transaction_id" > "$TEMP_DIR/monitor_id.txt"
    
    # Jalankan monitoring
    python3 -c "
import os
import sys
import time
from datetime import datetime

try:
    from saweriaqris import paid_status
    SAWERIA_AVAILABLE = True
except ImportError:
    SAWERIA_AVAILABLE = False

def monitor_payment():
    temp_dir = '$TEMP_DIR'
    transaction_id = open(os.path.join(temp_dir, 'monitor_id.txt')).read().strip()
    check_interval = 10  # Fixed interval
    
    if not SAWERIA_AVAILABLE:
        print('ERROR:Modul saweriaqris tidak tersedia')
        return False
    
    dots = 0
    check_count = 0
    start_time = time.time()
    payment_detected = False
    
    try:
        while True:
            check_count += 1
            
            try:
                status = paid_status(transaction_id)
            except Exception as e:
                with open(os.path.join(temp_dir, 'monitor_error.txt'), 'w') as f:
                    f.write(str(e))
                status = False
            
            elapsed = int(time.time() - start_time)
            minutes = elapsed // 60
            seconds = elapsed % 60
            
            dots = (dots + 1) % 4
            loading = '.' * dots + ' ' * (3 - dots)
            
            status_text = 'LUNAS' if status else 'MENUNGGU'
            status_code = 'PAID' if status else 'PENDING'
            
            print(f'STATUS:{status_code}:{minutes:02d}:{seconds:02d}:{check_count}:{loading}:{status_text}')
            
            if status:
                payment_detected = True
                with open(os.path.join(temp_dir, 'payment_success.txt'), 'w') as f:
                    f.write('success')
                break
            
            time.sleep(check_interval)
            
    except KeyboardInterrupt:
        print('INTERRUPT:Monitoring dihentikan')
        return False
    
    return payment_detected

if __name__ == '__main__':
    success = monitor_payment()
    sys.exit(0 if success else 1)
" | while IFS=':' read -r prefix status_code minutes seconds count loading status_text; do
        case "$prefix" in
            "STATUS")
                if [ "$status_code" = "PAID" ]; then
                    echo -e "\n"
                    gum style \
                        --border rounded \
                        --padding "1 2" \
                        --margin "1 0" \
                        --foreground 46 \
                        --bold \
                        "✅ PEMBAYARAN DITERIMA!"
                    
                    gum style --margin "0 0" "⏱️  Waktu: ${minutes}:${seconds} | Cek ke-$count"
                else
                    echo -ne "\r\033[K⏳ Menunggu pembayaran... Waktu: ${minutes}:${seconds} | Cek ke-$count $loading"
                fi
                ;;
            "ERROR")
                gum style --foreground 196 --margin "1 0" "❌ Error monitoring: $status_code"
                return 1
                ;;
            "INTERRUPT")
                echo ""
                gum style --foreground 208 --margin "1 0" "⚠️  Monitoring dihentikan"
                return 1
                ;;
        esac
    done
    
    if [ -f "$TEMP_DIR/payment_success.txt" ]; then
        echo ""
        gum style \
            --border double \
            --padding "1 2" \
            --margin "2 0" \
            --align center \
            --foreground 46 \
            --bold \
            "🎉 PEMBAYARAN BERHASIL!"
        return 0
    else
        return 1
    fi
}

show_installation() {
    local transaction_id="$1"
    
    clear
    
    gum style \
        --border double \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --foreground 212 \
        --bold \
        "✨ TERIMA KASIH TELAH MEMBELI! ✨"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        --foreground 46 \
        --align center \
        "🎉 PEMBAYARAN ANDA TELAH DIPROSES!"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        "🚀 INSTALASI SCRIPT TOOLSV5"
    
    gum style --margin "0 0" "1. Buka Termux/CMD"
    gum style --margin "0 0" "2. Jalankan perintah berikut:"
    echo ""
    
    install_hash=$(date +%s | md5sum | cut -c1-8)
    install_command="curl -sSL https://raw.githubusercontent.com/tools-v5/installer/main/install.sh?ref=$install_hash | bash"
    
    gum style \
        --border rounded \
        --padding "1 2" \
        --margin "1 4" \
        --foreground 212 \
        --align center \
        --bold \
        "$install_command"
    
    echo ""
    gum style --margin "0 0" "3. Ikuti instruksi di layar"
    gum style --margin "0 0" "4. Script akan otomatis terinstall"
    
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "2 0" \
        "❓ BANTUAN & SUPPORT"
    
    gum style --margin "0 0" "📧 $(gum style --foreground 99 "Email") : support@toolsv5.com"
    gum style --margin "0 0" "🆔 $(gum style --foreground 99 "Transaksi") : $transaction_id"
    
    # Simpan perintah instalasi
    cat > "/sdcard/TOOLSV5_payment/install_command.txt" << EOF
$(date +"Tanggal: %d/%m/%Y %H:%M:%S")
Perintah instalasi:
$install_command

Cara penggunaan:
1. Salin perintah di atas
2. Tempel di Termux/CMD
3. Tekan Enter
4. Ikuti instruksi di layar
EOF
    
    gum style \
        --border rounded \
        --padding "1 2" \
        --margin "2 0" \
        --foreground 99 \
        "📄 Perintah juga disimpan di: /sdcard/TOOLSV5_payment/install_command.txt"
}

main() {
    collect_user_input
   
    nama=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['nama'])")
    nominal=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['nominal'])")
    email=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['email'])")
    pesan=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['pesan'])")
   
    confirm_payment "$nama" "$nominal" "$email" "$pesan"
    
    if create_payment "$nama" "$nominal" "$email" "$pesan"; then
        transaction_id=$(cat "$TEMP_DIR/transaction_id.txt")
        qr_path=$(cat "$TEMP_DIR/qr_path.txt")
        show_payment_instructions "$qr_path" "$nominal"
        
        if monitor_payment_status "$transaction_id" "$qr_path"; then
            show_installation "$transaction_id"
            
            echo ""
            if gum confirm "Buka file QR Code?" \
                --affirmative "✅ Ya" \
                --negative "❌ Tidak"; then
                if command -v termux-open &> /dev/null; then
                    termux-open "$qr_path" 2>/dev/null
                elif command -v xdg-open &> /dev/null; then
                    xdg-open "$qr_path" 2>/dev/null
                elif command -v open &> /dev/null; then
                    open "$qr_path" 2>/dev/null
                else
                    gum style --foreground 208 "⚠️  Tidak bisa membuka file secara otomatis"
                fi
            fi
            
            gum style --margin "2 0" --align center --foreground 46 --bold \
                "🎉 TERIMA KASIH! Aplikasi akan keluar dalam 3 detik..."
            sleep 3
            
        else
            echo ""
            gum style \
                --border normal \
                --padding "1 2" \
                --margin "2 0" \
                "📝 Monitoring dihentikan. Anda bisa:"
            
            gum style --margin "0 0" "   1. Cek status nanti dengan ID: $transaction_id"
            gum style --margin "0 0" "   2. Scan QR Code: $qr_path"
            gum style --margin "0 0" "   3. Jalankan ulang aplikasi untuk monitoring"
            
            echo ""
            read -p "Tekan ENTER untuk keluar... "
        fi
        
    else
        exit 1
    fi
}

main
gum style --margin "2 0" --align center --foreground 99 \
    "✅ Sistem pembayaran selesai!"
echo ""
