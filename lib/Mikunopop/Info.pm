# 
# /info/sm7654321

package Mikunopop::Info;

use strict;
use 5.008;
use vars qw($VERSION);
use Data::Dumper;
use Path::Class qw(file);
use List::Util qw(first);
use List::MoreUtils qw(uniq);
use DateTime;
use DateTime::Format::W3CDTF;
use JSON::Syck ();
use LWP::Simple qw(get);
use XML::Twig;

use Apache2::Const -compile => qw(:common);
use Apache2::RequestRec ();
use Apache2::Log ();
use Apache2::Request ();

use utf8;

$VERSION = '0.01';

my $base = '/web/mikunopop';
my $template_file = file( $base, "template", "info.html" )->stringify;

my $json_file = file( $base, 'htdocs/play/count.json' );
my $expire = 6 * 60 ** 2;    # 6hrs
my $last = 0;    # epoch
my $count;    # count container

sub handler : method {    ## no critic
	my ($class, $r) = @_;
	$r = Apache2::Request->new($r);

	# insert to memory
	if( time - $last > $expire ){
		$r->log_error("=> count file reloaded.");
		$count = JSON::Syck::Load( $json_file->slurp );
		$last = time;
	}

	my $id;
	if( $r->param('id') =~ m{^.+/((sm|nm)\d+)$}o ){
		# http://www.nicovideo.jp/watch/sm6626954
		$id = $1;
	}
	elsif( $r->param('id') =~ m{^(sm|nm)\d+$}o ){
		# sm6626954
		$id = $r->param('id');
	}
	elsif( $r->param('id') =~ m{^\d+$}o ){
		# 6626954
		# -> sm を補完する
		$id = sprintf "sm%d", $r->param('id');
	}
	else{
		# path_info から得る
		$id = $r->path_info;
		$id =~ s{^/+}{}o;
	}

	my $stash = {};
	$stash->{id} = $id;

	my $info_url = sprintf "http://ext.nicovideo.jp/api/getthumbinfo/%s", $id;

	if( $id and my $content = get( $info_url ) ){
		my $handler = {};
		my @tag;
		$handler->{'/nicovideo_thumb_response/thumb'} = sub {
			my ($tree, $elem) = @_;
			
			for my $item( $elem->children ){
				# get all
				my @key = qw(title description thumbnail_url first_retrieve length view_counter comment_num mylist_counter watch_url last_res_body);
				
				for my $key( @key ){
					if( $item->name eq $key ){
						$stash->{$key} = $item->trimmed_text;
					}
				}
				
				# all tag
				if( $item->name eq 'tags' and $item->att('domain') eq 'jp' ){
					for my $t( $item->children ){
						next if $t->trimmed_text eq q{音楽};
						push @tag, $t->trimmed_text;
					}
				}
			}
		};
		
		# parse
		my $twig = XML::Twig->new( TwigHandlers => $handler );
		eval { $twig->parse( $content ) };
		
		# vocaloid tag
		my @tag_vocaloid;
		my @tags = @{ &tags };
		for my $tag( @tag ){
			# first が使えない
			my $flag = 0;
			for my $t( @tags ){
				if( $tag =~ /$t/i ){
					push @tag_vocaloid, $tag;
				}
			}
		}
		
		# set
		$stash->{tag} = [ @tag ];
		$stash->{tag_vocaloid} = [ @tag_vocaloid ];
		
		if( defined $stash->{title} and $stash->{title} ne '' ){
			$stash->{has_info} = 1;
			
			# pname
			if( my @pname = &get_pnames( @{ $stash->{tag} } ) ){
				$stash->{pnames} = [ @pname ];
				$stash->{pname} = join ' ', @pname;
			}
			else{
				$stash->{pname} = "Ｐ名？";
			}
			
			# first_retrieve
			my $f = DateTime::Format::W3CDTF->new;
			$stash->{first_retrieve} = eval { $f->parse_datetime( $stash->{first_retrieve} ) };
			
			my $tz = DateTime::TimeZone->new( name => 'local' );
			my $now = DateTime->now( time_zone => $tz );
			
			eval {
				if( $now->epoch - $stash->{first_retrieve}->epoch < 7 * 24 * 60 ** 2 ){
					$stash->{is_too_new} = 1;
				}
			};
			
			# マイリス率
			$stash->{mylist_percent} = sprintf "%.1f", $stash->{mylist_counter} / $stash->{view_counter} * 100;
			
			# ミクノ度
			if( defined $count->{$id} and $count->{$id} > 0 ){
				$stash->{count} = $count->{$id};
			}
			else{
				$stash->{count} = '0';
			}
		}
		else{
			$stash->{not_found} = 1;
		}
	}

	# out
	my $template = &create_template;

	$r->content_type("text/html; charset=UTF-8");
	$template->process( $template_file, $stash, $r, binmode => ':utf8' )
		or die ;

	return Apache2::Const::OK;
}

sub get_pnames {
	my @p = grep { $_ ne '' } @{ &pnames };
	my @pn = qw(MikuPOP RinPOP アニメOP ゲームOP エロゲOP 偽OP J-POP);    # NG
	
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

sub create_template {
	require Template;

	my $config = {
		INCLUDE_PATH => '.',
		ABSOLUTE => 1,
		RELATIVE => 1,
		AUTO_RESET => 1,
		ENCODING => 'utf8',    # will be passed to Encode::decode()
		PRE_CHOMP => 1,
		POST_CHOMP => 0,
		TRIM => 0,
	};

	my $tmpl_config = {
		%{ $config },
	};

	return Template->new( $tmpl_config );
}

# from tags.js
sub tags {
return ["",
#	// 一般
	"テクノ",
	"Instrumental",
	"ChipTune",

#	// 大百科より
#	// http://dic.nicovideo.jp/a/vocaloid%E9%96%A2%E9%80%A3%E3%81%AE%E3%82%BF%E3%82%B0%E4%B8%80%E8%A6%A7
	"アングーグラウンドボカロジャパン",
	"居酒屋KAITO",
	"カラオケBOX流歌",
	"キャバレー巡音",
	"クラブ鏡音",
	"ジャズクラブ初音",
	"スナック初音",
	"全部KAITO",
	"全部ミク",
	"全部リン",
	"全部レン",
	"Chiptune×VOCALOIDリンク",
	"電脳愛国婦人",
	"BAR初音",
	"BAR弱音",
	"初音フォークジャンボリー",
	"初音ミク合唱団シリーズ",
	"初音ミクの合唱",
	"初音ミクの弾き語り",
	"初音洋楽シリーズ",
	"パブMEIKO",
	"プログレミク",
	"VOCAJAZZ",
	"VOCALOIDアカペラ曲",
	"VOCALOIDヴィジュ系カバー曲",
	"VOCALOID合唱団",
	"VOCALOID口笛",
	"VOCALOIDミュージカル",
	"VOCALOID民族調曲",
	"ボカロ演歌",
	"ボカロクラシカ",
	"VOCAROCK",
	"VOCASKA",
	"ボカロ童謡",
	"ボカロメタル",
	"ボカロメタル殿堂入り",
	"ボカロラップ",
	"ミクゲイザー",
	"ミクトランス",
	"ミクトロニカ",
	"ミクノ",
	"ミクノポップ",
	"MikuHouse",
	"ミクHR/HM",
	"ミク☆バラード",
	"ミクパンク",
	"ミクビエント",
	"MikuPOP",
	"ミクボッサ",
	"巡音洋楽シリーズ",
	"ボカノバ",
	"ミクメタル",
	"ミクラシック",
	"ミクろっく",
	"ミックンベース",
	"MEIKO無双",
	
#	// ミク
	"みんなのミクうた",
	"初音ミク処女作",
	"切ないミクうた",
	"爽やかなミクうた",
	"クールなミクうた",
	"元気が出るミクうた",
	"ピアノミク",
	"隠れたミク名曲",
	"ミクちゃんといっしょ",
	"かわいいミクうた",
	"ききいるミクうた",
	"ミクのクリスマス曲",
	"ミクという音源を使ってみた",
	"初音ミク迷曲リンク",
	"大人のミク曲",
	"素朴なミクうた",
	"ごきげんミクさん",
	"なごみく",
	"アコギミク",
	"元気が減るミクうた",
	"全部初音ミク",
	"初音ミクでクラシック",
	"初音ミクの合唱",
	"エロかわいいミクうた",
	"ミクロック",

#	// リン
	"隠れたリン名曲",
	"鏡音リン迷曲リンク",
	"鏡音リン名曲リンク",
	"みんなのリンうた",
	"切ないリンうた",
	"元気が出るリンうた",
	"爽やかなリンうた",
	"かわいいリンうた",
	"クールなリンうた",
	"恋するリンうた",
	"ききいるリンうた",
	"ホットなリンうた",
	"素朴なリンうた",
	"元気の出るリンうた",

#	// ルカ
	"巡音ルカ名曲リンク",
	"ききいるルカうた",
	"クールなルカうた",
	"切ないルカうた",
	"隠れたルカ名曲",
	"爽やかなルカうた",
	"ピアノルカ",
	"みんなのルカうた",
	"やさしいルカうた",
	"かわいいルカうた",

#	// GUMI
	"かわいいGUMIうた",
	"ききいるGUMIうた",

#	// 特別
	"時田トリビュート",
];
}

# from pnames.js
sub pnames {
return ["",
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
	"m\@rk",
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
	"shin",
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
	"電PアルPカ",
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
	"グラウル",
	"yuukiss",
	"L*aura",
	"tatmos",
	"glim",
	"ねこぼーろ",
	"geppei-taro",
	'T@KC',
	"salome",
	"おなつ",
	"サイコパズル",
	"nyan_nyan",
	"hiropon_5th",
];
}

1;

__END__

