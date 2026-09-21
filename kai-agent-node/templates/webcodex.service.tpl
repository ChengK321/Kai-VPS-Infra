[Unit]
Description=WebCodex Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{USER}}
Group={{GROUP}}
WorkingDirectory={{HOME}}
Environment=HOME={{HOME}}
ExecStart={{NPM_BIN}}/webcodex server run --env-file {{CONFIG}}/webcodex.env
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
