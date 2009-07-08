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
use JSON::Syck;
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

sub handler : method {    ## no critic
	my ($class, $r) = @_;
	$r = Apache2::Request->new($r);

	my $id = $r->param('id');
	$id =~ s{^.+/((sm|nm)\d+)$}{$1};    # URL だったら削る

	if( $id eq '' ){
		$id = $r->path_info;
		$id =~ s{^/+}{}o;
	}

	my $stash = {};
	$stash->{id} = $id;

	my $info_url = sprintf "http://ext.nicovideo.jp/api/getthumbinfo/%s", $id;

	if( $id and my $content = get( $info_url ) ){
		$stash->{has_info} = 1;
		
		my $handler = {};
		$handler->{'/nicovideo_thumb_response/thumb'} = sub {
			my ($tree, $elem) = @_;
			
			for my $item( $elem->children ){
				# get all
				my @key = qw(title description thumbnail_url first_retrieve length view_counter comment_num mylist_counter watch_url);
				
				for my $key( @key ){
					if( $item->name eq $key ){
						$stash->{$key} = $item->trimmed_text;
					}
				}
				
				# tags
				if( $item->name eq 'tags' and $item->att('domain') eq 'jp' ){
					for my $t( $item->children ){
						$stash->{tag} ||= [];
						push @{ $stash->{tag} }, $t->trimmed_text;
					}
				}
			}
		};
		
		# parse
		my $twig = XML::Twig->new( TwigHandlers => $handler );
		eval { $twig->parse( $content ) };

		# pname
		if( my @pname = &get_pnames( @{ $stash->{tag} } ) ){
			$stash->{pnames} = [ @pname ];
			$stash->{pname} = join ' ', @pname;
		}
		else{
			$stash->{pname} = "Ｐ名/?";
		}
		
		# first_retrieve
		my $f = DateTime::Format::W3CDTF->new;
		$stash->{first_retrieve} = $f->parse_datetime( $stash->{first_retrieve} );
		
		# マイリス率
		$stash->{mylist_percent} = sprintf "%.2f", $stash->{mylist_counter} / $stash->{view_counter} * 100;
		
		# ミクノ度をゲット
		my $mikuno_url = sprintf "http://mikunopop.info/count/%s", $id;
		if( my $content = get( $mikuno_url ) ){
			if( my $json = JSON::Syck::Load( $content ) ){
				if( defined $json->{count} and $json->{count} ne '' ){
					$stash->{count} = $json->{count};
				}
				else{
					$stash->{count} = '?';
				}
			}
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
	my @name;
	for my $tag(@_){
		if( $tag =~ /(P|Ｐ)$/io ){
			push @name, $tag;
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
];

}

1;

__END__

