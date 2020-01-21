var express = require('express');
var router = express.Router();

// for querying postgres
const { pool } = require('../config')

// Contract module to get instance of and call on MultiSigWallet
const Contract = require('../public/javascripts/contract');

const users_query = 'SELECT * FROM users ORDER BY id ASC'; 
const stampers_query = 'SELECT * FROM users WHERE stamper = TRUE ORDER BY id ASC'; 

const data = {}
router.param('address', async function(req, res, next, _address){
  // Do something with id
  // Store id or other info in req object
  // Call next when done
  data.user = await carboTag.callFn('wallet',_address)
  data.user.address = _address
  data.user.owner = await carboTag.callFn('owner',_address)
  data.stamper = await carboTag.callFn('stampRegister',_address)
  if(current_user.address!=null){ 
    if(current_user.address != data.user.address){
      let escrowAddr = await carboTag.callFn('findEscrowAddr',[data.user.address,current_user.address])  
      data.escrow = {address: escrowAddr}
      multiSigWallet = new Contract(contract.escrowAbi,escrowAddr)
      const txCount = await carboTag.callFn('escrowTxCount',escrowAddr)
      data.escrow.transactions = []
      var tx
      for (i = 0; i < txCount; i++) {
        tx = await carboTag.callFn('escrowTx',[escrowAddr,i])
        if(tx.exists){
          data.escrow.transactions[i] = tx
          data.escrow.transactions[i].confirmed = 
            await multiSigWallet.callFn('confirmations',[tx.multisig_tx_id,current_user.address])
        }
      }
    }else{

    }
  }

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
    result.render('users/index', { users: results.rows})
  })
}

/* Users router  page. */
router.get('/',async function (req, res) {
  getUsers(res,users_query)
})
router.get('/stampers',async function (req, res) {
  getUsers(res,stampers_query)
}).get('/search', async function (req, res) {
  const address  = req.query.address
  data.user = await carboTag.callFn('wallet',address)
  if(data.user){
    data.user.address = address
    data.stamper = await carboTag.callFn('stampRegister',address)
    res.render('users/show', {data: data})
  }else{
    res.render('error', { message: 'no user'})
  }
})

// get sign up or current_user instance by passing address read from metamask
router.get('/form/:address', function (req, res) {
  //store current user
  global.current_user = data.user
  if(data.user.registered){
    res.render('users/_profile', {data: data}) 
  }else{
    res.render('users/_signup')    
  }
})
.get('/:address', function (req, res) {
  res.render('users/show', {data: data})
})
// render current_user's escrow with :address, or form to create one
.get('/:address/escrow/', function (req, res) {
  res.render('users/_escrow', {data: data})
})

// create new user
router.post('/',async function (req, res) {
  const { name, address } = req.body
  console.log(address)
  data.user = await carboTag.callFn('wallet',address)
    
  if(data.user){
    //when user has been created store address
    data.user.address = address
    data.stamper = await carboTag.callFn('stampRegister',address)
    // insert into PG db if user registered to contract
    pool.query('INSERT INTO users (name, wallet) VALUES ($1, $2)', [data.user.name, address], error => {
      if (error) {
        throw error
      }else{res.render('users/show', {data: data})}
    })
  }
})

.post('/stamper/:address', function (req, res) {
  pool.query('UPDATE users SET stamper = true WHERE wallet = ($1)', [data.user.address], error => {
    if (error) {
      throw error
    }else{res.render('users/show', {data: data})}
  })
  
})

//.post(addUser)


module.exports = router;