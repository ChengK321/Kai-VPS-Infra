[Unit]
Description=WebCodex Runner
After=network-online.target webcodex.service
Requires=webcodex.service

[Service]
Type=simple
User={{USER}}
Group={{GROUP}}
WorkingDirectory={{HOME}}
Environment=HOME={{HOME}}
ExecStart={{NPM_BIN}}/webcodex runner run --config {{RUNNER_CONFIG}}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
