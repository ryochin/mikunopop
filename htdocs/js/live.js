//

var min = 2;    // per min
var min_disp = '５';
var is_first = 1;

function loadLive(once) {
	if( is_first ){
		loadLiveMain(once);
	}
	else{
		$('#update').text("更新しています・・");
		setTimeout( "loadLiveMain(" + once + ")", 2000 );
	}
}

var flag = 0;
function loadLiveMain(once) {
	// get
	$.ajax( {
		url: "/var/live_status.js",
		dataType: "json",
		success: function (result, status) {
			if( result.status === 1 ){
				$('#update').html( "[放送中] " + '<a href="' + result.uri + '">' + result.title + '</a>' );
				
				// alert
				if( $('#alert').attr('checked') ){
					if( flag == 0 ){
						window.alert("ミクノポップの生放送が始まったよ！");
					}
				}
				
				flag = 1;
			}
			else{
				$('#update').html("[状況] 現在、生放送はありません。");
				flag = 0;
			}
			
			if( is_first ){
				is_first = 0;
			}
		},
		error: function (req, status, error) {
			$('#update').html("！　情報を取得できませんでした orz");
		}
	} );

	// updated
	$('#update').unbind();    // all events cleared
	$('#update').click( function () { loadLive(1); } );

	// set timer
	if( ! once ){
		setTimeout( "loadLive()", min * 60 * 1000 );
	}
}

