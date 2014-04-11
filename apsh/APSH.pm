#!/usr/bin/perl
##################################################################################
# Copyright (C) 2010  Chris Rutledge <rutledge.chris@gmail.com>
#
# http://code.google.com/p/apsh
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
##################################################################################
package APSH;
use strict;
use threads;
use threads::shared;
use Thread::Queue;

our @ISA        = qw(Exporter);
our @EXPORT     = qw(GenNodes, QuoteCMD, CreateThreads, GetPadding, ReturnAllNodes);

my $NODEFILE    = '/etc/apsh/nodes.tab';
my $MAXNAME_L   = "0";

our $QUEUE       = Thread::Queue->new();
our $THREADCNT   = 0;

share($THREADCNT);

##############################
# GenNodes()
#
# Returns a list of lines from
# the config file that match
# the first arg passed in cmdline.
##############################
sub GenNodes {
   my ($GREPV_STRING, $GREP_STRING) = "";

   my (@tNODES, @NODES, @INCLUDE, @EXCLUDE)  = ();

   @tNODES = GetAllNodes();

   ##############################
   # Build INCLUDE and EXCLUDE arrays
   ##############################
   for (split(/,/, $_[0])){
      $_ =~ tr/A-Z/a-z/;

      if ($_ =~ s/^-//){
         push(@EXCLUDE, $_);
      }else{
         push(@INCLUDE, $_);
      }
   }

   for my $Element (0 .. $#tNODES){
      my $CurrLine = $tNODES[$Element];

      $CurrLine =~ tr/A-Z/a-z/;

      ##############################
      # Look for nodes to be included
      ##############################
      for (@INCLUDE){
         if (($_ eq "all") || ($CurrLine =~ /(:|,|^)$_(:|,|$)/)){
            if (($_ eq "all") && ($CurrLine =~ /-all/)){
               delete($tNODES[$Element]);
            }else{
               push(@NODES, $CurrLine);
               $CurrLine = undef;
            }
         }
      }
   }

   for my $Element (0 .. $#NODES){
      my $CurrLine = $NODES[$Element];
      
      $CurrLine =~ tr/A-Z/a-z/;

      ##############################
      # Look for nodes to be excluded
      # and remove them when found
      ##############################
      for (@EXCLUDE){
         if ($CurrLine =~ /(:|,|^)$_(:|,|$)/){
            delete($NODES[$Element]);
         }
      }
   }

   @tNODES = ();

   for (@NODES){
      if (defined($_)){
         push(@tNODES, $_);
      }
   }

   if (! @tNODES){
      print STDERR "ERROR: no nodes found!\n";
      exit(1);
   }

   ####################
   # Find the longest hostname
   ####################
   for (@tNODES){
      my @NODEPROPERTIES = split(/:/, $_);

      my @SSH_DETAILS = split(/,/, $NODEPROPERTIES[0]);

      # Find the longest hostname
      if (length($SSH_DETAILS[0]) > $MAXNAME_L){
         $MAXNAME_L = length($SSH_DETAILS[0]);
      }
   }

   return(@tNODES);
}

##############################
# QuoteCMD($CMD)
#
# Escape special chars in $CMD
##############################
sub QuoteCMD{
   my ($STR) = @_;

   $STR =~ s/\"/\\\"/sg;
   $STR =~ s/\$/\\\$/sg;
   $STR =~ s/\`/\\\`/sg;
   $STR = qq("$STR");

   return($STR);
}

##############################
# CreateThreads(@NODES)
#
# For each node passed in the
# config array - start a thread.
##############################
sub CreateThreads{
   my @NODES      = @_;
   my @THREADS    = ();

   # Create a thread to handle output from worker threads
   push(@THREADS, threads->create(\&outputThread));

   # Create the worker threads
   for (@NODES){
      push(@THREADS, threads->create(\&main::RunCMD, ParseNodeLine($_)));
   }

   for (@THREADS){
      $_->join();
   }
}

##############################
# outputThread()
#
# Rather than letting each thread
# send output to STDOUT, each thread
# now inserts each line of output onto
# the queue. This single thread here is
# now handles output -- preventing any
# sort of output overlap from the
# individual threads.
##############################
sub outputThread{
   my $FINISHED = undef;

   while ((! defined $FINISHED) && (my $OUTPUT = $QUEUE->dequeue())){
      # Could not find a mechanism for letting
      # this thread know when all worker threads
      # were complete. Each will send the following
      # string as the last line of output to signal
      # completion.
      if ($OUTPUT =~ /--THREAD_FINISHED--/){
         $THREADCNT--;
      }else{
         print $OUTPUT;
      }

      if ($THREADCNT eq 0){
         $FINISHED = 1;
      }
   }
}

sub ParseNodeLine{
   my @NODE_DETAILS = split(/:/, $_[0]);

   my @SSH_DETAILS = split(/,/, $NODE_DETAILS[0]);

   my %NODE_CONFIG = ();

   $NODE_CONFIG{'HOSTNAME'} = $SSH_DETAILS[0];
   $NODE_CONFIG{'SSH_OPTS'} = $SSH_DETAILS[1];
   $NODE_CONFIG{'USERNAME'} = $NODE_DETAILS[1];
   $NODE_CONFIG{'GROUPS'}   = $NODE_DETAILS[2];
   $NODE_CONFIG{'PADDING'}  = GetPadding($NODE_CONFIG{'HOSTNAME'});

   return(\%NODE_CONFIG);
}

##############################
# GetPadding($NODENAME)
#
# Return padding based on diff
# between this hostname and the
# longest hostname.
##############################
sub GetPadding{
   my $NODE = $_[0];

   my $PADDING = "";

   my $LENGTHDIFF = $MAXNAME_L - length($NODE);

   for (1 .. $LENGTHDIFF){
      $PADDING .= " ";
   }

   return($PADDING);
}

sub GetAllNodes{
   my @AllNodes = `cat $NODEFILE | grep -v "^[[:space:]]*#" | grep -v "^[[:space:]]*\$" | sort`;

   return(@AllNodes);
}

sub GetNodeGroups{
   my %NODEGROUPS = ();

   my @ALL_NODES = GetAllNodes();

   for (@ALL_NODES){
      chomp($_);

      my @DETAILS = split(/:/, $_);

      my @GROUP_DETAILS = split(/,/, $DETAILS[2]);

      my @HOST_DETAILS = split(/,/, $DETAILS[0]);

      for (@GROUP_DETAILS){
         if ($_ =~ /-all/){
            next;
         }

         $NODEGROUPS{$_}{'NODES'} .= " $HOST_DETAILS[0]";

         $NODEGROUPS{$_}{'NODES'} =~ s/^ //;

         $NODEGROUPS{$_}{'SIZE'}++;
      }
   }

   return(\%NODEGROUPS);
}

1;
