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
our $COLOR_FLAG = undef;

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
      @NODES = `cat $NODEFILE $GREPV_STRING | grep -v "^#" | grep -v '\\-all' | sort`;
   }else{
      @NODES = `cat $NODEFILE | grep $GREP_STRING $GREPV_STRING | grep -v "^#" | sort`;
   }

   if (! @NODES){
      print STDERR "ERROR: node or group not found!\n";
      exit(1);
   }

   ####################
   # Find the longest hostname
   ####################
   for (@NODES){
      my @NODEPROPERTIES = split(/:/, $_);

      # Find the longest hostname
      if (length($NODEPROPERTIES[0]) > $MAXNAME_L){
         $MAXNAME_L = length($NODEPROPERTIES[0]);
      }
   }

   ####################
   # Assign a color to each
   # node.
   ####################
   if ($COLOR_FLAG){
      my @BGCOLORS   = qw(47 46 45 44 43 42 41 40);
      my @FGCOLORS   = qw(37 36 35 34 33 32 31 30);
      my $FGCOLOR    = undef;
      my $BGCOLOR    = undef;
      my $BRIGHTNESS = "1";
   
      my @BGCOLORS_t = @BGCOLORS;
      my @FGCOLORS_t = @FGCOLORS;
   
      for (@NODES){
         $FGCOLOR = pop(@FGCOLORS_t);
   
         # Avoid same color BG and FG
         if ($BGCOLOR && ($FGCOLOR eq ($BGCOLOR - 10))){
            $FGCOLOR = pop(@FGCOLORS_t);
         }
   
         if (! @FGCOLORS_t){
            @FGCOLORS_t = @FGCOLORS;
   
            $BGCOLOR = pop(@BGCOLORS_t) . "m\033\[";
   
            if ($BRIGHTNESS){
               $BRIGHTNESS = "0";
            }else{
               $BRIGHTNESS = "1";
            }
         }
   
         if (! @BGCOLORS_t){
            @BGCOLORS_t = @BGCOLORS;
         }
   
         $_ .= ":$BGCOLOR$BRIGHTNESS;$FGCOLOR";
      }
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

1;
