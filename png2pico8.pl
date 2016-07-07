#!/usr/local/bin/Perl
=begin

Copyright (c) 2014 Michael Hawthorne (Jigglebizz)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut

use strict;
use warnings;

use POSIX;
use GD;
use Getopt::Long;

#my $ref = GD::Image->new("reference.png") or die "Could not find reference file";

main();

sub main {
    my $iFile = "turt_half.png";
    my $cart  = "carts/turt2.p8";
    my $sprite = 0;
    
    GetOptions( "i=s" => \$iFile,
                "c=s" => \$cart,
                "s=i" => \$sprite);
    
    my $inImage = GD::Image->new($iFile) or die "Could not open " . $iFile;
    my ($width, $height) = $inImage->getBounds();
    print "Image Size: " .$width.", ".$height."\n";
    
    # Do some data validation on image size/location
    my %pico_bounds = ( x => 0,
                        y => 0,
                        w => 128,
                        h => 128 
                        );
    
    my %img_bounds = (  x =>      ($sprite % 16) * 8,
                        y => floor($sprite / 16) * 8,
                        w => $width,
                        h => $height
                        );
                    
    print "Placed in sprite sheet at\n".$img_bounds{x} . ", " . $img_bounds{y} . "\n" . $img_bounds{w} . ", " . $img_bounds{h}."\n";
    if (    $img_bounds{x} < $pico_bounds{x} ||
            $img_bounds{y} < $pico_bounds{y} ||
            $img_bounds{x} + $img_bounds{w} > $pico_bounds{w} ||
            $img_bounds{y} + $img_bounds{h} > $pico_bounds{h}
        ) {
        die "Image file will not fit at specified location in cart sprite sheet";
    }
    
    # Let's convert our input image to the pico's palette
    my $pico_img = convertToPicoPalette($inImage);
    
    # Read in cart data
    open ( my $cart_fh, '<', $cart) or die "Can't open $cart : $!\n";
    my @cart_data = <$cart_fh>;
    close $cart_fh;
    
    # Replace with our data
    # Find graphics start index
    my $gfx_start_idx = 0; 
    for my $line (@cart_data) {
        $gfx_start_idx++;
        if ($line =~ /__gfx__/) { last; }
    }
    
    print "Graphics line " . $gfx_start_idx . "\n";
    # Place data in cart
    for (my $y = 0; $y < $img_bounds{h}; $y++) {
            # Construct string to be placed in cart
            my $img_string = '';
            for (my $x = 0; $x < $img_bounds{w}; $x++) {
                my @rgb = $pico_img->rgb($pico_img->getPixel($x, $y));
                $img_string .= convertColorToPicoNum(@rgb);
            }
            
            #print $img_string;
            substr( $cart_data[$gfx_start_idx + $img_bounds{y} + $y], 
                    $img_bounds{x}, $img_bounds{w}) = 
                    $img_string;
    }
    
    # Write to new cart
    my $filename = $cart;
    open (my $out_fh, '>', $filename) or die "Could not open $filename $!";
    foreach my $line (@cart_data) {
        print $out_fh $line;
    }
    close $out_fh;

    print "Conversion complete. Saved as $filename";
}

sub convertToPicoPalette {
    my ($oldImage) = @_;
    my ($width, $height) = $oldImage->getBounds();
    my $img = GD::Image->newPalette($width, $height);
    
    $img->colorAllocate(0x00, 0x00, 0x00); # Black
    $img->colorAllocate(0x1C, 0x2A, 0x52); # Navy
    $img->colorAllocate(0x7D, 0x24, 0x52); # Purple
    $img->colorAllocate(0x00, 0x86, 0x50); # Kelly Green
    
    $img->colorAllocate(0xAA, 0x51, 0x35); # Poop
    $img->colorAllocate(0x5E, 0x56, 0x4E); # Dark Grey
    $img->colorAllocate(0xC1, 0xC2, 0xC6); # Light Gray
    $img->colorAllocate(0xFE, 0xF0, 0xE7); # Ivory
    
    $img->colorAllocate(0xFE, 0x00, 0x4C); # Red
    $img->colorAllocate(0xFE, 0xA2, 0x00); # Orange
    $img->colorAllocate(0xFE, 0xFE, 0x26); # Yellow
    $img->colorAllocate(0x00, 0xE6, 0x55); # Turtle Green
    
    $img->colorAllocate(0x28, 0xAC, 0xFE); # Sky
    $img->colorAllocate(0x82, 0x75, 0x9B); # Roman Silver
    $img->colorAllocate(0xFE, 0x76, 0xA7); # Pink
    $img->colorAllocate(0xFE, 0xCB, 0xA9); # Skin
    
    for (my $y = 0; $y < $height; $y++) {
        for (my $x = 0; $x < $width; $x++) {
            my @oldColor = $oldImage->rgb($oldImage->getPixel($x, $y));
            my $newColor = $img->colorClosest(@oldColor);
            $img->setPixel($x, $y, $newColor);
        }
    }
    
    #open my $dbg, '>', 'dbg.png' or die;
    #binmode $dbg;
    #print $dbg $img->png;
    #close $dbg;
    return $img;
}

sub convertColorToPicoNum {
    my ($r, $g, $b) = @_;
    
    if (compareRGB((0x00, 0x00, 0x00), ($r, $g, $b))) {
      return 0;
    }
    elsif (compareRGB((0x1C, 0x2A, 0x52), ($r, $g, $b))) {
      return 1;
    }
    elsif (compareRGB((0x7D, 0x24, 0x52), ($r, $g, $b))) {
      return 2;
    }
    elsif (compareRGB((0x00, 0x86, 0x50), ($r, $g, $b))) {
      return 3;
    }
    elsif (compareRGB((0xAA, 0x51, 0x35), ($r, $g, $b))) {
      return 4;
    }
    elsif (compareRGB((0x5E, 0x56, 0x4E), ($r, $g, $b))) {
      return 5;
    }
    elsif (compareRGB((0xC1, 0xC2, 0xC6), ($r, $g, $b))) {
      return 6;
    }
    elsif (compareRGB((0xFE, 0xF0, 0xE7), ($r, $g, $b))) {
      return 7;
    }
    elsif (compareRGB((0xFE, 0x00, 0x4C), ($r, $g, $b))) {
      return 8;
    }
    elsif (compareRGB((0xFE, 0xA2, 0x00), ($r, $g, $b))) {
      return 9;
    }
    elsif (compareRGB((0xFE, 0xFE, 0x26), ($r, $g, $b))) {
      return 'a';
    }
    elsif (compareRGB((0x00, 0xE6, 0x55), ($r, $g, $b))) {
      return 'b';
    }
    elsif (compareRGB((0x28, 0xAC, 0xFE), ($r, $g, $b))) {
      return 'c';
    }
    elsif (compareRGB((0x82, 0x75, 0x9B), ($r, $g, $b))) {
      return 'd';
    }
    elsif (compareRGB((0xFE, 0x76, 0xA7), ($r, $g, $b))) {
      return 'e';
    }
    elsif (compareRGB((0xFE, 0xCB, 0xA9), ($r, $g, $b))) {
      return 'f';
    }
    die "This is a bad problem\n";
    return -1;
}

sub compareRGB {
    my ($ar, $ag, $ab, $br, $bg, $bb) = @_;
    
    return ($ar == $br &&
            $ag == $bg &&
            $ab == $bb);
}