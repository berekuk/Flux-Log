#!/usr/bin/perl

use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;
use Test::Fatal;

use lib 'lib';

use IPC::System::Simple;
use autodie qw(:all);

use Flux::Log;
use Flux::Log::In;

sub setup :Test(setup) {
    system("rm -rf tfiles");
    system("mkdir tfiles");
}


sub reading :Test(4) {
    system("echo aaa >>tfiles/log");
    system("echo bbb >>tfiles/log");
    system("echo ccc >>tfiles/log");

    my $storage = Flux::Log->new("tfiles/log");

    my $stream = $storage->in({ pos => "tfiles/pos" });
    is($stream->read, "aaa\n");
    $stream->commit;

    system("mv tfiles/log tfiles/log.1");
    system("echo ddd >>tfiles/log");
    system("echo eee >>tfiles/log");
    system("echo fff >>tfiles/log");

    $stream = $storage->in({ pos => "tfiles/pos" });
    is($stream->read, "bbb\n");
    is($stream->read, "ccc\n");
    is($stream->read, "ddd\n");
    $stream->commit;
}


sub reading_without_commit :Test(2) {
    system("echo eee >>tfiles/log");
    system("echo fff >>tfiles/log");

    my $storage = Flux::Log->new("tfiles/log");
    my $stream = $storage->in({ pos => "tfiles/pos" });
    is($stream->read, "eee\n");
    $stream = $storage->in({ pos => "tfiles/pos" });
    is($stream->read, "eee\n");
}


sub commit :Test(2) {
    my $out = Flux::Log->new("tfiles/out");
    is exception { $out->commit }, undef, 'commit of an log';
    ok(! -e "tfiles/out", "empty commit does not create a log");
}


sub by_name :Test(7) {
    system("echo ".($_ x 3)." >>tfiles/log") for 'd'..'g';

    my $storage = Flux::Log->new("tfiles/log");

    my $first = $storage->in('first');
    is($first->read, "ddd\n");
    is($first->read, "eee\n");
    $first->commit;
    my $second = $storage->in('second');
    is($second->read, "ddd\n");
    $second->commit;
    $first = $storage->in('first');
    is($first->read, "fff\n");
    $first->commit;
    is($first->read, "ggg\n");
    $first = $storage->in('first');
    is($first->read, "ggg\n");
    $first = $storage->in('first');
    is($first->read, "ggg\n");
}


sub clients :Test(3) {
    system("echo ".($_ x 3)." >>tfiles/log") for 'd'..'g';

    my $storage = Flux::Log->new("tfiles/log");

    is_deeply([ $storage->client_names ], [], 'initially there are no clients');

    my $in = $storage->in('xxx');
    undef $in;
    is_deeply([ $storage->client_names ], [], "uncommited input stream don't create posfile and so don't register itself in storage");

    $in = $storage->in('xxx');
    $in->commit;
    $in = $storage->in('yyy');
    $in->read;
    $in->commit;
    is_deeply([ $storage->client_names ], ['xxx', 'yyy'], "client_names returns all clients");
}
__PACKAGE__->new->runtests;


__END__
1) create stream

Stream::Log::In->new({
    LogFile => "/var/log/file",
    PosFile => "/var/log/file.pos",
});
# + one call
# + unrotate options
# - named log
# - named pos

2) create stream from storage
Stream::Log->new("/var/log/file")->stream(Stream::Log::Cursor->new("/var/log/file.pos"));
# or:
storage("file")->stream(Stream::Log::Cursor->new("/var/log/file.pos"));
# or:
storage("file")->stream(cursor("file.pos"))
# or:
stream("file.pos")

(in catalog:
# storage.d/file:
Stream::Log->new("/var/log/file");
# cursor.d/file.pos:
Stream::Log::Cursor->new("/var/log/file.pos");

# + can be really short
# + catalog names
# - no unrotate options
# - many different files
# - not so easy for unrotate users
