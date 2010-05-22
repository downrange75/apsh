#!/usr/bin/perl
##################################################################################
# Copyright (C) 2010  Chris Rutledge <rutledge.chris@gmail.com>
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
our @EXPORT     = qw(GenNodes, QuoteCMD, CreateThreads, GetPadding);

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
   my ($ALLFLG, $GREPV_STRING, $GREP_STRING) = "";

   for (split(/,/, $_[0])){
      $_ =~ tr/A-Z/a-z/;

      if ($_ =~ s/^-//){
         $GREPV_STRING .= "| grep -iv \"\\(:\\|,\\|^\\)$_\\(:\\|,\\|\$\\)\" ";
      }else{
         if (($_ eq "all") || ($ALLFLG)){
            $ALLFLG = "1";
         }else{
            $GREP_STRING .= "-ie \"\\(:\\|,\\|^\\)$_\\(:\\|,\\|\$\\)\" ";
         }
      }

      if (($_ ne "all") && (! `cat $NODEFILE | grep -i \"\\(:\\|,\\|^\\)$_\\(:\\|,\\|\$\\)\" | grep -v "^#"`)){
         print STDERR "ERROR: node or group \"$_\" not found!\n";
         exit(1);
      }
   }

   my @NODES = ();

   if ($ALLFLG){
      @NODES = `cat $NODEFILE $GREPV_STRING | grep -v "^#" | grep -v '\\-all'`;
   }else{
      @NODES = `cat $NODEFILE | grep $GREP_STRING $GREPV_STRING | grep -v "^#"`;
   }

   if (! @NODES){
      print STDERR "ERROR: node or group not found!\n";
      exit(1);
   }

   return(@NODES);
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
   my @NODES = @_;
   my @THREADS = ();

   for (@NODES){
      my @NODEPROPERTIES = split(/:/, $_);

      if (length($NODEPROPERTIES[0]) > $MAXNAME_L){
         $MAXNAME_L = length($NODEPROPERTIES[0]);
      }

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

1;
