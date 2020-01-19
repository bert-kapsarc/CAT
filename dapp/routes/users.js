var express = require('express');
var router = express.Router();

// for querying postgres
const { pool } = require('../config')

// Contract module to get instance of and call on MultiSigWallet
const Contract = require('../public/javascripts/contract');

const users_query = 'SELECT * FROM users ORDER BY id ASC'; 
const stampers_query = 'SELECT * FROM users WHERE stamper = TRUE ORDER BY id ASC'; 

router.param('address', async function(req, res, next, _address){
  // Do something with id
  // Store id or other info in req object
  // Call next when done
  req.data = {}

  req.data.user = await carboTag.callFn('wallet',_address)
  req.data.user.address = _address
  req.data.user.owner = await carboTag.callFn('owner',_address)
  if(current_user.address!=null){
    let escrowAddr = await carboTag.callFn('findEscrowAddr',[req.data.user.address,current_user.address])  
    req.data.escrow = {address: escrowAddr}
    multiSigWallet = new Contract(contract.escrowAbi,escrowAddr)
    const txCount = await carboTag.callFn('escrowTxCount',escrowAddr)
    req.data.escrow.transactions = []
    var tx
    for (i = 0; i < txCount; i++) {
      tx = await carboTag.callFn('escrowTx',[escrowAddr,i])
      if(tx.exists){
        req.data.escrow.transactions[i] = tx
        req.data.escrow.transactions[i].confirmed = 
          await multiSigWallet.callFn('confirmations',[tx.multisig_tx_id,current_user.address])
      }
    }
  }
  req.data.stamper = await carboTag.callFn('stampRegister',_address)
  next();
}); 

async function getUsers(result,query){
  const count = await carboTag.callFn('accountCount')
  const rows = []
  /*
    need to make accountIndex public so we can call the contract
    but do we want/need to store account directory within the contract?
    should we jsut do this as an external cntralize service, as with the current querry below
    the search function is available so user's can look for wallets that do not appear in the directory?
  for (i = 0; i < count; i++) {
    const address = await carboTag.callFn('accountIndex',i)
    const user = await carboTag.callFn('wallet',address)
    rows[i] = [user.name,user.wallet];
  }
  result.render('users', { users: rows})
  */
  pool.query(query, (error, results) => {
    if (error) {
      throw error
    }
    result.render('users', { users: results.rows})
  })
}

/* Users router  page. */
router.get('/',async function (req, res) {
  getUsers(res,users_query)
})
router.get('/stampers',async function (req, res) {
  getUsers(res,stampers_query)
})

router.get('/form/:address', function (req, res) {
  //store current user
  global.current_user = req.data.user
  if(req.data.user.registered){
    res.render('profile', {data: req.data}) 
  }else{
    res.render('signup')    
  }
}).get('/:address', function (req, res) {
  res.render('show', {data: req.data})
})

router.post('/',async function (req, res) {
  const { name, address } = req.body
  console.log(req.body)
  req.data = {}
  req.data.address = address
  req.data.user = await carboTag.callFn('wallet',address)
  req.data.stamper = await carboTag.callFn('stampRegister',address)
  
  pool.query('INSERT INTO users (name, wallet) VALUES ($1, $2)', [name, address], error => {
    if (error) {
      throw error
    }else{res.render('profile', {data: req.data})}
  })
})
.get('/escrow/:address', function (req, res) {
  res.render('escrow', {data: req.data})
})
.post('/stamper/:address', function (req, res) {
  pool.query('UPDATE users SET stamper = true WHERE wallet = ($1)', [req.data.user.address], error => {
    if (error) {
      throw error
    }else{res.render('show', {data: req.data})}
  })
  
})

//.post(addUser)


module.exports = router;