# -*-perl-*-

package Astro::FITS::HdrTrans::WFCAM;

=head1 NAME

Astro::FITS::HdrTrans::WFCAM - UKIRT WFCAM translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::WFCAM;

  %gen = Astro::FITS::HdrTrans::WFCAM->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the WFCAM camera of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRTNew
use base qw/ Astro::FITS::HdrTrans::UKIRTNew /;

# We want the FITS standard versions of DATE-OBS/DATE-END parsing
# Not the UKIRT-specific versions that have Z problems
use Astro::FITS::HdrTrans::FITS qw/ UTSTART UTEND /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                  POLARIMETRY => 0,
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ DETECTOR_INDEX WAVEPLATE_ANGLE /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                # WFCAM specific
                CAMERA_NUMBER        => "CAMNUM",
                DEC_SCALE            => "CD2_1",
                DETECTOR_READ_TYPE   => "READMODE",
                NUMBER_OF_COADDS     => "NEXP",
                NUMBER_OF_JITTER_POSITIONS    => "NJITTER",
                NUMBER_OF_MICROSTEP_POSITIONS => "NUSTEP",
                RA_SCALE             => "CD1_2",
                TILE_NUMBER          => "TILENUM",

                # CGS4 + MICHELLE + WFCAM
                CONFIGURATION_INDEX  => 'CNFINDEX',
               );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );

=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns "WFCAM".

=cut

sub this_instrument {
  return "WFCAM";
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=item B<to_DATA_UNITS>

Return the data units.

=cut

sub to_DATA_UNITS {
  my $self = shift;
  my $FITS_headers = shift;
  my $data_units = 'counts/exp';

  if( defined( $FITS_headers->{BUNIT} ) ) {
    $data_units = $FITS_headers->{BUNIT};
  } else {
    my $date = $self->to_UTDATE( $FITS_headers );

    if( $date > 20061023 && $date < 20061220 ) {

      my $read_type = $self->to_DETECTOR_READ_TYPE( $FITS_headers );
      if( substr( $read_type, 0, 2 ) eq 'ND' ) {

        $data_units = 'counts/sec';
      }
    }
  }

  return $data_units;

}

=item B<to_GAIN>

Determine the gain entirely from camera number.

The GAIN FITS header is not used.

=cut

sub to_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $gain;
  if ( defined( $FITS_headers->{CAMNUM} ) ) {
    my $camnum = $FITS_headers->{CAMNUM};
    if ( $camnum == 1 || $camnum == 2 || $camnum == 3 ) {
      $gain = 4.6;
    } elsif( $camnum == 4 ) {
      $gain = 5.6;
    } else {
      $gain = 1.0;
    }
  } else {
    $gain = 1.0;
  }
  return $gain;
}

=item B<from_GAIN>

This is a null operation. The GAIN FITS header in WFCAM data is always incorrect.

=cut

sub from_GAIN {
   return ();
}

=item B<to_NUMBER_OF_OFFSETS>

Return the number of offsets (jitters and micro steps).

=cut

sub to_NUMBER_OF_OFFSETS {
  my $self = shift;
  my $FITS_headers = shift;
  my $njitter = ( defined( $FITS_headers->{NJITTER} ) ? $FITS_headers->{NJITTER} : 1 );
  my $nustep = ( defined( $FITS_headers->{NUSTEP} ) ? $FITS_headers->{NUSTEP} : 1 );

  return $njitter * $nustep + 1;

}

=item B<to_RA_BASE>

The RABASE header converted to degrees.

=cut

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  return ($FITS_headers->{RABASE} * 15.0);
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2003-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
