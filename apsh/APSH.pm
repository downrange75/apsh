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

our @ISA        = qw(Exporter);
our @EXPORT     = qw(GenNodes, QuoteCMD, CreateThreads, GetPadding, ReturnAllNodes);

my $NODEFILE    = '/etc/apsh/nodes.tab';
my $MAXNAME_L   = "0";

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

   @tNODES = `cat $NODEFILE | grep -v "^#"`;

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

      # Find the longest hostname
      if (length($NODEPROPERTIES[0]) > $MAXNAME_L){
         $MAXNAME_L = length($NODEPROPERTIES[0]);
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

   for (@NODES){
      push(@THREADS, threads->create(\&main::RunCMD, "$_"));
   }

   for (@THREADS){
      $_->join();
   }
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

sub ReturnAllNodes{
   my @AllNodes = `cat $NODEFILE | grep -v "^#"`;

   return(@AllNodes);
}

1;
