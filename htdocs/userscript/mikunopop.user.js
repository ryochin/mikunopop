// ==UserScript==
// @name           Mikunopop Tools
// @namespace      http://mikunopop.info/
// @description    Mikunopop Utility Tools
// @include        http://www.nicovideo.jp/watch/*
// @include        http://www.nicovideo.jp/my/mylist*
// @include        http://jbbs.livedoor.jp/bbs/read.cgi/internet/2353/*
// @include        http://jbbs.livedoor.jp/internet/2353/*
// @require        http://ajax.googleapis.com/ajax/libs/jquery/1.7/jquery.min.js
// @version        0.0.4
// ==/UserScript==

(function(){
	if( location.href.match(/\/watch\/(sm|nm|so)/) ){
		var id = location.href.split('/').reverse()[0];
		var countURL = "http://mikunopop.info/count/" + id;
		var style = 'margin: auto 4px; color: #cc3333';    // 表示スタイル
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
		
		// main
		GM_xmlhttpRequest({
			method: "GET",
			url: countURL,
			onload: function(xhr) {
				setCount(xhr.responseText);
			}
		});
	}
	else if( location.href.match(/\/my\/mylist/) ){
		// get list
		var jsonURL = "http://mikunopop.info/play/count.json";
		var count = {};
		function getCount (id) {
			var n = count[id];
			return n == null ? 0 : n;
		}
		
		// maint
		GM_xmlhttpRequest({
			method: "GET",
			url: jsonURL,
			onload: function(xhr) {
				count = eval("(" + xhr.responseText + ")");
				
				// mylist
				(function () {
					$('.mylistVideo').each( function () {
						// check flag
						var dl = $(this).children("dl");
						if( dl.hasClass('count-done') )
							return true;
						
						// get id
						var link = $(this).children("h4").children("a");
						var id = link.attr('href').replace(/^\/watch\//, "");
						
						// set
						$('<dt>')
							.text("彡:")
							.appendTo( dl );
						$('<dd>')
							.text( getCount( id ) )
							.appendTo( dl );
						
						// add flag
						dl.addClass('count-done');
					} );
					
					setTimeout( arguments.callee, 3000 );
				})();
			}
		});
	}
	else if( location.href.match(/^https?\:\/\/jbbs\.livedoor\.jp\//) ){
		// bbs autolink
		$('dd').each( function () {
			var s = $(this).html();
			s = s.replace(/((sm|nm)[0-9]+)/g, '<a href="http://www.nicovideo.jp/watch/$1" target="_blank">$1</a>');
			s = s.replace(/(lv[0-9]+)/g, '<a href="http://live.nicovideo.jp/watch/$1" target="_blank">$1</a>');
			$(this).html(s);
		});
	}
})();
