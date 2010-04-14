//

var chat_interval = 180;

function loadChat(once) {
	var d = new Date();
	var epoch = parseInt( d.getTime() / 1000, 10);
	
	// get
	$.ajax( {
		url: "/var/chat_status.js?" + epoch,
		dataType: "json",
		success: function (result, status) {
			// num
			if( result.num == 0 ){
				$('#chat-status').html("今、チャットルームには誰もいません。" );
			}
			else{
				var str = "今、チャットルームに " + result.num + " 名います（" + result.name.join(", ") + "）。" ;
				if( result.topic != null && result.topic != "" ){
					str += "トピックは「" + result.topic + "」です。";
				}
				$('#chat-status').html( str );
			}
		},
		error: function (req, status, error) {
			;
		}
	} );

	// set timer
	setTimeout( "loadChat()", chat_interval * 1000 );
}

