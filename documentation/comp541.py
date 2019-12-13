#  DFIN 541 mini bitcoin project
# A simple python 3.5 script for recording a string argument on the bitcoin blockchain
# Requires python-bitcoinrpc library
from decimal import *
from bitcoin import *
# to convert string to hexadecimal
from binascii import *
# Import Python bitcoinrpc library for Bitcoins API calls
from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException
# For loading environment variables in python
import os

# Setup RPC connection to send Bitcoin API calls to server
# collect rpcuser and rpcpassword asssumed to have been stored in user's environment variables
rpcuser = os.getenv("RPCUSER")
rpcpassword = os.getenv("RPCPASS")
rpc_connection = AuthServiceProxy("http://%s:%s@127.0.0.1:18332"%(rpcuser,rpcpassword))

# Enter string argument to store on the blockchain
string = input('Type a message to store on the blockchain: ')
# Convert to hexadecimal format
hex = hexlify(string.encode())
string = unhexlify(b"%s"%(hex))
print('data hex: '+hex.decode())
print('string: '+string.decode())

# Calculate a transaction relay fee (0.0001)
tx_fee = Decimal(1)/Decimal(10000)

# Get list of unspent transactions
unspent = rpc_connection.listunspent()

# Loop over unspent transactions
i = 0
while i < len(unspent):

# Get amount listed unpent transaction
 amount=unspent[i]['amount']
# If balance is greater than fee proceed to create raw transaction
# (not so smart function for selecting transaction inputs!)
 if amount > tx_fee:

# Get Transaction id and output # of unspent transaction
  txid = unspent[i]['txid']
  vout = unspent[i]['vout']

# Remove the fee from the unspent transaction balance. 
# The remainder is returned to the senders change_address
  amount = amount - tx_fee
  change_address=rpc_connection.getrawchangeaddress()

# New transaction input
  input = [{"txid": txid, "vout": vout}]
# New transaction output including amount sent to change_address and the hexadecimal string
  output = {change_address : amount, "data": hex.decode()}

# Create unsigned transaction
  raw_tx = rpc_connection.createrawtransaction(input,output)

# Unlock user wallet before signing, assuming the pass[hrase is stored in environment variables as WALLET_PASS (safe?)
  rpc_connection.walletpassphrase(os.environ.get("WALLET_PASS"),100)

# Sign transaction and send
  signed_tx = rpc_connection.signrawtransaction(raw_tx)
  status = rpc_connection.sendrawtransaction(signed_tx["hex"])

# print the decoded transaction
  decoded = rpc_connection.decoderawtransaction(signed_tx["hex"])
  if signed_tx['complete']:
   print("status: complete")
   print("tx info: "+str(decoded))
  else:
   print("error: "+signed_tx['error'])

#  stop the while loop
  break
 else:
  i += 1
