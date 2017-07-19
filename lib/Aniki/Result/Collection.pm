package Aniki::Result::Collection;
use 5.014002;

use namespace::autoclean;
use Mouse v2.4.5;
extends qw/Aniki::Result/;

use overload
    '@{}'    => sub { shift->rows },
    fallback => 1;

has row_datas => (
    is       => 'ro',
    required => 1,
);

has inflated_rows => (
    is      => 'ro',
    lazy    => 1,
    builder => '_inflate',
);

sub _inflate {
    my $self = shift;
    my $row_class  = $self->row_class;
    my $table_name = $self->table_name;
    my $handler    = $self->handler;
    return [
        map {
            $row_class->new(
                table_name => $table_name,
                handler    => $handler,
                row_data   => $_
            )
        } @{ $self->row_datas }
    ];
}

sub sort :method {
    my ($self, $callback) = @_;
    if ($self->suppress_row_objects) {
        @{ $self->row_datas } = sort { &{$callback} } @{ $self->row_datas };
    }
    else {
        @{ $self->inflated_rows } = sort { &{$callback} } @{ $self->inflated_rows };
    }
    return $self;
}

sub grep :method {
    my ($self, $callback) = @_;
    if ($self->suppress_row_objects) {
        @{ $self->row_datas } = grep { &{$callback} } @{ $self->row_datas };
    }
    else {
        @{ $self->inflated_rows } = grep { &{$callback} } @{ $self->inflated_rows };
    }
    return $self;
}

sub limit {
    my ($self, $limit) = @_;
    my $edge = $#{ $self->row_datas };
    splice @{ $self->row_datas }, $limit, $edge;
    return $self if $self->suppress_row_objects || not exists $self->{inflated_rows};
    splice @{ $self->inflated_rows }, $limit, $edge;
    return $self;
}

sub offset {
    my ($self, $offset) = @_;
    splice @{ $self->row_datas }, 0, $offset - 1;
    return $self if $self->suppress_row_objects || not exists $self->{inflated_rows};
    splice @{ $self->inflated_rows }, 0, $offset - 1;
    return $self;
}

sub prefetch {
    my ($self, @prefetch) = @_;
    $self->handler->fetch_and_attach_relay_data($self->table_name, \@prefetch, $self->inflated_rows);
}

sub rows {
    my $self = shift;
    return $self->suppress_row_objects ? $self->row_datas : $self->inflated_rows;
}

sub count { scalar @{ shift->rows(@_) } }

sub first        { shift->rows(@_)->[0]  }
sub last :method { shift->rows(@_)->[-1] }
sub all          { @{ shift->rows(@_) }  }

__PACKAGE__->meta->make_immutable();
__END__

=pod

=encoding utf-8

=head1 NAME

Aniki::Result::Collection - Rows as a collection

=head1 SYNOPSIS

    my $result = $db->select(foo => { bar => 1 });
    for my $row ($result->all) {
        print $row->id, "\n";
    }

=head1 DESCRIPTION

This is collection result class.

=head1 INSTANCE METHODS

=head2 C<rows()>

Returns rows as array reference.

=head2 C<count()>

Returns rows count.

=head2 C<first()>

Returns first row.

=head2 C<last()>

Returns last row.

=head2 C<all()>

Returns rows as array.

=head2 C<prefetch(@prefetch)>

Pre-fetch related rows by rows of collection.

=head1 ACCESSORS

=over 4

=item C<handler : Aniki>

=item C<table_name : Str>

=item C<suppress_row_objects : Bool>

=item C<row_class : ClassName>

=item C<row_datas : ArrayRef[HashRef]>

=item C<inflated_rows : ArrayRef[Aniki::Row]>

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
