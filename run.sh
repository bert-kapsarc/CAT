osascript -e 'tell app "Terminal"
    do script "ganache-cli -i 5777"
end tell';
truffle migrate --network development;