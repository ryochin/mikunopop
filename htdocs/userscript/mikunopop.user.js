// ==UserScript==
// @name           Mikunoop Tools
// @namespace      http://mikunopop.info/
// @description    Mikunopop Utility Tools
// @include        http://www.nicovideo.jp/watch/*
// @version        0.0.1
// @require        http://ajax.googleapis.com/ajax/libs/jquery/1.7/jquery.min.js
// ==/UserScript==

(function(){
	var id = location.href.split('/').reverse()[0];
	var countURL = "http://mikunopop.info/count/" + id;
	var style = 'margin: auto 4px; color: #cc3333';
	
	function setCount(n) {
		var str = "彡" + n;
		$("<span>")
			.text( str )
			.attr('style', style)
			.insertBefore('#video_article');
	}
	
	GM_xmlhttpRequest({
		method: "GET",
		url: countURL,
		onload: function(xhr) {
			setCount(xhr.responseText);
		}
	});
})();