// ==UserScript==
// @name           Mikunoop Tools
// @namespace      http://mikunopop.info/
// @description    Mikunopop Utility Tools
// @include        http://www.nicovideo.jp/watch/*
// @version        0.0.2
// ==/UserScript==

(function(){
	var id = location.href.split('/').reverse()[0];
	var countURL = "http://mikunopop.info/count/" + id;
	var style = 'margin: auto 4px; color: #cc3333';
	var showOnlyPlayed = false;    // 彡が０の時は表示させたくないなら true に。
	
	function setCount(n) {
		// check
		if( n == 0 && showOnlyPlayed == true )
			return;
		
		// span
		var str = "彡" + n;
		var span = document.createElement("span");
		span.setAttribute("style", style);
		span.innerHTML = str;
		
		// set
		var article = document.getElementById("video_article");
		document.getElementById("video_title").insertBefore(span, article);
	}
	
	GM_xmlhttpRequest({
		method: "GET",
		url: countURL,
		onload: function(xhr) {
			setCount(xhr.responseText);
		}
	});
})();