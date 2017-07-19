package Aniki::Handler;
use 5.014002;

use namespace::autoclean;
use Mouse;

use DBIx::Handler 0.12;

has connect_info => (
    is       => 'ro',
    required => 1,
);

has on_connect_do => (
    is => 'ro',
);

has on_disconnect_do => (
    is => 'ro',
);

has trace_query => (
    is      => 'ro',
    default => 0,
);

has trace_ignore_if => (
    is      => 'ro',
    default => sub { \&_noop },
);

has handler => (
    is      => 'rw',
    lazy    => 1,
    builder => 'connect',
    clearer => 'disconnect',
);

sub _noop {}

sub connect :method {
    my $self = shift;
    my ($dsn, $user, $pass, $attr) = @{ $self->connect_info };
    my $trace_ignore_if = $self->trace_ignore_if;
    return $self->_handler_class->new($dsn, $user, $pass, $attr, {
        on_connect_do    => $self->on_connect_do,
        on_disconnect_do => $self->on_disconnect_do,
        trace_query      => $self->trace_query,
        trace_ignore_if  => sub { $_[0]->isa('Aniki') || $_[0]->isa('Aniki::Handler') || $trace_ignore_if->(@_) },
    });
}

sub _handler_class { 'DBIx::Handler' }
sub _proxy_methods { qw/dbh trace_query_set_comment run txn_manager txn in_txn txn_scope txn_begin txn_rollback txn_commit/ }

for my $name (__PACKAGE__->_proxy_methods) {
    my $code = __PACKAGE__->_handler_class->can($name);
    __PACKAGE__->meta->add_method($name => sub {
        @_ = (shift->handler, @_);
        goto $code;
    });
}

sub DEMOLISH {
    my $self = shift;
    $self->disconnect();
}

__PACKAGE__->meta->make_immutable();
__END__

=pod

=encoding utf-8

=head1 NAME

Aniki::Handler - Database handler manager

=head1 SYNOPSIS

    # define custom database handler class
    pakcage MyApp::DB::Handler {
        use Mouse;
        extends qw/Aniki::Handler/;

        has '+connect_info' => (
            is => 'rw',
        );

        has servers => (
            is  => 'ro',
            isa => 'ArrayRef[Str]',
        );

        sub _choice { @_[int rand scalar @_] }

        around connect => sub {
            my $self = shift;
            my ($dsn, $user, $pass, $attr) = @{ $self->connect_info };
            $attr->{host} = _choice(@{ $self->servers });
            $self->connect_info([$dsn, $user, $pass, $attr]);
            return DBIx::Handler->new($dsn, $user, $pass, $attr, {
                on_connect_do    => $self->on_connect_do,
                on_disconnect_do => $self->on_disconnect_do,
            });
        };
    };

    # and use it
    package MyApp::DB {
        use Mouse;
        extends qw/Aniki::Handler/;

        __PACKAGE__->setup(
            handler => 'MyApp::DB::Handler',
        );
    }

    1;

=head1 DESCRIPTION

This is database handler manager.

=head1 METHODS

=head2 CLASS METHODS

=head3 C<new(%args) : Aniki::Handler>

Create instance of Aniki::Handler.

=head4 Arguments

=over 4

=item C<connect_info : ArrayRef>

Auguments for L<DBI>'s connect method.

=item on_connect_do : CodeRef|ArrayRef[Str]|Str
=item on_disconnect_do : CodeRef|ArrayRef[Str]|Str

Execute SQL or CodeRef when connected/disconnected.

=back

=head2 INSTANCE METHODS

=head3 C<connect() : DBIx::Handler>

Create instance of DBIx::Handler.
You can override it in your custom handler class.

=head2 ACCESSORS

=over 4

=item C<connect_info : ArrayRef>

=item C<on_connect_do : CodeRef|ArrayRef[Str]|Str>

=item C<on_disconnect_do : CodeRef|ArrayRef[Str]|Str>

=item trace_query : Bool

=item trace_ignore_if : CodeRef

=item C<dbh : DBI::db>

=item C<handler : DBIx::Handler>

=item C<txn_manager : DBIx::TransactionManager>

=back
