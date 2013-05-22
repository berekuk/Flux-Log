package Flux::Log;

# ABSTRACT: storage implemented as log.

=head1 DESCRIPTION

This class is similar to L<Flux::File>, but designed to work with logs (files which can rotate sometimes).

It supports safe writes to rotating logs, i.e. it will automatically switch to the new file instead of writing to C<foo.log.1>.

=cut

use Moo;
extends 'Flux::File';

#with 'Flux::Storage::Role::ClientList';

use Type::Params qw(validate);
use Types::Standard qw(HashRef);

use Digest::MD5 qw(md5_hex);

use Flux::Log::In;
use Scalar::Util qw(blessed reftype);
use Carp;

has '+reopen' => (
    default => sub { 1 },
);

sub description {
    my $self = shift;
    return "log: ".$self->file;
}

=head1 METHODS

=over

=item B<in($unrotate_params)>

Construct input stream from a client name or an L<Flux::Log::Cursor> object.

C<$unrotate_params> can contain more unrotate options.

=cut
sub in {
    my $self = shift;
    my ($unrotate_params) = validate(\@_, HashRef);
    return Flux::Log::In->new({ log => $self->file, unrotate => $unrotate_params });
}

=back

=cut

1;
