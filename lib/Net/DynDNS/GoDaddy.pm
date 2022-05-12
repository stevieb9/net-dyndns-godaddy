package Net::DynDNS::GoDaddy;

use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;
use Exporter qw(import);
use File::HomeDir;
use HTTP::Tiny;
use JSON;

our $VERSION = '0.01';

our @EXPORT = qw(host_ip_get host_ip_set);
our @EXPORT_OK = qw(api_key_get api_key_set);

my $home_dir;

BEGIN {
    $home_dir = File::HomeDir->my_home;
}

use constant {
    URL             => 'https://api.godaddy.com',
    API_KEY_FILE    => "$home_dir/godaddy_api.json",
};

my $client = HTTP::Tiny->new;
my ($key, $secret);

sub api_key_get {
    return($key, $secret) if $key && $secret;

    {
        local $/;
        open my $fh, '<', API_KEY_FILE
            or croak "GoDaddy API key/secret file ${\API_KEY_FILE} doesn't exist";

        my $data = decode_json(<$fh>);

        $key = $data->{api_key};
        $secret = $data->{api_secret};
    }

    return($key, $secret);
}
sub api_key_set {
    my ($key, $secret) = @_;

    if (! $key || ! $secret) {
        croak "api_key_set() requires an API key and an API secret sent in";
    }

    my $data = {
        api_key     => $key,
        api_secret  => $secret,
    };

    open my $fh, '>', API_KEY_FILE
        or croak "Can't open ${\API_KEY_FILE} for writing";

    print $fh JSON->new->pretty->encode($data);

    return 1;
}

sub _api_key_file {
    return API_KEY_FILE;
}

sub _get {
    my ($url) = @_;
    my $response = $client->get($url);

    my $status = $response->{status};

    if ($status != 200) {
        warn "Failed to connect to $url to get your address: $response->{content}";
        return '';
    }

    return $response->{content};
}


sub __placeholder {}

1;
__END__

=head1 NAME

Net::DynDNS::GoDaddy - Provides Dynamic DNS functionality for your GoDaddy
domains

=for html
<a href="https://github.com/stevieb9/net-dyndns-godaddy/actions"><img src="https://github.com/stevieb9/net-dyndns-godaddy/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/net-dyndns-godaddy?branch=main'><img src='https://coveralls.io/repos/stevieb9/net-dyndns-godaddy/badge.svg?branch=main&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Net::DynDNS::GoDaddy;
    use Net::MyIP;

    my $current_host_ip = host_ip_get();
    my $my_ip = myip();

    if ($current_host_ip ne $my_ip) {
        host_ip_set($my_ip);
    }

=head1 DESCRIPTION

Provides an interface to allow dynamically updating your GoDaddy domain's DNS
name to IP mapping.

=head1 FUNCTIONS

=head2 api_key_get

Fetch your GoDaddy API key and secret from the previously created
C<godaddy_api.json> in your home directory.

B<Not exported by default>.

Croaks if the file can't be read.

I<Returns:> A list of two scalars, the API key and the API secret.

=head2 api_key_set($key, $secret)

Creates the C<godaddy_api.json> file in your home directory that contains your
GoDaddy API key and secret.

B<Not exported by default>.

I<Parameters>:

    $key

I<Mandatory, String>: Your GoDaddy API key

    $secret

I<Mandatory, String>: Your GoDaddy API secret

I<Returns>: C<1> upon success.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
