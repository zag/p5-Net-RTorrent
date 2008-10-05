# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MetaStore.t'

#########################
#$Id$

# change 'tests => 1' to 'tests => last_test_to_print';
#env TEST_RPC_URL=http://10.100.0.1:8080/scgitest perl t/
use Test::More;
use Data::Dumper;
unless ( $ENV{TEST_RPC_URL} ) {
    plan skip_all => "set TEST_RPC_URL for XML RPC SERVER";
}
else {
    plan tests => 11;
}
use_ok('Net::RTorrent');
my $rpc_url = $ENV{TEST_RPC_URL};
isa_ok   my $obj = (new Net::RTorrent:: $rpc_url ), 'Net::RTorrent', 'create object';
isa_ok  my $cli = $obj->_cli,'RPC::XML::Client' ,'test cli attr';
my $resp = $cli->send_request('system.listMethods');
ok @{$resp->value}, 'check system.listMethods';
unless ( ref $resp ) {
    diag "Error: $resp";
} else {

#diag Dumper  $resp->value ;
    foreach my $method ( @{$resp->value} ) {
        my $h  = $cli->send_request('system.methodHelp', $method);
        print "'$method='=>'$1',\n" if $method =~/d\.get_(.*)/;
#        diag " " , $h->value;
     
     }
}
#diag Dumper $cli->send_request('download_list')->value;
#$cli->send_request()

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

