package Flux::Log::In;

# ABSTRACT: input stream for Flux::Log storage.

=head1 SYNOPSIS

    $in = $log_storage->in({ unrotate => { log => "/var/log/my.log", pos => "/tmp/pos" } });

    $line = $in->read; # read next line from log

    $lag = $in->lag; # get log lag in bytes

    $in->commit; # commit current position
    # or:
    $position = $in->position; # remember position
    ... # read more lines
    $in->commit($position); # commit saved position to cursor, ignoring all other lines

=head1 METHODS

=over

=cut

use Moo;
with
    'Flux::In::Role::Easy',
    'Flux::In::Role::Lag',
    'Flux::Role::Description';

use Type::Params qw(validate);
use Types::Standard qw( Int Str HashRef Object Optional );

use Log::Unrotate;

has '_unrotate_params' => (
    is => 'ro',
    isa => HashRef,
    init_arg => 'unrotate',
    required => 1,
);

has 'log' => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has '_unrotate' => (
    is => 'lazy',
    isa => Object,
    default => sub {
        my $self = shift;
        return Log::Unrotate->new({
            log => $self->log,
            %{ $self->_unrotate_params }
        });
    },
);

sub description {
    my $self = shift;

    my $current_log = $self->_unrotate->_log_file; # FIXME - incapsulation violation!
    return
        "pos: ".$self->_unrotate_params->{pos}."\n"
        ."log: $current_log";
}

sub clone {
    my $self = shift;
    return __PACKAGE__->new({ unrotate => $self->_unrotate_params });
}

sub read {
    my $self = shift;
    validate(\@_);

    return $self->_unrotate->read;
}

=item C<< position() >>

Get current position.

You can commit this stream later using this position instead of position at the moment of commit.

=cut
sub position {
    my $self = shift;
    validate(\@_);
    return $self->_unrotate->position;
}

=item C<< lag() >>

Get log lag in bytes.

=cut
sub lag {
    my $self = shift;
    validate(\@_);

    return $self->_unrotate->lag;
}

=item C<< commit() >>

=item C<< commit($position) >>

Commit position in stream's cursor.

=cut
sub commit {
    my $self = shift;
    my ($position) = validate(\@_, Optional[Int]);

    $self->_unrotate->commit($position ? $position : ());
}

=back

=head1 SEE ALSO

L<Flux::Log> - output stream for writing logs.

L<Flux::In> - role for all input streams.

L<Log::Unrotate> - module for reading rotated logs.

=cut

1;
