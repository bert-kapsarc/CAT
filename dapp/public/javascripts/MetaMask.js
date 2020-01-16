async function MetaMask(abi,contractAddr,rpcURL) {
  //window.addEventListener('load', async function() {
    var provider, address
    if (window.ethereum) {  
      var form, name
      // boolean to halt form submit while user submits carboTag signUp fn 
      let confirmation = false;
      try {
        $(document).ready(function(){
          window.web3 = new Web3(ethereum)
          provider = window.web3.currentProvider
          address = provider.selectedAddress
          $.ajax({
            type: 'get',
            url: '/users/form',
            data: {address: address},
            success: function(data){
              $('#signup').html(data);
              form = document.querySelector('form[name=signup]')
              if($(form).length>0){
                form.onsubmit = signup;
              }
            },
            error: function(data) {
              console.log(data);
              alert('error');
            }
          })
        });
        // Request account access if needed
        await ethereum.enable();
        // Acccounts now exposed
        //web3.eth.sendTransaction({});
        //console.log(web3.eth.getAccounts())
      } catch (error) {
        console.log(error)
        console.log('User denied account access...')
      }

      function signup(event) {
        if(!confirmation){
          name = form.querySelector('input[name=name]').value
          const web3 = new Web3(new Web3.providers.HttpProvider(rpcURL))
          const carboTag = new web3.eth.Contract(abi, contractAddr)
          //form.setAttribute('hidden', '')
          let data = carboTag.methods.signUp(name).encodeABI();
          window.web3.eth.sendTransaction({from: address, to: contractAddr, data: data})
          .on('confirmation', function(confirmationNumber, receipt){ 
            console.log(receipt)
            confirmation = true;
            $(form).submit();
          }).on('error', function(){console.error})
          return false
        }
        //.sendFn('signUp(string)',address,name)
        // For this example, don't actually submit the form
        // event.preventDefault();
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      window.web3 = new Web3(web3.currentProvider);
      // Acccounts always exposed
      //web3.eth.sendTransaction({});
    }
    // Non-dapp browsers...
    else {
      console.log('Non-Ethereum browser detected. You should consider trying MetaMask!');
    }
  
  //})
  }
/*
  async componentWillMount() {
    await this.loadWeb3()
  }

  async loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum)
      await window.ethereum.enable()
    }
    else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider)
    }
    else {
      window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!')
    }
  }

  async componentWillMount() {
    await this.loadWeb3()
    await this.loadBlockchainData()
  }

  async loadBlockchainData() {
    const web3 = window.web3
    const accounts = await web3.eth.getAccounts()
    console.log(accounts)
    return accounts[0]
    //this.setState({ account: accounts[0] })
  }

}
*/