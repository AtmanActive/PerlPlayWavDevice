use strict;
use FindBin qw($RealBin);
use Win32::Sound;
use Audio::Wav;

my $verbose_wav_details = 0;

if
(
	( ( $ARGV[0] eq '-h' ) || ( $ARGV[0] eq '--help' ) || ( $ARGV[0] eq '/?' ) )
	||
	( ( ! exists ( $ARGV[0] ) ) || ( ! defined ( $ARGV[0] ) ) || ( ! length ( $ARGV[0] ) ) )
)
{
	print "\n";
	print "Sound file name or path as first argument\n";
	print "Optional output device partial name or number as second argument\n";
	print "-l, --list to list available devices\n";
	print "-i, --info as third argument to show wav file properties\n";
	print "-h, --help, /? for this info\n";
	print "\n";
	exit 0;
}

if ( ( $ARGV[0] eq '-l' ) || ( $ARGV[0] eq '--list' ) )
{
	print "List of available sound devices:\n";
	my $device_tree_href = enumerate_devices();
	foreach my $device ( sort ( keys ( %{ $device_tree_href } ) ) )
	{
		print "$device" . ": " . $device_tree_href->{ $device }->{ name } . "\n";
	}
	exit 0;
}

if ( ( $ARGV[2] eq '-i' ) || ( $ARGV[2] eq '--info' ) )
{
	$verbose_wav_details = 1;
}



my $device_tree_href = enumerate_devices();
my ( $is_match, $match_to_number, $match_to_name ) = match_the_device_by_partial_name( $ARGV[1], $device_tree_href );
play_the_sound( $ARGV[0], $is_match, $match_to_number, $match_to_name );

exit 0;



sub enumerate_devices
{
	
	# WAVE_MAPPER
	
	my %device_tree;
	
	my @devices = Win32::Sound::Devices();
	
	foreach my $device ( @devices )
	{
		if ( $device =~ m/^WAVEOUT/ )
		{
			my %info = Win32::Sound::DeviceInfo( $device );
			$device_tree{ $device } = \%info;
		}
	}
	
	return \%device_tree;
	
} ### END sub enumerate_devices



sub match_the_device_by_partial_name
{
	
	my ( $name, $device_tree_href ) = @_;
	
	my $is_match;
	my $match_to_number = 0; # USE DEFAULT AUDIO INTERFACE
	my $match_to_name;
	
	if ( ( defined ( $name ) ) && ( length ( $name ) ) )
	{
		
		if ( $name =~ m/^\d+$/ )
		{
			
			if ( $name == 0 )
			{
				return ( $is_match, $match_to_number, $match_to_name );
			}
			elsif ( ( keys ( %{ $device_tree_href } ) ) < $name )
			{
				return ( $is_match, $match_to_number, $match_to_name );
			}
			else
			{
				foreach my $device ( keys ( %{ $device_tree_href } ) )
				{
					if ( $device =~ m/$name$/ )
					{
						$is_match = 1;
						$match_to_number = $name;
						$match_to_name = $device_tree_href->{ $device }->{ name };
					}
				}
			}
		}
		else
		{
			foreach my $device ( keys ( %{ $device_tree_href } ) )
			{
				if ( $device_tree_href->{ $device }->{ name } =~ m/^$name/ )
				{
					$is_match = 1;
					$match_to_number = $device; $match_to_number =~ s/[^0-9]+//;
					$match_to_name = $device_tree_href->{ $device }->{ name };
				}
			}
		}
		
	} # END if ( ( defined ( $name ) ) || ( length ( $name ) ) )
	
	return ( $is_match, $match_to_number, $match_to_name );
	
} ### END sub match_the_device_by_partial_name



sub play_the_sound
{
	
	my ( $file_path, $is_match, $match_to_number, $match_to_name ) = @_;
	
	my $full_file_path;
	my $full_file_size;
	
	if ( ( $file_path =~ m/\// ) || ( $file_path =~ m/\\/ ) )
	{
		$full_file_path = $file_path;
	}
	else
	{
		$full_file_path = $RealBin . "/" . $file_path;
	}
	
	if ( -e $full_file_path )
	{
		$full_file_size = -s _;
	}
	else
	{
		print "File not found: " . $full_file_path . "\n";
		exit 1;
	}
	
	if ( $verbose_wav_details )
	{
		print "\n";
		print "About to scan: $full_file_path [$full_file_size bytes]\n";
	}
	
	my ( $hz, $bits, $channels ) = Win32::Sound::Format( $full_file_path );
	my $read = Audio::Wav->read( $full_file_path );
	my $details = $read->details();
	my $wav_data_start = $details->{ 'data_start' };
	my $wav_data_length = $details->{ 'data_length' };
	
	my $channels_verbose = "";
	if ( $channels == 1 )
	{
		$channels_verbose = "mono";
	}
	elsif ( $channels == 2 )
	{
		$channels_verbose = "stereo";
	}
	elsif ( $channels == 6 )
	{
		$channels_verbose = "5.1";
	}
	
	if ( $verbose_wav_details )
	{
		print "About to play $bits bits, $hz Hz, $channels_verbose";
		if ( $is_match )
		{
			print " to device $match_to_name";
		}
		print "\n";
	}
	
	my $wav_file = Audio::Wav->read( $full_file_path );
	my $details = $wav_file->details();
	
	my $SOUND = new Win32::Sound::WaveOut( $hz, $bits, $channels );
	$SOUND->CloseDevice();
	$SOUND->OpenDevice( $match_to_number );
	
	open( FH, "<$full_file_path" );
	seek FH, $wav_data_start, 0;
	read FH, $wav_file, $wav_data_length;
	close( FH );
	
	$SOUND->Load( $wav_file );
	$SOUND->Write();
	1 until $SOUND->Status();  # wait for completion
	$SOUND->Unload();
	$SOUND->CloseDevice();
	
	if ( $verbose_wav_details )
	{
		print "Complete\n";
	}
	
} ### END sub play_the_sound
 
