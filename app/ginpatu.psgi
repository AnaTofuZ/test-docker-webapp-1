#!/usr/bin/env perl
use strict;
use warnings;

use Plack::Request;
use LINE::Bot::API;
use LINE::Bot::API::Builder::SendMessage;
use LINE::Bot::API::Builder::TemplateMessage;
use WebService::YDMM;
use utf8;
use Encode;


my $bot = LINE::Bot::API->new(
    channel_secret => $ENV{LINE_SECRET},
    channel_access_token => $ENV{LINE_TOKEN},
);

my $dmm = WebService::YDMM->new(
    affiliate_id => $ENV{DMM_AFFI},
    api_id      =>  $ENV{DMM_API},
);

sub {
    my $req = Plack::Request->new(shift);

    unless ($bot->validate_signature($req->content,$req->header('X-Line-Signature'))) {
        return [200, [], ['bad request']];
    }

    my $events = $bot->parse_events_from_json($req->content);

    for my $event (@{ $events }) {
        if ($event->is_user_event && $event->is_message_event && $event->is_text_message) {
            my $offset = 1;
            my $target;

            if ($event->text =~ /(.+)をあと([0-9]+)個/) {
                $target = $1;
                $offset = $2;
            } else {
                $target = $event->text;
            }

            my $items = $dmm->item("DMM.R18", +{ keyword => $target, hits => 10, offset => $offset })->{items};
    
            my $carousel = LINE::Bot::API::Builder::TemplateMessage->new_carousel(
                alt_text => 'this is a dmm videos',
            );

            for my $i (0..9) {

                my $image_url = $items->[$i]->{imageURL}->{large};
                my $movie_uri = $items->[$i]->{sampleMovieURL}->{size_476_306};
                my $title = $items->[$i]->{title};

                next unless (defined $movie_uri);

                if ($image_url =~ /http:/){
                    $image_url =~ s/http:/https:/;
                }

                if ($movie_uri =~ /http:/){
                    $movie_uri =~ s/http:/https:/;
                }


                if ( length $title >= 40 ){
                    $title = substr($title,0,39);
                }

                my $col = LINE::Bot::API::Builder::TemplateMessage::Column->new(
                    image_url => $image_url,
                    title     => $title,
                    text      => "Please Selecet",
                )->add_uri_action(
                    label   => '動画で致す',
                    uri     => $movie_uri,
                );
                $carousel->add_column($col->build);
            }


            my $messages = LINE::Bot::API::Builder::SendMessage->new()->add_template($carousel->build);
            my $res = $bot->reply_message($event->reply_token,$messages->build);
            ... unless $res->is_success; # error handling
        }
    }
    return [200, [], ["OK"]];
};
