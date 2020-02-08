function MetaMask(contract){
  const web3 = new Web3(new Web3.providers.HttpProvider(contract.rpcURL))
  const carboTag = new web3.eth.Contract(contract.abi, contract.address)
  var address, browse, escrow, stamper
  window.addEventListener('load', async function() {
    if (window.ethereum) {
      window.web3 = new Web3(ethereum)  
      await ethereum.enable();
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      window.web3 = new Web3(web3.currentProvider);
    }
    if(window.web3){
      browser = window.web3
      getUserProfile()
      window.ethereum.on('accountsChanged', function (accounts) {
        getUserProfile()
      })
      if(window.web3.currentProvider.networkVersion==3){
        browser = "Connected to Ropsten"
      }else{
        browser = "Warning: you are not connected to Ropsten. Change metamask network"
      }
    }else{
    // Non-dapp browsers...
      browser = 'Non-Ethereum browser detected. You should consider trying MetaMask!'
      console.log(browser);
      $('#metaMask').html('<h3>'+browser+'</h3>')
    } 
  })
  function getUserProfile(){
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
      address = window.web3.currentProvider.selectedAddress
    }
    $.ajax({
      type: 'get',
      url: '/users/form/'+address,
      success: function(data){
        $('#metaMask').html(data);
        let signupForm = document.querySelector('form[name=signup]')
        if(signupForm!=null){
          signupForm.onsubmit = signUp;
        }else{
          // If a counterparty address has been loaded
          // call the escrow form/data
          if($('#counterparty').length>0){
            // Form to add counterparty as stamper
            let stamperForm = document.querySelector('form[name=addStamper'+ $('#counterparty').attr("address")+']')
            if(stamperForm!=null){stamperForm.onsubmit = addStamper}
            getEscrow()
          }
          document.querySelector('form[name=addCarbon]').onsubmit = addCarbon

          // form to add current address as stamper
          let stamperForm = document.querySelector('form[name=addStamper'+address+']')
          let stampForm = document.querySelector('form[name=stamp]')

          if(stamperForm!=null){stamperForm.onsubmit = addStamper}
          if(stampForm != null){
            var stamperAddr = document.querySelector('input[name=stamperAddr]')
            stamper = new web3.eth.Contract(contract.stamperAbi,stamperAddr)
            stampForm.onsubmit = stamp
          }



        }
        document.getElementById('browser').append(browser)

      },
      error: function(data) {
        console.log(data);
        alert('error');
      }
    })
  }
  function signUp(event){
    const name = event.path[0].querySelector('input[name=name]').value
    event.txData = carboTag.methods['signUp'](name).encodeABI();
    return sendTx(event)
  }

  function getEscrow(){
    let receiverAddr = $('#counterparty').attr("address");
    $.ajax({
      // ajax request to get escrow data (register or send txs)
      type: 'get',
      url: '/users/'+$('#counterparty').attr("address")+'/escrow',
      success: function(data){
        $('#counterparty').append(data);
        let form = document.querySelector('form[name=createEscrow]')
        if($(form).length>0){          
          //do something on submit
          form.onsubmit = createEscrow;
        }else{
          let txForm = document.querySelector('form[name=createTx]')
          if(txForm!=null){txForm.onsubmit = createTx}
          
          var escrowAdrr = document.querySelector('input[name=escrowAddr]')

          if(escrowAdrr!=null){
            escrowAdrr = escrowAdrr.value
            escrow = new web3.eth.Contract(contract.escrowAbi,escrowAdrr)
            var txID
            $.each(document.getElementsByClassName('confirmEscrow'), function(index, value) {
              txID = value.querySelector('input[name=escrowTxId]').value
              //console.log(txID)
              value.onsubmit = function(event){
                // store tx destination
                event.destination = escrowAdrr;
                event.txData = escrow.methods['confirmTransaction'](txID).encodeABI();
                return sendTx(event)
              }
              //acceptTx
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

  function createEscrow(event){
    //event.txData = carboTag.methods['createEscrow']($('#counterparty').attr("address")).encodeABI();
    event.txData = carboTag.methods['createEscrow'](event.path[0].querySelector('input[name=counterparty]').value).encodeABI();
    return sendTx(event)
  }

  function createTx(event){
    const counterparty = event.path[0].querySelector('input[name=counterparty]').value
    const gold = event.path[0].querySelector('input[name=gold]').value
    const carbon = event.path[0].querySelector('input[name=carbon]').value
    event.txData = carboTag.methods['createTransaction'](counterparty,carbon,gold).encodeABI();
    return sendTx(event)
  }
  function addCarbon(event){
    const carbon = event.path[0].querySelector('input[name=carbon]').value
    event.txData = carboTag.methods['addCarbon'](carbon).encodeABI();
    return sendTx(event)
  }
  function addStamper(event){
    const stamper = event.path[0].querySelector('input[name=stamper]').value
    const stampRate = event.path[0].querySelector('input[name=stampRate]').value
    const minPayment = event.path[0].querySelector('input[name=minPayment]').value
    event.txData = carboTag.methods['addStamper'](stamper,stampRate,minPayment).encodeABI();
    return sendTx(event)
  }
  function stamp(event){
    event.txData = stamper.methods['stamp']().encodeABI();
    return sendTx(event)
  }

  let confirmed = {}
  function sendTx(event) {
    //console.log(confirmed)
    if(event.destination==null){
      // default destination carboTag contract for majority of calls
      event.destination = contract.address
    }
    if(confirmed[event.target.name]){
      confirmed[event.target.name] = false
      return true
    }else{
      try {
        //console.log(event)
        window.web3.eth.sendTransaction({from: address, to: event.destination, data: event.txData})
        .on('confirmation', function(confirmationNumber, receipt){ 
          // set confirmed status of current form. 
          // NOte security issue if form names are not unique.
          // Can cause overwritting of confimration status preventing form from being submitted, or causing multiple sendTransaction requests!
          confirmed[event.target.name] = true
          event.path[0].submit()
        }).on('error', function(){
          console.error
          //return false
        })
          
        // For this example, don't actually submit the form
        // event.preventDefault();
      }catch (error) {
        console.log(error)
        console.log('User denied account access...')
      }
      return false
    }
  }
}