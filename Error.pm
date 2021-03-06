package UMBC::Error;

use strict;
use warnings;
use Apache2::Const qw(:http OK);
use Apache2::RequestRec;
use Apache2::RequestIO;
use APR::Table;

my %errorHash = (
    401 => {
        short => 'Unauthorized',
        long  => 'The server could not verify that you are authorized to access #REDIRECT_URL. Either you supplied invalid credentials (e.g., bad password) or your browser and the server could not agree on a shared authorization method. Please try <a href="http://my.umbc.edu/>logging in again</a>.'
    }, 
    404 => {
        short => 'Not Found',
        long  => 'The requested URL #REDIRECT_URL was not found on this server.'
    }, 
    500 => {
        short => 'Internal Server Error',
        long  => 'The server encountered an internal error or misconfiguration while processing the requested URL #REDIRECT_URL.'
    }
);

my $helpText = 'If you continue to have problems, please <a href="https://rt.umbc.edu/UMBC/RequestHelp.html">submit a help request</a> or contact the Technology Support Center at <a href="tel:4104553838">410-455-3838</a>.';

sub handler {
    my ($r, $data) = @_;
    my $errorCode = $ENV{PATH_INFO};
    my $server = $ENV{SERVER_NAME};
    my $port = $ENV{SERVER_PORT};

    $errorCode =~ s<^/(\d\d\d).*$><$1>;
    my $short = $errorHash{$errorCode}{short};
    my $long = $errorHash{$errorCode}{long};
    $long =~ s<#([A-Z_]*)><$ENV{$1}>eg;

    my $header = qq{
    <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
    <html><head>
    <title>$errorCode $short</title>
    <!-- Compiled and minified CSS -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.96.1/css/materialize.min.css">

    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"/>
    </head><body>
    <div class="container">
    <header>
    <h1>$short</h1>
    </header>
    };

    my $body = qq{
    <main>
    <p>$long</p>
    <p>$helpText</p>
    };

    my $footer = qq{
    </main>
    <footer>
    <address>$server Port $port</address>
    <pre>
};
    if ($ENV{DEBUG}) {
        $footer .= "$_ => $ENV{$_}\n" foreach keys %ENV;
    }
    $footer .= qq{
    </pre>
    <a href="javascript:(function%20()%20{var%20s%20=%20document.createElement('script');s.setAttribute('src',%20'http://fontbomb.ilex.ca/js/main.js');document.body.appendChild(s);}());">Destroy this page</a>
    </footer>
    </div>
    </body></html>
    };

    $r->headers_out->add('Status', $ENV{REDIRECT_STATUS}." Condition Intercepted");
    $r->print($header);
    $r->print($body);
    $r->print($footer);
    $r->rflush();
    return OK;
}

1;
__END__
