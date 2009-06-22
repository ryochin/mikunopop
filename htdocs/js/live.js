//

var sec_default = 45;    // per
var sec = sec_default;    // per
var is_first = 1;

function loadLive(once) {
	if( is_first ){
		loadLiveMain(once);
	}
	else{
		$('#update').text("[状況] 情報を更新しています・・");
		setTimeout( "loadLiveMain(" + once + ")", 2000 );
	}
}

var flag = 0;
function loadLiveMain(once) {
	var d = new Date();
	var epoch = parseInt( d.getTime() / 1000, 10);
	
	// get
	$.ajax( {
		url: "/var/live_status.js?" + epoch,
		dataType: "json",
		success: function (result, status) {
			if( result.status === 1 ){
				$('#update').html( "[放送中] " + '<a href="' + result.uri + '" target="_blank">' + result.title + '</a>' );
				
				// alert
				if( $('#alert').attr('checked') ){
					if( flag === 0 ){
						window.alert("ミクノポップの生放送があるよ！");
					}
				}
				
				flag = 1;
				sec = 120;
			}
			else{
				$('#update').html("[状況] 現在、生放送はありません（定期的にチェック）。");
				flag = 0;
				sec = sec_default;
			}
			
			if( is_first ){
				is_first = 0;
			}
		},
		error: function (req, status, error) {
			$('#update').html("[状況] ！ 情報を取得できませんでした orz");
		}
	} );

	// updated
	$('#update').unbind();    // all events cleared
	$('#update').click( function () { loadLive(1); } );

	// set timer
	if( ! once ){
		setTimeout( "loadLive()", sec * 1000 );
	}
}

