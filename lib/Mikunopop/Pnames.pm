package Mikunopop::Pnames;

use strict;
use 5.008;
use List::Util qw(first);
use List::MoreUtils qw(uniq);

use utf8;

# from pnames.js
our $Pnames = [
	"OSTER_project",
	"ika",
	"kz",
	"ryo",
	"KEI",
	"masquer",
	"ボカロ互助会",
	"AEGIS",
	"andromeca",
	"awk",
	"Azell",
	"cokesi",
	"DARS",
	"DixieFlatline",
	"GonGoss",
	"G-Fac.",
	"halyosy",
	"haruna808",
	"HMOとかの中の人",
	"IGASIO",
	"inokix",
	"iroha(sasaki)",
	"Karimono",
	"kashiwagi氏",
	"kotaro",
	"kous",
	"KuKuDoDo",
	"LOLI.COM",
	"MAX_VEGETABLE",
	"Masuda_K",
	"MineK",
	"No.D",
	"OPA",
	"otetsu",
	"Otomania",
	"AETA(イータ)",
	"cosMo(暴走P)",
	"doriko",
	"PENGUINS_PROJECT",
	"Re:nG",
	"ShakeSphere",
	"samfree",
	"Shibayan",
	"SHIKI",
	"snowy*",
	"takotakoagare交響楽団",
	"Tatsh",
	"Treow(逆衝動P)",
	"Tripshots",
	"TuKuRu",
	"UPNUSY",
	"VIVO",
	"wintermute",
	"X-Plorez",
	"YAMADA-SUN",
	"yukiwo",
	"カリスマブレイクに定評のあるうP主",
	"[TEST]",
	"杏あめ",
	"Dog tails",
	"歌和サクラ",
	"裸時",
	"邂逅の中の人",
	"喜兵衛",
	"Φ串Φ",
	"このり",
	"小林オニキス",
	"田中和夫",
	"ちゃぁ",
	"チョコパ幻聴P(パティシエ)",
	"ティッシュ姫",
	"テンネン",
	"とおくできこえるデンシオン",
	"トマ豆腐",
	"ナツカゼP(Tastle)",
	"肉骸骨",
	"伴長",
	"森井ケンシロウ",
	"山本似之",
	"山本ニュー",
	"林檎",
	"レインロード",
	"164",
	"∀studio",
	"uunnie",
	"おいも",
	"madamxx",
	"mijinko3",
	"DECO*27",
	"さかきょ",
	"ちーむ炙りトロ丼",
	"GlassOnion",
	"bothneco",
	"yu",
	'm@rk',
	"shin",
	"kame",
	"たすどろ",
	"nof",
	"YYMIKUYY",
	"Zekky",
	"HironoLin",
	"スタジオいるかのゆ",
	"PEG",
	"meam",
	"ＸＧｗｏｒｋｓ",
	"まはい",
	"nankyoku",
	"ナヅキ",
	"Nen-Sho-K",
	"Sat4",
	"suzy",
	"ぽぴー",
	"名鉄2000系",
	"Noya",
	"さね",
	"きらら",
	"ごんぱち",
	"えどみはる",
	"analgesic_agents",
	"takuyabrian",
	"kuma",
	"tomo",
	"nabe_nabe",
	"桃茄子",
	"river",
	"れい・ぼーん",
	"クリアP(YS)",
	"usuki",
	"OperaGhost",
	"instinctive",
	"銀色の人",
	"pan",
	"龍徹",
	"AVTechNO",
	"●テラピコス",
	"びんご",
	"ゆよゆっぺ",
	"くっじー",
	"ミナグ",
	"LIQ",
	"まゆたま",
	"チームほしくず",
	"WEB-MIX",
	"ukey",
	"Phantasma",
	"Kossy",
	"mintiack",
	"Yoshihi",
	"ぱきら",
	"すたじおEKO＆GP1",
	"Neri_McMinn",
	"ぼか主",
	"Harmonia",
	"Rock",
	"TACHE",
	"cmmz",
	"BIRUGE",
	"m_yus",
	"たけchan",
	"CleanTears",
	"Lue",
	"FuMay",
	"SHUN",
	"関西芋ぱん伝",
	"静野",
	"どぶウサギ",
	"bestgt",
	"IGASI○",
	"メロネード(仮)",
	"ICEproject",
	"ぱんつのうた製作委員会",
	"さいはね",
	"MikSolodyne-ts",
	"Yossy",
	"あつぞうくん",
	"タイスケ",
	"P∴Rhythmatiq",
	"ぎん",
	"Rin",
	"hapi⇒",
	"microgroover",
	"Studio_IIG",
	"cenozoic",
	"miumix",
	"U-ji",
	"aquascape",
	"deathpiyo",
	"Fraidy-fraidy",
	"いのりば",
	"DATEKEN",
	"霧島",
	"bobuun",
	"ぎんなこ",
	"ceres",
	"ノエル",
	"すけ",
	"chickenthe",
	"かとちゃ",
	"BiRD(s)",
	"mousya",
	"d3ud3u",
	"D-3110",
	"やしきん",
	"LazyRage",
	"YHK",
	"杏あめ（匿名希望の東京都在住）",
	"ちっちー",
	"NANIKA_SHEILA",
	"Team_Frontier",
	"unluck",
	"DjA.Q.",
	"D-Splash",
	"舞人",
	"SAT",
	"はんにゃG",
	"ぴろち。",
	"よ",
	"MRtB",
	"邪界ニドヘグ",
	"えるのわ",
	"白井しゅそ",
	"musashi-k",
	"774Muzik",
	"とーい",
	"GuitarGirlsAddiction",
	"ypl",
	"Masaki",
	"yuxuki",
	"れお",
	"Dengaku",
	"une",
	"Rin（ぎん）",
	"クリーム市長",
	"Runo",
	"en",
	"ノーベル",
	"Momotalow",
	"電PアルPカ",    # デンパアルパカ
	"tms",
	"すえぞぉ",
	"ヒゲドライバー",
	"k2",
	"チータン",
	"わたしょ",
	"36g",
	"salome",
	"ぱたや",
	"P*Light",
	"放任主義",
	"21世紀核戦争",
	"Stremanic",
	"HIDAKA",
	"KAZU-k",
	"effe",
	"TEMB",
	"鼎沙耶",
	"vanzz",
	"グラウル",
	"yuukiss",
	"L*aura",
	"tatmos",
	"glim",
	"ねこぼーろ",
	"geppei-taro",
	'T@KC',
	"おなつ",
	"サイコパズル",
	"nyan_nyan",
	"hiropon_5th",
	"stereoberry",
	"Seventh_Heaven",
	"sh_m",
	"ut21",
	"ziki_7",
	"でっち",
	"立秋",
	"とんかつ",
	"だいすけ",
	"ボッチ",
	"arata",
	"えこ。",
	"o.ken",
	"Aether_Eru",
	"卯月めい",
	"黒サムネ",
	"PtPd",
	"ピロシキ＋",
	"今日犬",
	"ma10a",
	"Kyanite",
	"LC:AZE",
	"baker",
	"kiichi",
	"North-",
	"とち-music_box",
	"temporu",
	"すこっぷ",
	"Dong",
	"DONTNORA",
	"田村ヒロ",
	"Hal",
	"堤逢叶",
	"sampling_INO",
	"akiwo",
	"sorahayah",
	"ふぁい＆ふぁい",
	"deutsch242",
	"モケケ",
	'm@rk',
	"aoid",
	"Miku-flo",
	"オクトロ",
	"異界堂Works",
	"SH100000",
	"白熱灯",
	"IllMia",
	"k-sk",
	"CAINE",
	"uvox",
	"muhmue",
	'G9Fried@GRM',
	"Calla_Soiled",
	"大納僧",
	"マッペ",
	"ええすゆう",
	"たいようのおなら",
	"マッコイ",
	"Aether_eru",
	"いとうぺんこ",
	"不確定名：producer（1）",
	"pull",
	"ＨＩＤＡＫＡ",
	"LOSTMAN",
	"Aoi",
	"まちざわ",
	"ゆいほ",
	"くぼ牧",
	"Chiquewa",
	"ddh",
	"dol",
	"sweet-kit",
	"konkon",
	"REDALiCE",
	"koja",
	"五条城",
	"Noazi",
	"pandra",
	"lazyrage",
	"マサシ",
	"roki",
	"mikuru396",
	"embryo4713",
	"球（スフィア）",
	"ウインディー",
	"Dr.Willy",
	"CALFO",
	"ミニ丸",
	"漣也",
	"きー",
	"usob",
	"TOOKATO",
	"terry10x12th",
	"ds_8",
	"ぽんたろう",
	"su~mi",
	"njn",
	'K@Z',
	"kj3",
	"T26",
	"Su",
	"めいこっち",
	"DragonFlavor",
	"えろ豆先生",
	"ミロ",
	"ミロ(PV作者)",
	"meola",
	"chan×co",
	"Dog_tails",
	"djA.Q.",
	"Dtk",
	"sat1080",
	"ych",
	"cannabanoid",
	"神戸のシュナイダー",
	"Wissy",
	"ひろ☆りん",
	"k.TAMAYAN",
	"こっそりP★ReON",
	"私と友人たち",
	"こめる",
	"多摩川タマコ",
	"key-yan69",
	"ハチ",
	"nf",
	"む～ちょ",
	"tom",
	"ReON",
	"mononofrog",
	"tac_",
	"スズナリ",
	"てるるての人",
	"taat",
	"dede",
	"msimo",
	"Ho-Ne",
	"Spiltmilk",
	"takunama",
	"life636_",
	"A_Luyuvi",
	"vicki_rhodes",
	"function",
	"Nogirroute",
	"s*g*",
	"animebrass",
	"monoeye",
	"黄花",
	"ミューム(うぇ～い♪P)",
	"ピアナ",
	"阿刀田阿子",
	"pemopemo",
	"hmtk",
	"snowkuouks",
	"yuki",
	"sixty-six-eleven",
	"mondaiji",
	"inaphon",
	"dsz",
	"DS-10",
	"AquesTone",
	"dohety",
	"aki",
	"ARuFa",
	"ke-ji",
	"keitarou",
	"2M",
	"hosaka1988",
	"NES",
	"ちよこ_T",
	"CYTOKINE",
	"bicco",
	"星空かける",
	"NORXM",
	"くぇ",
	"caferi",
	"minami",
	"Jotaka_NW",
	"EM",
	"BONU",
	"ふらーぐ",
	"Opti-",
	"toridori",
	"Akia",
	"トーマ",
	"BBれもん",
	"アドム",
	"iROH",
	"Taishi",
	"NAV",
	"ももか",
	"ギザギザネコ",
	"nick",
	"まりっちゃ",
	"崎崎崎",
	"hyton",
	"koh-hey",
	"花一",
	"さばぴん",
	"こみかん",
	"根黒ノミ子",
	"白の無地",
	"雛國ミキ",
	"クロヤマ",
	"mizole",
	"digitalchoco",
	"maru",
	"type74",
	"akt",
	'T@KC',
	"edima2000",
	"マスターvation",
	"ぺぺるる",
	"藤村彩家",
	"炉心先生",
	"MCI_Error",
	"athome",
	"Mi",
	"ぽき",
	"れるりり",
	"ファンド",
	'phili@music',
	"みりんぼし",
	"kiyoyan",
	"mia子",
	"vation",
	"DJシガニー・ウィーバー",
	"paraoka",
	"em_es",
	"シイサ",
	"fukuda_yuichi",
	"centrevillage",
	"ryuto",
	"Yamamaya",
	"イルカの夢X",
	"１１０７２１",
	"room335",
	"かこい",
	"ねこすけ",
	"kara_age",
	"mishiki",
	"ハウチュ",
	"kolon",
	"Kha",
	"狸穴",
	"DBP(charlie)",
	"rudder-k",
	"ヒゲ伸び太",
	"銀泡虹草",
	"iymt",
	"偉いほうの犬",
	"E-某",
	"シーサ",
	"ブルボンヌ雪村",
	"qb-ism",
	"harun",
	"909state",
	"kamno",
	"SH1000000",
	"うねりとイカサマ・ヘッド",
	"遊句",
	"山芋",
	"Y/D",
	"synthesized_flowers",
	"TECHNORCH",
	"p-mansource",
	"StingraySongs",
	"もじゃぶた",
	"マクガフィン",
	"小森マル",
	"dddaaaiii",
	"おにゅう",
	"097(オグナ)",
	"broiler",
	"式部",
	"peakedyellow",
	'M@SATOSHI',
	"Doppelman",
	"mok",
	"初心者の集い",
	"WHETHE",
	"hisaruki",
	"tms",
	"Miku-flo",
	"ショウショウ",
	"yamabushi",
	"イクアノクス",
	"cocotuki",
];

sub get_pnames {
	my @p = grep { $_ ne '' } @{ $Pnames };
	my @pn = qw(MikuPOP RinPOP アニメOP ゲームOP エロゲOP 偽OP J-POP これからもずっとbakerの嫁P 2STEP ミーム第２期OP Human_Dump お前はもう死んでいるP);    # NG
	
	my @name;
	for my $tag(@_){
		if( $tag =~ /(P|Ｐ)$/io ){
			if( not first { $tag =~ /^$_$/i } @pn ){
				push @name, $tag;
			}
		}
		elsif( first { $tag eq $_ } @p ){
			push @name, $tag;
		}
	}
	
	return @name;
}

1;

__END__

