#  ----------------------------------------------------------------------------
#  "THE BEER-WARE LICENSE":
#  <ivan@sanchezortega.es> wrote this file. As long as you retain this notice you
#  can do whatever you want with this stuff. If we meet some day, and you think
#  this stuff is worth it, you can buy me a beer in return.
#  ----------------------------------------------------------------------------
#
# Bot para responder a quien me pregunta ¿Cuánto tarda mi autobús?
#
# Pide los datos a www.cuantotardamiautobus.es/madrid/tiempos.php, que a su vez los pide a la EMT de Madrid
#
# Cómo ejecutar:
# bin/ttytter.pl -keyf=.tardabus -exts=ttytter/tardabus.pl -rc=/dev/null -dostream=1 -ssl=1
#
# Cuenta: @TardaBus tardabus@sanchezortega.es


use Data::Dumper qw{Dumper};



# Preparamos algunas regexps que vamos a usar mucho
my $regexp_parada = qr/parada ([0-9]+)/;



$handle = sub {
	our $verbose;
	my $tweet = shift;

	my $text = $tweet->{'text'};


	# Me han mandado un comando de tiempos de espera en una parada
	if ($text =~ m/$regexp_parada/ig)
	{
		my $parada = $1;

		# TTYtter's grabjson and backtick system needs a few backslashes to escape the []'s
		my $url = "http://www.cuantotardamiautobus.es/madrid/tiempos.php?ids_parada\\\\[0\\\\]=" . $parada;
		print $stdout "-- Procesando tiempos para parada $parada - $url\n" if ($verbose);
		my $r = &grabjson($url,0,1);

		print Dumper($r) if $superverbose;
# 		print Dumper($parada);
# 		print Dumper($tweet->{'user'}->{'screen_name'});
# 		print Dumper($tweet->{'id_str'});

		my $string = "@" . $tweet->{'user'}->{'screen_name'} . "\n";

		while (my ($index, $bus) = each $r)
		{
# 			print Dumper($bus);
			my $minutossegundos;
			if ($bus->{'segundos'} == '999999')
				{ $minutossegundos = 'más de 20 minutos'; }
			else
				{ $minutossegundos = int($bus->{'segundos'} / 60) . ":" . $bus->{'segundos'} % 60; }

			if (length($string) < 140)
			{
				$string .= "Bus " . $bus->{'linea'} . " en $minutossegundos\n";
			}
			else
			{
				print $stdout "-- El bus de línea " . $bus->{'linea'} . " no cabe en la respuesta\n" if ($verbose);
			}

		}

		print $stdout "-- La respuesta es: $string\n" if ($verbose);
		&updatest(&descape($string), 0, $tweet->{'id_str'});
	}



	&defaulthandle($tweet);
	return 1;
};


