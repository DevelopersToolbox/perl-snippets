#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use JSON;
use Getopt::Long;
use Term::ANSIColor;

#
# You need to setup an incoming webhook in your slack account.
#
# Navigate to this url: https://my.slack.com/services/new/incoming-webhook/
#
# Create a new incoming webhook and set the url below (or use the -w flag).
# The url will look something like 'https://hooks.slack.com/services/XXXXXXXXXXXXXXXXXX'
#
#
my $default_webhook_url = '';

#
# This is set during the init phase of the script.
#
my $webhook_url;

#
# This is the default channel and can be overriden with -c flag.
#

my $default_channel     = '#general'; 

#
# This is the default username which can be overriden with the -u flag.
#

my $default_username    = 'WSPerlBot';

my %payload;

&init();
&main();

sub main
{
  my $ua = LWP::UserAgent->new;
  $ua->timeout(15);

  my $json = encode_json \%payload;
  my $req = POST("${webhook_url}", ['payload' => $json]);
  my $resp = $ua->request($req);

  if ($resp->is_success)
    {
      #print $resp->decoded_content;  # or whatever
    }
  else
    {
      die $resp->status_line;
    }
  exit(0);
}

sub usage
{
  my ($error) = @_;

  print STDERR << "EOF";

  This program does...

  usage: $0 [ -h ] [ -c channel ] [ -u username ] [ -w webhook ] message

   -h          : this (help) message
   -c channel  : the channel to post to
   -u username : the username to post as
   -u webhook  : the webhook url from slack

  example: $0 -c '#test' -u 'MyBot' 'This is a test'

EOF

  print "  ", colored(sprintf("Error: %s", $error), 'white on_bright_red'), "\n\n" if (defined($error));

  exit;
}

sub init
{
  my $options = {};
  my ($channel, $tmp_channel, $username, $tmp_username, $tmp_webhook_url, $message, $help);

  Getopt::Long::Configure('bundling');
  GetOptions("c=s"        => \$tmp_channel,
             "channel=s"  => \$tmp_channel,
             "u=s"        => \$tmp_username,
             "username=s" => \$tmp_username,
             "w=s"        => \$tmp_webhook_url,
             "webhook=s"  => \$tmp_webhook_url,
             "h"          => \$help,
             "help"       => \$help);

  $message = shift @ARGV;

  usage if (defined($help));

  usage('Missing message') if (!defined($message));

  $channel     = $tmp_channel || $default_channel;
  $username    = $tmp_username || $default_username;
  $webhook_url = $tmp_webhook_url || $default_webhook_url;

  usage('Missing webhook url') if ($webhook_url eq '');

  %payload = (
               channel => $channel,
               username => $username,
               text => $message,
             );
}

