package X11::Xlib::XGCValues;
require X11::Xlib::Struct;

__END__

=head1 NAME

X11::Xlib::XGCValues - Struct providing graphics context and state

=head1 ATTRIBUTES

The fields of the struct are as follows (from X11 docs)

 int function;                 /* logical operation */
 unsigned long plane_mask;     /* plane mask */
 unsigned long foreground;     /* foreground pixel */
 unsigned long background;     /* background pixel */
 int line_width;               /* line width (in pixels) */
 int line_style;               /* LineSolid, LineOnOffDash, LineDoubleDash */
 int cap_style;                /* CapNotLast, CapButt, CapRound, CapProjecting */
 int join_style;               /* JoinMiter, JoinRound, JoinBevel */
 int fill_style;               /* FillSolid, FillTiled, FillStippled FillOpaqueStippled*/
 int fill_rule;                /* EvenOddRule, WindingRule */
 int arc_mode;                 /* ArcChord, ArcPieSlice */
 Pixmap tile;                  /* tile pixmap for tiling operations */
 Pixmap stipple;               /* stipple 1 plane pixmap for stippling */
 int ts_x_origin;              /* offset for tile or stipple operations */
 int ts_y_origin
 Font font;                    /* default text font for text operations */
 int subwindow_mode;           /* ClipByChildren, IncludeInferiors */
 Bool graphics_exposures;      /* boolean, should exposures be generated */
 int clip_x_origin;            /* origin for clipping */
 int clip_y_origin;
 Pixmap clip_mask;             /* bitmap clipping; other calls for rects */
 int dash_offset;              /* patterned/dashed line information */
 char dashes;

The values for C<function>, C<line_style>, C<cap_style>, C<join_style>,
C<fill_style>, C<fill_rule>, C<arc_mode>, and C<subwindow_mode> are
exported with:

  use X11::Xlib ':const_xgcvalues';

Each of the parameter's values are described below:

=over 1

=item C<function>

Can be one of the following: , C<GXclear>, C<GXand>, C<GXandReverse>,
C<GXcopy>, C<GXandInverted>, C<GXnoop>, C<GXxor>, C<GXor>, C<GXnor>,
C<GXequiv>, C<GXinvert>, C<GXorReverse>, C<GXorInverted>,
C<GXcopyInverted>, C<GXnand>, C<GXset>.

=item C<line_style>

can be ONE of C<LineSolid>, C<LineOnOffDash>, or C<LineDoubleDash>.

=item C<cap_style>

can be ONE of C<CapNotLast>, C<CapButt>, C<CapRound>, or 
C<CapProjecting>.

=item C<join_style>

can be ONE of C<JoinMiter>, C<JoinRound>, or C<JoinBevel>.

=item C<fill_style> 

can be ONE of C<FillSolid>, C<FillTiled>, C<FillStippled>, or
C<FillOpaqueStippled>.

=item C<fill_rule> 

can be either C<EvenOddRule> or C<WindingRule>.

=item C<arc_mode>

can be either C<ArcChord> or C<ArcPieSlice>.

=item C<subwindow_mode>

can be either C<ClipByChildren> or C<IncludeInferiors>.

=back

For more information on what each of these mean, see the Xlib manual.

=head1 METHODS

See parent class L<X11::Xlib::Struct>

=head1 AUTHOR

Thomas Nijssen E<lt>thomasnijssen97@gmail.comE<gt>

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2020 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
