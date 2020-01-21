// Contract module to get instance of and call on MultiSigWallet
const Contract = require('./contract');

async function getTxData(escrowAddr){
  let multiSigWallet = new Contract(contract.escrowAbi,escrowAddr)
  const txCount = await carboTag.callFn('escrowTxCount',escrowAddr)
  var transactions = []
  for (i = 0; i < txCount; i++) {
    let tx = await carboTag.callFn('escrowTx',[escrowAddr,i])
    if(tx.exists){
      transactions[i] = tx
      transactions[i].confirmed = 
        await multiSigWallet.callFn('confirmations',[tx.multisig_tx_id,current_user.address])
    }
  }
  return {
    address: escrowAddr,
    transactions: transactions
  }
}