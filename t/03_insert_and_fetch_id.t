use strict;
use warnings;
use utf8;

use Test::More;

use File::Spec;
use lib File::Spec->catfile('t', 'lib');
use t::Util;

run_on_database {
    my $id = db->insert_and_fetch_id(author => { name => 'MOZNION' });
    ok defined $id, 'id is defined.';

    my $row = db->select(author => { id => $id }, { limit => 1 })->first;
    is_deeply $row->get_columns, {
        id              => $id,
        name            => 'MOZNION',
        message         => 'hello',
        inflate_message => 'hello',
        deflate_message => 'hello',
    }, 'Data is valid.';
};

done_testing();
