use strict;
use warnings;
use utf8;

use Test::More;

use File::Spec;
use lib File::Spec->catfile('t', 'lib');
use t::Util;

run_on_database {
    my $row = db->insert_and_fetch_row(author => { name => 'MOZNION' });
    ok defined $row, 'row is defined.';
    ok $row->is_new, 'new row.';

    is_deeply $row->get_columns, {
        id              => $row->id,
        name            => 'MOZNION',
        message         => 'hello',
        inflate_message => 'hello',
        deflate_message => 'hello',
    }, 'Data is valid.';
};

done_testing();
