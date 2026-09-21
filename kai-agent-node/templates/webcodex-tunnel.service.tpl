[Unit]
Description=WebCodex OpenAI Secure MCP Tunnel
After=network-online.target webcodex.service
Wants=network-online.target

[Service]
Type=simple
User={{USER}}
EnvironmentFile={{CONFIG}}/tunnel.env
ExecStart=/bin/bash -c '/usr/bin/sleep infinity | {{NPM_BIN}}/webcodex server tunnel --provider openai --env-file {{CONFIG}}/webcodex.env --json --stop-on-stdin-eof'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
