#$Id$

package Net::RTorrent;

use strict;
use warnings;
use RPC::XML;
use RPC::XML::Client;
use Net::RTorrent::Downloads;
use Carp;
use 5.005;

=head1 NAME

Net::RTorrent - Perl interface to rtorrent via XML-RPC.

=head1 SYNOPSIS

  my $obj =  new Net::RTorrent:: 'http://10.100.0.1:8080/scgitest';
  my $dloads = $obj->get_downloads;
  my $keys = $dloads->list_ids;
  $obj->load_raw( $torrent_raw );

=head1 ABSTRACT
 
Perl interface to rtorrent via XML-RPC

=head1 DESCRIPTION

Net::RTorrent - short way to create tools for rtorrent.

=cut

use constant {
    S_ATTRIBUTES => [
        'get_download_rate'    => 'download_rate',    #in my version dosn't work
        'get_memory_usage'     => 'memory_usage',
        'get_max_memory_usage' => 'max_memory_usage',
        'get_name'             => 'name',
        'get_safe_free_diskspace' => 'safe_free_diskspace',
        'get_upload_rate'         => 'upload_rate',
        'system.client_version'   => 'client_version',
        'system.hostname'         => 'hostname',
        'system.library_version'  => 'library_version',
        'system.pid'              => 'pid',
    ]
};

our @ISA     = qw();
our $VERSION = '0.03';
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

=head1 METHODS

=cut

=head2 new URL

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

=head2 load_raw [\$raw_data || new IO::File ], [ start_now=>1||0 , tag=><string>]

load torrent from file descriptor or scalar ref.

Params:

=over 2 

=item start_now  - start torent now

1 - start download now (default)

0 - not start download

=item tag - save <string> to rtorrent

For read tag value use:

    $ditem->tag

=back

=cut

sub load_raw {
    my $self = shift;
    my ( $raw, $flg ) = @_;
    $flg = 1 unless defined $flg;
    my $command = $flg ? 'load_raw_start' : 'load_raw';
    return $self->_cli->send_request( $command, RPC::XML::base64->new($raw) );
}

=head2 system_stat 

Return system stat.

For example:

    print Dumper $obj->system_stat;

Return:

        {
           'library_version' => '0.11.9',
           'max_memory_usage' => '-858993460', #  at my amd64 ?? 
           'upload_rate' => '0',
           'name' => 'gate.home.zg:1378',
           'memory_usage' => '115867648',
           'download_rate' => '0',
           'hostname' => 'gate.home.zg',
           'pid' => '1378',
           'client_version' => '0.7.9',
           'safe_free_diskspace' => '652738560'
         };

=cut

sub system_stat {
    my $self  = shift;
    my $comms = S_ATTRIBUTES;
    my @list  = @{$comms};
    my ( @res_pull, @cmd_pull ) = ();
    while ( my ( $mname, $aname ) = splice( @list, 0, 2 ) ) {
        push @res_pull, $aname;
        push @cmd_pull, $mname => [];
    }
    my $call_res = $self->do_sys_mutlicall(@cmd_pull);
    my %res      = ();
    while ( my $tmp_res = shift @$call_res ) {
        my $attr_name = shift @res_pull;
        $res{$attr_name} = defined $tmp_res->[1] ? $tmp_res : $tmp_res->[0];
    }
    return \%res

}

=head2 remove_untied (TODO)

remove_untied
    
=cut 

=head2 do_sys_mutlicall 'method1' =>[ <param1>, .. ], ...

Do XML::RPC I<system.multicall>. Return ref to ARRAY of results

For sample.

 print Dumper $obj->do_sys_mutlicall('system.pid'=>[], 'system.hostname'=>[]);

Will return:

    [
           [
             '1378'
           ],
           [
             'gate.home.zg'
          ]
    ];

=cut

sub do_sys_mutlicall {
    my $self    = shift;
    my $res     = [];
    my @methods = ();
    while ( my ( $method, $param ) = splice( @_, 0, 2 ) ) {
        push @methods, { methodName => $method, params => $param },;
    }
    if (@methods) {
        my $resp =
          $self->_cli->send_request(
            new RPC::XML::request::( 'system.multicall', \@methods ) );
        $res = $resp->value;
    }
    return $res;
}

1;
__END__

=head1 Setting up rtorrent

If you are compiling from rtorrent's source code, this is done during the configuration step by adding the flag --with-xmlrpc-c to the configure step. Example ./configure --with-xmlrpc-c. See L<http://libtorrent.rakshasa.no/wiki/RTorrentXMLRPCGuide>

Setup your rtorrent  and Web server. My tips:

=head3 .rtorrent

   scgi_port = 10.100.0.1:5000 
   #for complete erase
   on_erase = erase_complete,"execute=rm,-rf,$d.get_base_path="
   #or for save backup 
   on_erase = move_complete,"execute=mv,-n,$d.get_base_path=,~/erased/ ;d.set_directory=~/erased"

=head3 apache.conf

    LoadModule scgi_module        libexec/apache2/mod_scgi.so
    <IfModule  mod_scgi.c>
      SCGIMount /scgitest 10.100.0.1:5000
      <Location "/scgitest">
         SCGIHandler On
      </Location>
    </IfModule>

My url for XML::RPC is L<http://10.100.0.1:8080/scgitest>.

Use B<xmlrpc> ( L<http://xmlrpc-c.sourceforge.net/> ) for tests:

    xmlrpc http://10.100.0.1:8080/scgitest system.listMethods


=head1 SEE ALSO

Net::RTorrent::DItem, Net::RTorrent::Downloads, L<http://libtorrent.rakshasa.no/wiki/RTorrentXMLRPCGuide>

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
