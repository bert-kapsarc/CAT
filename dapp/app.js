var createError = require('http-errors');
const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const multer = require('multer')
const upload = multer()
const env = require('dotenv').config()
/*const helmet = require('helmet')
const compression = require('compression')
const rateLimit = require('express-rate-limit')
const expressValidator = require('express-validator')*/

var path=require('path');

var logger = require('morgan');
var cookieParser = require('cookie-parser');

const Contract = require('./public/javascripts/contract');
const fs = require('fs');

var CATjson = "../build/contracts/CAT.json";
global.site = 
{
    title: 'CAT'
}
global.author = {
    name: 'Bertrand Rioux',
    contact: 'bertrand.rioux@gmail.com'
}
let CATabi = JSON.parse(fs.readFileSync(CATjson)).abi;
global.contract = {
  CATabi: CATabi,
  escrowAbi: JSON.parse(fs.readFileSync("../build/contracts/MultiSigWallet.json")).abi,
  stamperAbi: JSON.parse(fs.readFileSync("../build/contracts/Stamper.json")).abi,
  CATaddr: process.env.CAT_ADDR,
  rpcURL: process.env.NETWORK_URL
}
global.current_user = {address: null}; // address extracted from active metamask plugin

// store cat contract as global json object
global.cat = new Contract(CATabi,process.env.CAT_ADDR);
var MSWFactAbi = JSON.parse(fs.readFileSync("../build/contracts/MultiSigWalletFactory.json")).abi;
let MSWFactAddr = cat.callFn('factory_addr');
global.MSWFactory = new Contract(MSWFactAbi,MSWFactAddr);

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

