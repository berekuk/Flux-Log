package Flux::Log;

# ABSTRACT: storage implemented as log.

=head1 DESCRIPTION

This class is similar to L<Flux::File>, but designed to work with logs (files which can rotate sometimes).

It supports safe writes to rotating logs, i.e. it will automatically switch to the new file instead of writing to C<foo.log.1>.

=cut

use Moo;
extends 'Flux::File';
with 'Flux::Storage::Role::ClientList';

use Type::Params qw(validate);
use Types::Standard qw(Str Dict HashRef);

use File::Basename qw(basename);

use Flux::Log::In;

has '+reopen' => (
    default => sub { 1 },
);

sub description {
    my $self = shift;
    return "log: ".$self->file;
}

has 'client_dir' => (
    is => 'lazy',
    isa => Str,
    default => sub {
        my $self = shift;
        my $dir = $self->file.".pos";
        unless (-d $dir) {
            mkdir $dir or die "mkdir failed: $!";
        }
        return $dir;
    },
);

=head1 METHODS

=over

=item B<in($client_name)>

=item B<in({ pos => $posfile })>

Construct input stream from a client name or a posfile name.

=cut
sub in {
    my $self = shift;
    my ($client_or_params) = validate(\@_, Str | Dict[pos => Str]);

    if (ref $client_or_params) {
        return Flux::Log::In->new({
            log => $self->file,
            unrotate => $client_or_params,
        });

    }
    else {
        return Flux::Log::In->new({
            log => $self->file,
            unrotate => {
                pos => $self->client_dir."/".$client_or_params
            }
        });
    }
}

sub client_names {
    my $self = shift;
    my @files = glob $self->client_dir.'/*';
    return map { basename $_ } @files;
}

=back

=cut

1;
