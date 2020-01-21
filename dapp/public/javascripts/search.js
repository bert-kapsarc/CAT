$(document).ready(function(){
    let input = document.getElementById('searchSubmit')
    input.onclick = search
    function search(event){
      $.ajax({
        type: 'get',
        url: '/users/search/'+document.querySelector('input[name=walletSearch]').value,
        success: function(data){
          $('#searchResult').html(data);
          getEscrow()
          //form = document.querySelector('form[name=signup]')
        },
        error: function(data) {
          console.log(data);
          alert('error');
        }
      })
    }
});