function refreshing(){
    console.log("hello");
    var refresh = true;
    $('.fa').click(function(){
        refresh = !refresh;
        console.log(refresh);
        if(refresh) $('.auto-refresh-button').removeClass("fa-circle-o").addClass("fa-dot-circle-o");
        else $('.auto-refresh-button').removeClass("fa-dot-circle-o").addClass("fa-circle-o");
    });
    setInterval(function(){ if(refresh) location.reload() }, 3000);
    
}