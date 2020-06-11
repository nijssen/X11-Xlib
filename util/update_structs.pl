#! /bin/sh
d=$(dirname $0);
$d/generate_xevent_xs.pl XEvent < /usr/include/X11/Xlib.h
$d/generate_struct_xs.pl XVisualInfo < /usr/include/X11/Xutil.h
$d/generate_struct_xs.pl XSizeHints < /usr/include/X11/Xutil.h
$d/generate_struct_xs.pl XWindowChanges < /usr/include/X11/Xlib.h
$d/generate_struct_xs.pl XWindowAttributes < /usr/include/X11/Xlib.h
$d/generate_struct_xs.pl XSetWindowAttributes < /usr/include/X11/Xlib.h
$d/generate_struct_xs.pl XPoint < /usr/include/X11/Xlib.h
$d/generate_struct_xs.pl XRectangle < /usr/include/X11/Xlib.h
$d/generate_struct_xs.pl XSegment < /usr/include/X11/Xlib.h
$d/generate_struct_xs.pl XArc < /usr/include/X11/Xlib.h
$d/generate_struct_xs.pl XRenderPictFormat < /usr/include/X11/extensions/Xrender.h
$d/generate_struct_xs.pl XGCValues < /usr/include/X11/Xlib.h
echo done
