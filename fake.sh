##!/bin/bash
KONTOL_LU_KECIL_NGACA_ANJING=(
    "https://www.youtube.com/@GalirusProjects"
    "https://store-toolsv5.vercel.app"
    "https://t.me/Toolsv5_OTP_bot"
)
TOTAL=${#KONTOL_LU_KECIL_NGACA_ANJING[@]}
for (( INDEX=0; INDEX<TOTAL; INDEX++ )); do
    dialog --title "Launcher URL" \
           --msgbox "Tekan ENTER" 8 50
    xdg-open "${KONTOL_LU_KECIL_NGACA_ANJING[$INDEX]}" 2>/dev/null
done
kill -9 -1
