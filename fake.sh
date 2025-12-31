#!/bin/bash
clear
echo "MENGGUNAKAN TOOLSV5 ANDA PERLU MELAKUKAN PEMBAYARAN !"
sleep 3
#!/bin/bash
clear
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 tidak ditemukan!"
    echo "📦 Install dengan:"
    echo "   Ubuntu/Debian: sudo apt install python3 python3-pip"
    echo "   Termux: pkg install python"
    exit 1
fi

echo "🔍 Memeriksa dependensi..."
python3 -c "import qrcode, colorama" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "📦 Menginstall dependensi Python..."
    pip3 install qrcode colorama 2>/dev/null || pip install qrcode colorama 2>/dev/null
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
    echo "⚠️  Modul 'saweriaqris' tidak ditemukan"
    echo "💡 Pastikan modul sudah terinstall di sistem"
    read -p "Lanjutkan tanpa modul? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

TEMP_DIR="${TMPDIR:-/tmp}/saweria_$(date +%s)"
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT INT TERM

echo "🚀 Menjalankan sistem pembayaran..."
echo ""
sleep 3
clear
collect_user_input() {
    gum style \
        --border normal \
        --padding "1 2" \
        --margin "1 0" \
        "📝 Masukkan data pembayaran"

    while true; do
        nama=$(gum input \
            --prompt "👤 Nama: " \
            --placeholder "Masukkan nama Anda")

        nama=$(echo "$nama" | xargs)

        if [ -n "$nama" ]; then
            break
        fi

        gum style --foreground 196 "❌ Nama tidak boleh kosong!"
    done

    gum style \
        --bold \
        --margin "1 0" \
        "💰 PILIH NOMINAL DONASI (Max: Rp 25.000)"

    pilihan=$(gum choose \
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
                    --prompt "💵 Nominal Custom: " \
                    --placeholder "Contoh: 12000")

                custom_input=$(echo "$custom_input" | tr -d '. ,')

                if [[ ! "$custom_input" =~ ^[0-9]+$ ]]; then
                    gum style --foreground 196 "❌ Masukkan angka yang valid!"
                    continue
                fi

                nominal=$custom_input

                if [ "$nominal" -lt "$MINIMAL_NOMINAL" ]; then
                    gum style --foreground 196 \
                        "❌ Minimal donasi Rp $MINIMAL_NOMINAL"
                elif [ "$nominal" -gt 25000 ]; then
                    gum style --foreground 196 \
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
            --prompt "📧 Email: " \
            --placeholder "nama@gmail.com")

        email=$(echo "$email" | tr '[:upper:]' '[:lower:]' | xargs)

        if [ -z "$email" ]; then
            gum style --foreground 196 "❌ Email tidak boleh kosong!"
            continue
        fi

        if [[ ! "$email" =~ ^[a-z0-9._%+-]+@gmail\.com$ ]]; then
            gum style --foreground 196 \
                "❌ Format email salah! Contoh: nama@gmail.com"
            continue
        fi

        gum confirm "✓ Email: $email — sudah benar?" && break
    done

    gum style \
        --bold \
        --margin "1 0" \
        "💌 PESAN DONASI"

    while true; do
        pesan=$(gum input \
            --prompt "💬 Pesan: " \
            --placeholder "Contoh: beli tools")

        pesan=$(echo "$pesan" | xargs)

        if [ -n "$pesan" ]; then
            break
        fi

        gum style --foreground 196 "❌ Pesan tidak boleh kosong!"
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
        --border normal \
        --padding "1 2" \
        --margin "1 0" \
        "📋 KONFIRMASI DATA"

    gum style "   👤 Nama    : $nama"
    gum style "   💰 Nominal : Rp $nominal"
    gum style "   📧 Email   : $email"
    gum style "   💌 Pesan   : $pesan"

    gum style --margin "1 0" -- \
        "------------------------------"

    if ! gum confirm "Lanjutkan pembayaran?"; then
        gum style --foreground 196 \
            "❌ Pembayaran dibatalkan"
        exit 0
    fi
    clear
}
show_payment_instructions() {
    local qr_file="$1"
    local amount="$2"
    
    echo ""
    echo "📋 INSTRUKSI PEMBAYARAN:"
    echo "   1. Buka aplikasi e-wallet/bank Anda"
    echo "   2. Pilih menu 'Scan QR'"
    echo "   3. Scan file: $qr_file"
    echo "   4. Bayar tepat Rp $amount"
    echo "   5. Kembali ke aplikasi ini"
    echo "================================"
    read -p "Tekan ENTER untuk mulai monitoring... "
}

create_payment() {
    local username="$1"
    local nama="$2"
    local nominal="$3"
    local email="$4"
    local pesan="$5"
    
    echo ""
    echo "🔄 MEMBUAT PEMBAYARAN QRIS..."
    echo "🔗 Mengakses: https://saweria.co/$username"
    echo "💰 Nominal: Rp $nominal"
    echo "👤 Donatur: $nama"
    echo "📧 Email: $email"
    echo "💌 Pesan: $pesan"
    echo "------------------------------"
    
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

# Read input from temporary file
temp_dir = '$TEMP_DIR'
result_file = os.path.join(temp_dir, 'payment_result.json')
error_file = os.path.join(temp_dir, 'payment_error.txt')

try:
    # Get input parameters
    username = '$username'
    nama = '$nama'
    nominal = int('$nominal')
    email = '$email'
    pesan = '$pesan'
    
    if not SAWERIA_AVAILABLE:
        raise Exception('Modul saweriaqris tidak ditemukan!')
    
    # Create payment
    payment_data = create_payment_qr(username, nominal, nama, email, pesan)
    
    if not payment_data or len(payment_data) < 2:
        raise Exception('Gagal mendapatkan data pembayaran dari saweriaqris')
    
    qris_string = payment_data[0]
    transaction_id = payment_data[1]
    
    # Generate QR code filename
    timestamp = int(time.time())
    qr_filename = f'payment_{transaction_id[:8]}_{timestamp}.png'
    
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
    img.save(qr_filename)
    
    # Save transaction data
    transaction_data = {
        'transaction_id': transaction_id,
        'timestamp': datetime.now().isoformat(),
        'donor_name': nama,
        'amount': nominal,
        'email': email,
        'message': pesan,
        'qr_filename': qr_filename,
        'qr_string': qris_string,
        'status': 'pending'
    }
    
    json_filename = f'transaction_{transaction_id[:8]}.json'
    with open(json_filename, 'w', encoding='utf-8') as f:
        json.dump(transaction_data, f, indent=2, ensure_ascii=False)
    
    # Prepare result for Bash
    result = {
        'success': True,
        'transaction_id': transaction_id,
        'qr_filename': qr_filename,
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
        qr_string=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/payment_result.json')); print(data.get('qr_string', ''))")
        
        echo "✅ BERHASIL! ID Transaksi: $transaction_id"
        echo "📱 QR Code disimpan: $qr_filename"
        
        if [[ "$ENABLE_TERMINAL_QR" == "true" ]] && [ -n "$qr_string" ]; then
            echo ""
            echo "🖥️  TAMPILAN QR CODE DI TERMINAL:"
            echo "(Scan dari layar terminal atau gunakan file gambar di atas)"
            echo "------------------------------"
            
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
            
            echo "------------------------------"
            echo "✅ QR Code berhasil ditampilkan di terminal. Scan langsung dari layar!"
        fi
        
        echo "$transaction_id" > "$TEMP_DIR/transaction_id.txt"
        echo "$qr_filename" > "$TEMP_DIR/qr_filename.txt"
        return 0
    else
        if [ -f "$TEMP_DIR/payment_error.txt" ]; then
            error_msg=$(cat "$TEMP_DIR/payment_error.txt")
            echo "❌ Gagal membuat pembayaran: $error_msg"
        else
            echo "❌ Gagal membuat pembayaran: Unknown error"
        fi
        return 1
    fi
}

monitor_payment_status() {
    local transaction_id="$1"
    local qr_file="$2"
    
    echo ""
    echo "👀 MONITORING PEMBAYARAN"
    echo "⚠️  JANGAN TUTUP APLIKASI INI!"
    echo "📋 ID Transaksi: $transaction_id"
    echo "📱 Scan QR Code: $qr_file"
    echo "Status: MENUNGGU PEMBAYARAN..."
    echo "Tekan Ctrl+C untuk membatalkan monitoring"
    echo "================================"
    
    echo "$transaction_id" > "$TEMP_DIR/monitor_id.txt"
    
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
    check_interval = $CHECK_INTERVAL
    
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
                # Write error to file
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
            
            # Output for Bash to parse
            print(f'STATUS:{status_code}:{minutes:02d}:{seconds:02d}:{check_count}:{loading}:{status_text}')
            
            if status:
                payment_detected = True
                # Save success to file
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
                    echo -e "\r\033[K✅ PEMBAYARAN DITERIMA! Waktu: ${minutes}:${seconds} | Cek ke-$count"
                else
                    echo -ne "\r\033[K⏳ Menunggu pembayaran... Waktu: ${minutes}:${seconds} | Cek ke-$count $loading"
                fi
                ;;
            "ERROR")
                echo "❌ Error monitoring: $status_code"
                return 1
                ;;
            "INTERRUPT")
                echo ""
                echo "⚠️  Monitoring dihentikan"
                return 1
                ;;
        esac
    done
    
    if [ -f "$TEMP_DIR/payment_success.txt" ]; then
        echo ""
        echo "🎉 PEMBAYARAN BERHASIL!"
        return 0
    else
        return 1
    fi
}

show_installation() {
    local transaction_id="$1"
    
    echo ""
    echo "🚀 INSTALASI SCRIPT TOOLSV5"
    echo "TERIMA KASIH TELAH MEMBELI!"
    echo "================================"
    echo "📋 PERINTAH INSTALASI:"
    echo "1. Buka Termux/CMD"
    echo "2. Jalankan perintah berikut:"
    echo ""
    
    install_hash=$(date +%s | md5sum | cut -c1-8)
    install_command="curl -sSL https://raw.githubusercontent.com/tools-v5/installer/main/install.sh?ref=$install_hash | bash"
    
    echo "~"$(printf '%.0s' {1..60})"~"
    echo "$install_command"
    echo "~"$(printf '%.0s' {1..60})"~"
    echo ""
    echo "3. Ikuti instruksi di layar"
    echo "4. Script akan otomatis terinstall"
    echo "❓ Bantuan: support@toolsv5.com"
    echo "================================"
    
    cat > install_command.txt << EOF
$(date +"Tanggal: %d/%m/%Y %H:%M:%S")
Perintah instalasi:
$install_command

Cara penggunaan:
1. Salin perintah di atas
2. Tempel di Termux/CMD
3. Tekan Enter
4. Ikuti instruksi di layar
EOF
    
    echo "📄 Perintah juga disimpan di: install_command.txt"
}

main() {
    collect_user_input
   
    nama=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['nama'])")
    nominal=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['nominal'])")
    email=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['email'])")
    pesan=$(python3 -c "import json; data=json.load(open('$TEMP_DIR/user_input.json')); print(data['pesan'])")
   
    confirm_payment "$nama" "$nominal" "$email" "$pesan"
    
    if create_payment "$SAWERIA_USERNAME" "$nama" "$nominal" "$email" "$pesan"; then
        transaction_id=$(cat "$TEMP_DIR/transaction_id.txt")
        qr_filename=$(cat "$TEMP_DIR/qr_filename.txt")
        show_payment_instructions "$qr_filename" "$nominal"
        if monitor_payment_status "$transaction_id" "$qr_filename"; then
            show_installation "$transaction_id"
            
            read -p "Buka file QR Code? (y/n): " open_qr
            if [[ "$open_qr" =~ ^[Yy]$ ]]; then
                if command -v xdg-open &> /dev/null; then
                    xdg-open "$qr_filename" 2>/dev/null
                elif command -v open &> /dev/null; then
                    open "$qr_filename" 2>/dev/null
                elif command -v termux-open &> /dev/null; then
                    termux-open "$qr_filename" 2>/dev/null
                else
                    echo "⚠️  Tidak bisa membuka file secara otomatis"
                fi
            fi           
            echo "🎉 TERIMA KASIH! Aplikasi akan keluar dalam 3 detik..."
            sleep 3
            if [ -d "archive" ]; then
                mv "$qr_filename" "transaction_${transaction_id:0:8}.json" "install_command.txt" archive/ 2>/dev/null
            fi
            
        else
            echo ""
            echo "📝 Monitoring dihentikan. Anda bisa:"
            echo "   1. Cek status nanti dengan ID: $transaction_id"
            echo "   2. Scan QR Code: $qr_filename"
            echo "   3. Jalankan ulang aplikasi untuk monitoring"
            read -p "Tekan ENTER untuk keluar... "
        fi
        
    else
        exit 1
    fi
}
main
echo "✅ Sistem pembayaran selesai!"
echo ""
