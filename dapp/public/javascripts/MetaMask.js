function MetaMask(contract){
  window.web3 = new Web3(window.ethereum);
  const web3 = new Web3(new Web3.providers.HttpProvider(contract.rpcURL))
  const carboTag = new web3.eth.Contract(contract.abi, contract.address)
  var address, browse, stamperForms={}
  window.addEventListener('load', async function() {
    if (window.ethereum) {
      ethereum.on('chainChanged', (_chainId) => window.location.reload());
      await ethereum.request({ method: 'eth_requestAccounts' });
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      console.log('legacy');
      window.ethereum = new Web3(web3.currentProvider);
    }
    if(window.ethereum){
      browser = window.ethereum
      getUserProfile()
      window.ethereum.on('accountsChanged', function (accounts) {
        getUserProfile()
      })
      if(window.ethereum.networkVersion== 3 || 1337){
        $('#browser').html('&#10004;')
        browser = "Connected to Ropsten"
      }else{
        browser = "Warning: you are not connected to Ropsten. Change metamask network"
      }
    }else{
    // Non-dapp browsers...
      browser = 'Your browser is not connected to Ethereum. Try <a href="https://metamask.io/"> MetaMask </a> to setup an account with SACAT.'
      //$('#metaMask').html('<h3>'+browser+'</h3>')
    } 
    $('#browser').append(browser)
  })
  function getUserProfile(){
    // TODO review isStatus (for beta metamask mobile app ?)
    if(window.ethereum.isStatus){
      window.ethereum.status
      .getContactCode()
      .then(data => {
        console.log('Contact code:', data)
      })
      .catch(err => {
        console.log('Error:', err)
      })
    }else{
      address = window.ethereum.selectedAddress
    }
    $.ajax({
      type: 'get',
      url: '/users/form/'+address,
      success: function(data){
        $('#metaMask').html(data);
        let signupForm = document.querySelector('form[name=signup]')
        if(signupForm!=null){
          signupForm.onsubmit = signUp;
          $('#counterparty').children('#CPforms').html(null)
        }else{
          // If a counterparty address has been loaded
          // call the escrow form/data
          if($('#counterparty').length>0){
            getEscrow()
          }
        }
      },
      complete: function(data){
        var form = document.querySelector('form[name=addCarbon]')
        if(form != null){form.onsubmit = addCarbon}
        // forms to add user as stamper
        let addStamperForms = document.getElementsByName('addStamper');
        for (var i = 0; i < addStamperForms.length; i++) {
          form = addStamperForms[i]
          if(form != null){form.onsubmit = addStamper}
        }
        // forms to vote for users as stamper
        let stamperForms = document.getElementsByName('stamperVote');
        for (var i = 0; i < stamperForms.length; i++) {
          form = stamperForms[i]
          if(form != null){form.onsubmit = stamperVote}
        }
        form = document.querySelector('form[name=stamp]')
        if(form != null){
          form.onsubmit = stamp
        }
      },
      error: function(data) {
        console.log(data);
        alert('error');
      }
    })
  }
  function signUp(event){
    const name = getPath(event).querySelector('input[name=name]').value
    event.txData = carboTag.methods['signUp'](name).encodeABI();
    return sendTx(event)
  }

  function getEscrow(){
    let counterpartyAddr = $('#counterparty').attr("address");
    $.ajax({
      // ajax request to get escrow data (register or send txs)
      type: 'get',
      url: '/users/'+$('#counterparty').attr("address")+'/escrow',
      success: function(data){
        let forms = $('#counterparty').children('#CPforms').html(data)[0];
        let escrowForm = forms.querySelector('form[name=createEscrow]')
        let txForm = forms.querySelector('form[name=createTx]')
        if(escrowForm!==null){          
          escrowForm.onsubmit = createEscrow;
        }else if(txForm!==null){
          txForm.onsubmit = createTx
          var escrowAddr = txForm.escrowAddr
          if(escrowAddr!==null){
            escrowAddr = escrowAddr.value
            let escrow = new web3.eth.Contract(contract.escrowAbi,escrowAddr)
            $.each(document.getElementsByClassName('confirmEscrowTx'), function(index, element) {
              let txId = element.escrowTxId.value
              console.log(escrowAddr)
              if(escrowAddr!==null){element.onsubmit = function(event){
                // store tx destination
                event.destination = escrowAddr;
                event.txData = escrow.methods['confirmTransaction'](txId).encodeABI();
                return sendTx(event)
              }}
            });
            $.each(document.getElementsByClassName('rejectEscrowTx'), function(index, element) {
              let txId = element.txId.value
              if(escrowAddr!==null){element.onsubmit = function(event){
                event.txData = carboTag.methods['rejectTransaction'](counterpartyAddr,txId).encodeABI();
                return sendTx(event)
              }}
            });
          }
        }
      },
      complete: function(){
        
      },
      error: function(data) {
        console.log(data);
        alert('error');
      }
    })
  }

  function getRadioValue(radios){
    for (var i = 0; i < radios.length; i++) {
      if (radios[i].checked) {
        return radios[i].value
        break;
      }
    }
  }


  function getPath(event){
    var path = event.path || (event.composedPath && event.composedPath());
    if (path) {
      return path[0];
    } else {
      return false;
    }

  }

  function stamperVote(event){
    let stamperAddr = getPath(event).querySelector('input[name=stamperAddr]').value 
    let stamperContract = new web3.eth.Contract(contract.stamperAbi,stamperAddr)
    //event.txData = carboTag.methods['createEscrow']($('#counterparty').attr("address")).encodeABI();
    let radios = document.getElementsByName('voteFor'+stamperAddr)
    let vote = getRadioValue(radios)
    event.txData = stamperContract.methods['vote'](vote=="true").encodeABI()
    event.destination = stamperAddr
    return sendTx(event)
  }

  function createEscrow(event){
    //event.txData = carboTag.methods['createEscrow']($('#counterparty').attr("address")).encodeABI();
    event.txData = carboTag.methods['createEscrow'](getPath(event).querySelector('input[name=counterparty]').value).encodeABI();
    return sendTx(event)
  }

  function createTx(event){
    const counterparty = getPath(event).querySelector('input[name=counterparty]').value

    // Get value of carbon gold to transact and sign of transaction (send (+)/ recevie (-))
    let carbon = getPath(event).querySelector('input[name=carbon]').value
    let radios = document.getElementsByName('txCarbon'+getPath(event).escrowAddr.value);
    carbon *= getRadioValue(radios)

    let gold = getPath(event).querySelector('input[name=gold]').value
    radios = document.getElementsByName('txGold'+getPath(event).escrowAddr.value);
    gold *= getRadioValue(radios)

    event.txData = carboTag.methods['createTransaction'](counterparty,carbon,gold).encodeABI();
    
    return sendTx(event)
  }
  function addCarbon(event){
    const carbon = getPath(event).querySelector('input[name=carbon]').value
    event.txData = carboTag.methods['addCarbon'](carbon).encodeABI();
    return sendTx(event)
  }
  function addStamper(event){
    const stamper = getPath(event).querySelector('input[name=stamper]').value
    const stampRate = getPath(event).querySelector('input[name=stampRate]').value
    const minPayment = 0//getPath(event).querySelector('input[name=minPayment]').value
    event.txData = carboTag.methods['addStamper'](stamper,stampRate,minPayment).encodeABI();
    return sendTx(event)
  }
  function stamp(event){
    let stamperAddr = getPath(event).querySelector('input[name=stamperAddr]').value
    let stamperContract = new web3.eth.Contract(contract.stamperAbi,stamperAddr)
    event.txData = stamperContract.methods['stamp']().encodeABI();
    event.destination = stamperAddr
    return sendTx(event)
  }

  let confirmed = {}
  async function sendTx(event) {
    event.preventDefault();
    let path = getPath(event);
    //console.log(confirmed)
    if(event.destination==null){
      // default destination carboTag contract for majority of calls
      event.destination = contract.address
    }
    if(confirmed[event.target.name]){
      confirmed[event.target.name] = false
      return true;
    }else{
      try {
        const transactionHash = await ethereum.request({
          method: 'eth_sendTransaction',
          params: [
            {
              to: event.destination,
              from: address,
              data: event.txData,
              // And so on...
            },
          ],
        });
        console.log(transactionHash);
        
        // Handle the result
      } catch (error) {
        console.error(error);
        console.log('User denied account access...')
      } finally{
      }
        
        
    }
  }

}