package X11::Xlib::XPoint;
require X11::Xlib::Struct;

__END__

=head1 NAME

X11::Xlib::XPoint - Struct providing a two-dimensional X11 point

=head1 ATTRIBUTES

The fields of the struct are as follows (from X11 docs)

  typedef struct {
    short x, y;
  } XPoint;

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
