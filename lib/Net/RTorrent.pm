#$Id$

package Net::RTorrent;

use strict;
use warnings;
use RPC::XML;
use RPC::XML::Client;
use Net::RTorrent::Downloads;
use Carp;
use 5.005;
our @ISA     = qw();
our $VERSION = '0.02';
my $attrs = {
    _cli       => undef,
    _downloads => undef
};
### install get/set accessors for this object.
for my $key ( keys %$attrs ) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

=head2
Creates a new client object that will route its requests to the URL provided. 

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless( {}, $class );
    if (@_) {
        my $rpc_url = shift;
        $self->_cli( RPC::XML::Client->new($rpc_url) );
        $self->_downloads( new Net::RTorrent::Downloads:: $self->_cli );

    }
    else {
        carp "need xmlrpc server URL";
        return;
    }
    return $self;
}

=head2 get_downloads [ <view name > || 'default']

Return collection of downloads

To get list of view:

    xmlrpc http://10.100.0.1:8080/scgitest view_list

  'main'
  'default'
  'name'
  'started'
  'stopped'
  'complete'
  'incomplete'
  'hashing'
  'seeding'
  'scheduler'

=cut

sub get_downloads {
    my $self = shift;
    my $view = shift;
    return new Net::RTorrent::Downloads:: $self->_cli, $view;
}

=head2 load_raw [\$raw_data || new IO::File ], [1||0]

load torrent from file descriptor or scalar ref.
1 - start download now (default)
0 - not start download

=cut

sub load_raw {
    my $self = shift;
    my ( $raw, $flg ) = @_;
    $flg = 1 unless defined $flg;
    my $command = $flg ? 'load_raw_start' : 'load_raw';
    return $self->_cli->send_request( $command, RPC::XML::base64->new($raw) );
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
