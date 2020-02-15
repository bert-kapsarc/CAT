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
  data.user.address = _address.toLowerCase()
  data.user.registered = await carboTag.callFn('registered',_address)
  data.user.owner = (await carboTag.callFn('owner')) == _address
  data.user.governor = await carboTag.callFn('governor',_address)
  // == _address

  data.stamper = await getStamperData(_address)


  if(current_user.address!=null){ 
    if(current_user.address != data.user.address){
      let escrowAddr = await carboTag.callFn('findEscrowAddr',[data.user.address,current_user.address])  
      data.escrow = {address: escrowAddr}
      multiSigWallet = new Contract(contract.escrowAbi,escrowAddr)
      const txCount = await carboTag.callFn('escrowTxCount',escrowAddr)
      data.escrow.transactions = []
      data.escrow.txCount = 0
      var tx
      for (i = 0; i < txCount; i++) {
        tx = await carboTag.callFn('escrowTx',[escrowAddr,i])
        if(tx.exists==true){
          data.escrow.txCount += 1
          // make sure all user addresses are consistent case 
          // for conditional comparisson with current or counterparty addres
          tx.issuer = tx.issuer.toLowerCase() 
          if(tx.issuer==current_user.address){
            tx.name = current_user.name
          }else{
            tx.name = data.user.name
          }
          tx.id = i
          tx.confirmed = await multiSigWallet.callFn('confirmations',[tx.multisig_tx_id,current_user.address])
          data.escrow.transactions.push(tx)
        }
      }
    }else{

    }
  }

  next();
}); 

async function getStamperData(_address){
  let _stamperAddr = await carboTag.callFn('stamperRegistry',_address)
  if(_stamperAddr!=0x0000000000000000000000000000000000000000){
    stamperContract = new Contract(contract.stamperAbi,_stamperAddr)
    let _stamper = await stamperContract.callFn('stamper')
    _stamper.address = _stamperAddr
    let votes = await stamperContract.callFn('countGovernorVotes')
    console.log(votes.nay)
    _stamper.yay = votes.yay
    _stamper.nay = votes.nay
    if(current_user!=null && current_user.address!=0x0000000000000000000000000000000000000000){
      let _voteIndex = await stamperContract.callFn('governorVoteIndex', current_user.address)
      _stamper.governorVote  = await stamperContract.callFn('governorVote', _voteIndex)
      console.log(_stamper)
      return(_stamper)
    }
  } 
}

async function getUsers(result,user_type){
  var count = await carboTag.callFn(user_type+'Count')
  var rows = []
  /*
    need to make userIndex public so we can call the contract
    but do we want/need to store account directory within the contract?
    should we jsut do this as an external cntralize service, as with the current querry below
    the search function is available so user's can look for wallets that do not appear in the directory?
  */
  var address, user;
  for (i = 0; i < count; i++) {
    address = await carboTag.callFn(user_type+'Index',i);
    user = await carboTag.callFn('wallet',address);
    rows[i] = {name: user.name, wallet: address};
  }
  result.render('users/index', { users: rows, user_type: user_type})

  /*pool.query(query, (error, results) => {
    if (error) {
      throw error
    }
    result.render('users/index', { users: results.rows})
  })*/
}

/* Users router  page. */
router.get('/',async function (req, res) {
  getUsers(res,'user')
})
router.get('/stampers',async function (req, res) {
  getUsers(res,'stamper')
}).get('/search', async function (req, res) {
  const address  = req.query.address
  data.user = await carboTag.callFn('wallet',address)
  if(data.user){
    data.user.address = address
    data.stamper = await getStamperData(address)
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
  data.user = await carboTag.callFn('wallet',address)
    
  if(data.user!='0x0000000000000000000000000000000000000000'){
    //when user has been created store address
    data.user.address = address
    data.stamper = await getStamperData(address)
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