package Flux::Log::Types;

use Type::Library
    -base,
    -declare => qw( ClientName );
use Type::Utils;
use Types::Standard -types;

declare ClientName,
    as Str,
    where { /^\w+$/ };

1;
