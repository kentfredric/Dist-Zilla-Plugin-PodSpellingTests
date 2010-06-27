use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::PodSpellingTests;
# ABSTRACT: Release tests for POD spelling
use Moose;
use Pod::Wordlist::hanekomu;
extends 'Dist::Zilla::Plugin::InlineFiles';

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=for test_synopsis
1;
__END__

=head1 SYNOPSIS

In C<dist.ini>:

    [PodSpellingTests]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/pod-spell.t - a standard Test::Spelling test

=cut

__DATA__
___[ xt/release/pod-spell.t ]___
#!perl

use Test::More;
use Carp qw();

eval "use Pod::Wordlist::hanekomu";
plan skip_all => "Pod::Wordlist:hanekomu required for testing POD spelling"
  if $@;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling"
  if $@;

#
#  Temporary workaround for Test::Spelling to work on systems without 'spell'
#  until Test::Spelling gets around to fixing it.
#
#  Order values to make re-prioritising easier later. I've set aspell to be default to check first
#  because I don't know how to reliably test for "spell"  as I don't have it and can't get it.
#
my @cmds = sort { $a->{order} <=> $b->{order} } (

  # do we need '-l en " for aspell?
  {
    order => 1,
    name  => 'aspell',
    args  => 'aspell list',
    check => sub {
      open my $fh, '-|', 'aspell', '--help' or return;
      while ( defined( my $line = <$fh> ) ) {
        return 1 if $line =~ qr/^\s*list\s*produce.*misspelled/;
      }
      return;
    },
  },
  {
    order => 2,
    name  => 'hunspell',
    args  => 'hunspell -l',
    check => sub {

      #  Urgh. Yuck.
      open my $fh, '-|', 'hunspell --help 2>&1' or return;
      while ( defined( my $line = <$fh> ) ) {
        return 1 if $line =~ qr/^\s*-l\s*print.*misspelled/;
      }
      return;
    },
  },
  {
    order => 3,
    name  => 'ispell',
    args  => 'ispell',
    check => sub {
      return;    # I don't have this, so somebody else will have to add support
    },
  },
  {
    order => 4,
    name  => 'spell',
    args  => 'spell',
    check => sub {

      # TODO: Do a real test, currently we just return 1.
      # So if it doesn't work, its no worse than it currently is. ( Broken )
      return 1;
    },
  },
  {
    order => 99,
    name  => undef,
    args  => undef,
    check => sub {
      Carp::croak("No `spell' function available.");
    },
  }
);

for my $cmd (@cmds) {
  next unless $cmd->{check}->();
  warn "Using $cmd->{name} for spelling ( $cmd->{args} )";
  set_spell_cmd( $cmd->{args} );
  last;
}

all_pod_files_spelling_ok('lib');

