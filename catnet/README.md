# catnet
This page lists steps to create a simple private ethereum network.

### Prerequisites

Java 
make sure you have java 11 and above
```javascript
java -version
```
### Install Besu
Download Besu from https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/21.1.6/besu-21.1.6.zip

Extract it to catnet directory. Resulting directory structure should look like

- besu-21.1.6
  - bin
  - lib
- catnet-data
  - node-1
- genesis.json
- genesisnode.sh
- node.sh


### Start a new network (Skip if a network is already up)
Edit properties in genesis.json

```javascript
./genesisnode.sh
```

### Connect to existing network
Edit the bootnode ip if needed. Boot node is from the genesis node started in the previous step.

```javascript
./node.sh
```

Reference : https://besu.hyperledger.org/en/stable/Tutorials/Private-Network/Create-Private-Network/
