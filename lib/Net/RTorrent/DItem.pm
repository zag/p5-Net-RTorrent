#$Id$

package Net::RTorrent::DItem;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Collection::Utl::Base;
use Collection::Utl::Item;
use 5.005;
__PACKAGE__->attributes(qw / _cli/);
our @ISA     = qw(Collection::Utl::Item);
our $VERSION = '0.01';
sub _changed { return 0 }

sub attr {
    return $_[0]->_attr
}

sub init {
    my $self = shift;
    $self->_cli(shift);
    return $self->SUPER::init(@_);
}

=head3 stop

=cut

sub stop {
    my $self= shift;
    $self->_cli->send_request()
}

1;
__END__

=head1 NAME

HTML::WebDAO - Perl extension for create complex web application

=head1 SYNOPSIS

  use HTML::WebDAO;

=head1 ABSTRACT
 
    Perl extension for create complex web application

=head1 DESCRIPTION

Perl extension for create complex web application

=head1 SEE ALSO

http://sourceforge.net/projects/webdao

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
