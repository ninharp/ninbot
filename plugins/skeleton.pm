package skeleton;

use strict;
use Data::Dumper;

my $plugin_name = "skeleton";

# routine for module closing
sub DESTROY {
	my $plugin = shift;
	my $self = &main::get_Self;
    $self->log( 5, "<".$plugin_name."> Plugin Object Destroyed." );
}

# required routine for parsing
sub Handler {
	my $plugin = shift;
	my $command = shift || "";
	my $param = shift || "";
	my $self = &main::get_Self;
	my $return = "";
	$self->log( 4, "<".$plugin_name."> Plugin Object Handler entered." );
	if ($param =~ m/skeleton/) {
		$return = "Skeleton rocks";
	}
	return $return;
}

# required routine to check if file is correct
sub valid {
	return 1;
}

1;
