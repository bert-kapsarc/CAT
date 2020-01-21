var createError = require('http-errors');
const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const multer = require('multer')
const upload = multer();
/*const helmet = require('helmet')
const compression = require('compression')
const rateLimit = require('express-rate-limit')
const expressValidator = require('express-validator')*/

var path=require('path');

var logger = require('morgan');
var cookieParser = require('cookie-parser');

// load a carboTag contract as global variable
const Contract = require('./public/javascripts/contract');
const fs = require('fs');

var jsonFile = "../build/contracts/CarboTag.json";
global.site = 
{
    title: 'CarboTag'
}
global.author = {
    name: 'Bertrand Rioux',
    contact: 'bertrand.rioux@gmail.com'
}
let abi = JSON.parse(fs.readFileSync(jsonFile)).abi;
global.contract = {
   abi: abi,
   escrowAbi: JSON.parse(fs.readFileSync("../build/contracts/MultiSigWallet.json")).abi,
   address: process.env.CARBO_TAG_ADDR,
   rpcURL: process.env.INFURA_ROPSTEN
}
global.current_user = {address: null}; // address extracted from active metamask plugin

// store carboTag contract as gloabl json object
global.carboTag = new Contract(abi,process.env.CARBO_TAG_ADDR)

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');
var escrowsRouter = require('./routes/escrows');

const app = express()

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

// for parsing multipart/form-data
app.use(upload.array()); 
app.use(cors())
app.use(express.static(path.join(__dirname,"public")))

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug')

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);
app.use('/users', usersRouter);
app.use('/escrows', escrowsRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;

