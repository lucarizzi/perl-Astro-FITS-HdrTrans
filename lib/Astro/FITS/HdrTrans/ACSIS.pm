# -*-perl-*-

package Astro::FITS::HdrTrans::ACSIS;

=head1 NAME

Astro::FITS::HdrTrans::ACSIS - class for translation of JCMT ACSIS headers

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::ACSIS;

=head1 DESCRIPTION

This class provides a set of translations for ACSIS at JCMT.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# inherit from the Base translation class and not HdrTrans
# itself (which is just a class-less wrapper)
use base qw/ Astro::FITS::HdrTrans::Base /;

# Use the FITS standard DATE-OBS handling
use Astro::FITS::HdrTrans::FITS;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/);

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
		 INST_DHS          => 'ACSIS',
                );

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
		AIRMASS_START      => 'AMSTART',
		AIRMASS_END        => 'AMEND',
		AMBIENT_TEMPERATURE=> 'ATSTART',
    AZIMUTH_START      => 'AZSTART',
    AZIMUTH_END        => 'AZEND',
    BACKEND            => 'BACKEND',
		CHOP_ANGLE         => 'CHOP_PA',
    CHOP_COORDINATE_SYSTEM => 'CHOP_CRD',
    CHOP_FREQUENCY     => 'CHOP_FRQ',
		CHOP_THROW         => 'CHOP_THR',
    DEC_BASE           => 'CRVAL2',
    DEC_SCALE          => 'CDELT2',
    DEC_SCALE_UNITS    => 'CUNIT2',
		DR_RECIPE          => 'DRRECIPE',
    ELEVATION_START    => 'ELSTART',
    ELEVATION_END      => 'ELEND',
    EQUINOX            => 'EQUINOX',
    FRONTEND           => 'INSTRUME',
    HUMIDITY           => 'HUMSTART',
    LATITUDE           => 'LAT-OBS',
    LONGITUDE          => 'LONG-OBS',
		MSBID              => 'MSBID',
		OBJECT             => 'OBJECT',
		OBSERVATION_NUMBER => 'OBSNUM',
		POLARIMETER        => 'POL_CONN',
		PROJECT            => 'PROJECT',
    RA_BASE            => 'CRVAL1',
    RA_SCALE           => 'CDELT1',
    RA_SCALE_UNITS     => 'CUNIT1',
    REST_FREQUENCY     => 'RESTFREQ',
		SEEING             => 'SEEINGST',
		STANDARD           => 'STANDARD',
		SWITCH_MODE        => 'SW_MODE',
    SYSTEM_VELOCITY    => 'VELOSYS',
		TAU                => 'WVMTAUST',
    TELESCOPE          => 'TELESCOP',
    WAVEPLATE_ANGLE    => 'SKYANG',
               );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

For this class, the method will return true if the B<BACKEND> header exists
and matches 'ACSIS'.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if ( exists $headers->{BACKEND} &&
       defined $headers->{BACKEND} &&
       $headers->{BACKEND} =~ /^ACSIS/i
     ) {
    return 1;
  } else {
    return 0;
  }
}


=back

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many)

=over 4

=item B<to_UTDATE>

Translates the DATE-OBS header into a C<Time::Piece> object.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;

  if( exists( $FITS_headers->{'DATE-OBS'} ) ) {
    $FITS_headers->{'DATE-OBS'} =~ /(\d{4}-\d\d-\d\d)/;
    my $ut = $1;
    $return = Time::Piece->strptime( $ut, "%Y-%m-%d" );
  }
  return $return;
}

=item B<to_UTSTART>

Translates the DATE-OBS header into a C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;

  if( exists( $FITS_headers->{'DATE-OBS'} ) ) {
    $FITS_headers->{'DATE-OBS'} =~ /(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d)/;
    my $ut = $1;
    $return = Time::Piece->strptime( $ut, "%Y-%m-%dT%H:%M:%S" );
  }
  return $return;
}

=item B<to_UTEND>

Translates the DATE-END header into a C<Time::Piece> object.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;

  if( exists( $FITS_headers->{'DATE-END'} ) ) {
    $FITS_headers->{'DATE-END'} =~ /(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d)/;
    my $ut = $1;
    $return = Time::Piece->strptime( $ut, "%Y-%m-%dT%H:%M:%S" );
  }
  return $return;
}

=item B<to_EXPOSURE_TIME>

Uses the to_UTSTART and to_UTEND functions to calculate the exposure
time.

=cut

sub to_EXPOSURE_TIME {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if( exists( $FITS_headers->{'DATE-OBS'} ) &&
      exists( $FITS_headers->{'DATE-END'} ) ) {

    my $start = $self->to_UTSTART( $FITS_headers );
    my $end = $self->to_UTEND( $FITS_headers );
    $return = $end - $start;
  }
  return $return;
}

=item B<to_OBSERVATION_MODE>

Concatenates the SAM_MODE, SW_MODE, and OBS_TYPE header keywords into
the OBSERVATION_MODE generic header, with spaces removed and joined with underscores. For example, if SAM_MODE is 'jiggle  ', SW_MODE is 'chop    ', and OBS_TYPE is 'science ', then the OBSERVATION_MODE generic header will be 'jiggle_chop_science'.

=cut

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if( exists( $FITS_headers->{'SAM_MODE'} ) &&
      exists( $FITS_headers->{'SW_MODE'} ) &&
      exists( $FITS_headers->{'OBS_TYPE'} ) ) {
    my $sam_mode = $FITS_headers->{'SAM_MODE'};
    $sam_mode =~ s/\s//g;
    my $sw_mode = $FITS_headers->{'SW_MODE'};
    $sw_mode =~ s/\s//g;
    my $obs_type = $FITS_headers->{'OBS_TYPE'};
    $obs_type =~ s/\s//g;

    $return = join '_', $sam_mode, $sw_mode, $obs_type;
  }
  return $return;
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
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