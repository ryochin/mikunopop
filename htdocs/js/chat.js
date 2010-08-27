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
			var user = [];
			$.each( result.name, function (name, status) {
				if( status == "active" ){
					user.push( name );
				}
				else if( status == "inactive" ){
					user.push( '<span class="dim" title="離席中">' + name + '</span>' );
				}
			} );
			
			// status
			var str = ( result.num == 0 )
				? "今、チャットルームには誰もいません。求むお留守番。"
				: "今、ルームに" + result.num + " 名います（" + user.join(", ") + "）。";
			
			$('#chat-status').html( str );
			
			// topic
			var topic = ( result.topic != null && result.topic != "" )
				? 'トピックは「<span id="chat-topic-title">' + result.topic + '</span>」です。'
				: "トピックは設定されていません。";
			
			$('#chat-topic').html( topic );
		},
		error: function (req, status, error) {
			;
		}
	} );

	// set timer
	setTimeout( "loadChat()", chat_interval * 1000 );
}

