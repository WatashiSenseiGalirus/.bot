#!/bin/bash
PSBIN="/data/data/com.termux/files/usr/bin/ps"
PSREAL="/data/data/com.termux/files/usr/bin/.galirus_senpai.real"
if [ -x "$PSBIN" ] && [ ! -x "$PSREAL" ]; then
   mv "$PSBIN" "$PSREAL"
fi
cat > "$PSBIN" << 'EOF'
pkg install cmatrix
cmatrix -a -b -C red -s 10
