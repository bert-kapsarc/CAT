nohup ./besu-21.1.6/bin/besu --data-path=./catnet-data/node-1 --genesis-file=./genesis.json --bootnodes=enode://aac55b1fb1c9dee535c25ca1ccb76cd1773a0f398615b52aef0066218936130ea122dbecdc4adfc99b41adc0ea02f0df92f0de6b693337fb1051cd9d2a98f2dd@172.31.45.127:30303 --network-id=10022022 --rpc-http-enabled --host-allowlist="*" --rpc-http-cors-origins="all" --rpc-http-host=0.0.0.0 > /dev/null 2>&1 &
