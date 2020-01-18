$(document).ready(function(){
    let input = document.getElementById('searchSubmit')
    input.onclick = search
    function search(event){
      $.ajax({
        type: 'get',
        url: '/users/'+document.querySelector('input[name=walletSearch]').value,
        success: function(data){
          $('#searchResult').html(data);
          //form = document.querySelector('form[name=signup]')
        },
        error: function(data) {
          console.log(data);
          alert('error');
        }
      })
    }
});