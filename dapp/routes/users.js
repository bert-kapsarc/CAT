var express = require('express');
var router = express.Router();

// for querying postgres
const { pool } = require('../config')


const getUsersJSON = (request, response) => {
  pool.query(users_query, (error, results) => {
    if (error) {
      throw error
    }
    response.status(200).json(results.rows)
  })
}

const addUser = (request, response) => {
  const { name, wallet } = request.body

  pool.query('INSERT INTO users (name, wallet) VALUES ($1, $2)', [name, wallet], error => {
    if (error) {
      throw error
    }
    response.status(201).json({ status: 'success', message: 'User added.' })
  })
}

const users_query = 'SELECT * FROM users ORDER BY id ASC'; 
const stampers_query = 'SELECT * FROM users WHERE stamper = TRUE ORDER BY id ASC'; 

async function getUsers(result,query){
  /*
  const count = await carboTag.callFn('accountCount')
  const rows = []
  for (i = 0; i < 5; i++) {
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

router.get('/form', async function (req, res) {
  console.log(req.query)
  const wallet = await carboTag.callFn('wallet',req.query.address)
  const stamper = await carboTag.callFn('stampRegister',req.query.address)
  if(wallet.registered){
    res.render('profile', {
        user: wallet,
        address: req.query.address,
        stamper: stamper
    }) 
  }else{
    res.render('form', {
        address: req.query.address
    })    
  }
})
.post('/',async function (req, res) {
  const { name, wallet } = req.body
  //console.log(address)
  const carboDebtWallet = await carboTag.callFn('wallet',wallet)
  const stamper = await carboTag.callFn('stampRegister',wallet)
  
  pool.query('INSERT INTO users (name, wallet) VALUES ($1, $2)', [name, wallet], error => {
    if (error) {
      throw error
    }else{
      res.render('profile', {
          wallet: carboDebtWallet,
          stamper: stamper
      })
    }
  })
})

//.post(addUser)


module.exports = router;