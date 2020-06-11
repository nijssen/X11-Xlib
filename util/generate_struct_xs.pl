#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Temp;

my $goal= shift
  or print <<'END';

Usage:
  generate_struct_xs.pl XEvent < /usr/include/X11/Xlib.h

END


my $input= do { local $/= undef; <STDIN> };
my %types;
my @def_stack= ( { cur_field => undef, fields => \%types } );
my $comment= 0;
while ($input =~ m!(typedef\b|struct\b|union\b|\{|\}|\;|\[|\]|/\*[^*]+|,|\*/|//.*$|\s+|#.*$|\*|\w+\b|.)!cmg) {
    my $token= $1;
    next if $comment && ($token ne '*/');
    #printf " token '%s'\n\t(comment=%d)\t(def_stack=%2d)\t(cur_field=%2s)\n",
    #	$token, $comment, scalar @def_stack, $def_stack[-1]{cur_field}? scalar @{$def_stack[-1]{cur_field}} : 'undef'
    #	unless $token =~ /^\s*$/;
    next unless @def_stack > 1 || $def_stack[-1]{cur_field} || ($token =~ /^(typedef\b|union\b|struct\b|\/\*|\*\/)/);
    
    if ($token eq 'typedef' or $token eq 'struct' or $token eq 'union') {
        push @{ $def_stack[-1]{cur_field} }, $token;
    } elsif ($token eq '{') {
        my %type= ();
        $type{typedef}= shift @{$def_stack[-1]{cur_field}}
            if $def_stack[-1]{cur_field}[0] eq 'typedef';
        if ($def_stack[-1]{cur_field}[0] eq 'struct' or $def_stack[-1]{cur_field}[0] eq 'union') {
            $type{container_type}= shift @{$def_stack[-1]{cur_field}};
            $type{container_name}= shift @{$def_stack[-1]{cur_field}}
                if @{$def_stack[-1]{cur_field}};
        }
        @{$def_stack[-1]{cur_field}}= ( \%type );
        push @def_stack, \%type;
    } elsif ($token eq '}') {
        pop @def_stack;
    } elsif ($token eq ';') {
        my $cur_field= delete $def_stack[-1]{cur_field};
        if (@$cur_field) {
            # break apart commas into separate fields
            my @fields= ( [] );
            for my $part (@$cur_field) {
                if ($part eq ',') {
                    push @fields, [ grep { !($_ =~ /[][*&]/) } @{ $fields[-1] } ];
                    pop @{$fields[-1]}; # remove variable name
                } else {
                    push @{ $fields[-1] }, $part;
                }
            }
            for my $field (@fields) {
                # find and remove name portion
                my $name;
                for (my $i= $#$field; $i > 0; $i--) {
                    if ($field->[$i] =~ /^[a-zA-Z_]/) {
                        ($name)= splice(@$field, $i, 1);
                        last;
                    }
                }
                #if (@def_stack == 1) { warn "Found $name\n"; } else { warn "Found  .$name\n"; }
                $def_stack[-1]{fields}{$name}= normalize_type($field);
            }
        }
    } elsif (substr($token,0,2) eq '/*') {
        $comment= 1;
    } elsif ($token eq '*/') {
        $comment= 0;
    } elsif ($token =~ m,^//, or $token =~ /^\s/ or $token =~ /^#/) {
    } elsif ($token eq '*' or $token eq ',' or $token eq ')' or $token eq '(' or $token eq '[' or $token eq ']' or $token =~ /\w+/) {
        push @{ $def_stack[-1]{cur_field} }, $token;
    } else {
        die "Unexpected token '$token' near ".substr($input, pos($input) - 10, 10).'|'.substr($input, pos($input), 50)."\n";
    }
}

sub normalize_type {
    my $f= shift;
    my @parts= grep{ !($_ =~ /const|static|volatile/) } @$f;
    if (grep { ref $_ } @parts) {
        @parts == 1 or warn "Ignoring ".join(' ',@parts).' because it is too complicated';
        return $parts[0] if @parts == 1;
    } else {
        return join ' ', @parts;
    }
}

my %def_bits= (
    XSizeHints => {
        defined_field => 'flags',
        defined_flag => {
            PPosition  => [qw( x y )],
            PSize      => [qw( width height )],
            PMinSize   => [qw( min_width min_height )],
            PMaxSize   => [qw( max_width max_height )],
            PResizeInc => [qw( width_inc height_inc )],
            PAspect    => [qw( min_aspect.x min_aspect.y max_aspect.x max_aspect.y )],
            PBaseSize  => [qw( base_width base_height )],
            PWinGravity=> [qw( win_gravity )],
        },
    },
);

#use DDP;
#p %types;
$types{$goal} or die "No type for $goal";

# Traverse struct recursively building a flat list of c_name => { pl_name, c_name, ctype }
sub flatten_fields {
    my ($result, $type_name, $type_spec, $c_path, $pl_prefix)= @_;
    ref $type_spec && ref $type_spec->{fields} eq 'HASH'
        or die "Not a container type: $type_name $c_path\n";
    for my $fieldname (keys %{ $type_spec->{fields} || {} }) {
        my $fieldtype= $type_spec->{fields}{$fieldname};
        # convert the type name to a type spec, in the case of typedefs
        my $fieldtype_spec= ref $fieldtype? $fieldtype : $types{$fieldtype};
        if (ref $fieldtype_spec && $fieldtype_spec->{container_type} eq 'union') {
            flatten_fields($result, $fieldtype, $fieldtype_spec, "$c_path$fieldname.", $pl_prefix);
        } elsif (ref $fieldtype_spec && $fieldtype_spec->{container_type} eq 'struct') {
            flatten_fields($result, $fieldtype, $fieldtype_spec, "$c_path$fieldname.", "$pl_prefix${fieldname}_");
        } else {
            my $member= {
                pl_name => "$pl_prefix$fieldname",
                c_name  => "$c_path$fieldname",
                c_type  => $fieldtype,
            };
            $result->{"$c_path$fieldname"}= $member;
        }
    }
}

my %members;
flatten_fields(\%members, $goal, $types{$goal}, '', '');
delete $members{c_class};

# Set values of "defined_field" and "defined_flag" for any struct which uses
# bitflags to indicated which fields are defined.
if ($def_bits{$goal}) {
    for my $flag (keys %{ $def_bits{$goal}{defined_flag} }) {
        my $fields= $def_bits{$goal}{defined_flag}{$flag};
        for (@$fields) {
            if ($members{$_}) {
                $members{$_}{defined_flag}= $flag;
                $members{$_}{defined_field}= $def_bits{$goal}{defined_field};
            }
        }
    }
}

my %int_types= map { $_ => 1 } qw( int short long Bool char );
my %unsigned_types= map { $_ => 1 } 'unsigned', 'unsigned int', 'unsigned long', 'unsigned short',
	qw( Time VisualID );
my %xid_types= map { $_ => 1 } qw( Window Drawable Colormap Cursor Atom Pixmap XserverRegion PictFormat Picture Glyph GlyphSet Font );

sub sv_read {
    my ($type, $access, $svname)= @_;
    return "$access= SvIV($svname);" if $int_types{$type};
    return "$access= SvUV($svname);" if $unsigned_types{$type};
    return "$access= PerlXlib_sv_to_xid($svname);" if $xid_types{$type};
    return "$access= PerlXlib_sv_to_display($svname, 0);" if $type eq 'Display *';
    return "$access= PerlXlib_sv_to_screen($svname, 0);" if $type eq 'Screen *';
    return "$access= ($type) PerlXlib_sv_to_display_innerptr($svname, 0);" if $type eq 'Visual *';
    return "{"
        ." if (!SvPOK($svname) || SvCUR($svname) != sizeof($1)*$2)"
        .'  croak("Expected scalar of length %ld but got %ld",'." (long)(sizeof($1)*$2), (long)SvCUR($svname));"
        ." memcpy($access, SvPVX($svname), sizeof($1)*$2);"
        ."}" if $type =~ /^(\w+) \[ (\d+) \]$/;
    die "Don't know how to read $type from an SV";
}
sub sv_create {
    my ($type, $value)= @_;
    return "newSViv($value)" if $int_types{$type};
    return "newSVuv($value)" if $unsigned_types{$type} or $xid_types{$type};
    return "newSVsv($value? PerlXlib_obj_for_display($value, 0) : &PL_sv_undef)" if $type eq 'Display *';
    return "newSVsv($value? PerlXlib_obj_for_screen($value) : &PL_sv_undef)" if $type eq 'Screen *';
    return "newSVsv($value? PerlXlib_obj_for_display_innerptr(dpy, $value, \"X11::Xlib::Visual\", SVt_PVMG, 1)"
        ." : &PL_sv_undef)" if $type eq 'Visual *';
    #return "($value? sv_setref_pv(newSV(0), \"X11::Xlib::$1\", (void*) $value) : &PL_sv_undef)"
    #    if $type =~ /^(\w+) \*$/;
    return "newSVpvn((void*)$value, sizeof($1)*$2)"
        if $type =~ /^(\w+) \[ (\d+) \]$/;
    die "Don't know how to create SV from $type";
}

sub generate_xs_accessor {
    my $member= shift;
    my $type= $member->{c_type};
    my $sv_read= sv_read($type, "s->$member->{c_name}", "value");
    my $sv_create= sv_create($type, "s->$member->{c_name}");
    my $need_dpy= ($sv_read =~ /\b dpy \b/x or $sv_create =~ /\b dpy \b/x);
    my $self_type= $need_dpy? 'SV' : $goal;
    my $init= $need_dpy?
        "$goal *s= ( $goal * ) PerlXlib_get_struct_ptr(
           self, 0, \"X11::Xlib::$goal\", sizeof($goal),
           (PerlXlib_struct_pack_fn*) &PerlXlib_${goal}_pack
         );
         SV *dpy_sv= PerlXlib_get_displayobj_of_opaque(SvRV(self));
         Display *dpy= PerlXlib_get_magic_dpy(dpy_sv,0);"
        : "$goal *s= self;";
    return <<"@";
void
$member->{pl_name}(self, value=NULL)
    $self_type *self
    SV *value
  INIT:
    $init
  PPCODE:
    if (value) {
      $sv_read
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal($sv_create));
    }

@
}

sub generate_pack_c {
    my $c= <<"@";
void PerlXlib_${goal}_pack($goal *s, HV *fields, Bool consume) {
    SV **fp;
    Display *dpy= NULL; /* not available.  Magic display attribute is handled by caller. */
@
    for my $c_name (sort keys %members) {
        my $member= $members{$c_name};
        my $name= $member->{pl_name};
        my $sv_read= sv_read($member->{c_type}, "s->$member->{c_name}", "*fp");
        my $name_len= length($name);
        my $mark_defined= $member->{defined_flag}? "s->$member->{defined_field} |= $member->{defined_flag}; " : '';
        $c .= <<"@";

    fp= hv_fetch(fields, "$name", $name_len, 0);
    if (fp && *fp) { $mark_defined$sv_read if (consume) hv_delete(fields, "$name", $name_len, G_DISCARD); }
@
    }

    return $c . "}\n";
}

sub generate_unpack_c {
    my $c= <<"@";
void PerlXlib_${goal}_unpack_obj($goal *s, HV *fields, SV *obj_ref) {
    /* hv_store may return NULL if there is an error, or if the hash is tied.
     * If it does, we need to release the reference to the value we almost inserted,
     * so track allocated SV in this var.
     */
    SV *sv= NULL;
@
    # Some fields need to be inflated to objects, and need a Display* pointer in order to
    # do that in the most efficient manner.  Display* can be gotten from a variety of
    # methods.  But, don't do any of this unless domething needs it.
    my $need_dpy= grep sv_create($_->{c_type}, 'x') =~ /\b dpy \b/x, values %members;

    if ($need_dpy) {
        if ($members{display} && $members{display}{c_type} =~ /Display/) {
            $c .= "    Display *dpy= s->display;\n";
        } elsif ($members{screen} && $members{screen}{c_type} =~ /Screen/) {
            $c .= "    Display *dpy= s->screen? DisplayOfScreen(s->screen) : NULL;\n";
        } else {
            $c .= "    SV *dpy_sv= obj_ref && SvROK(obj_ref)? PerlXlib_get_displayobj_of_opaque((void*)SvRV(obj_ref)) : NULL;\n";
            $c .= "    Display *dpy= dpy_sv && SvROK(dpy_sv)? PerlXlib_get_magic_dpy(dpy_sv, 0) : NULL;\n";
        }
    }

    for my $c_name (sort keys %members) {
        my $member= $members{$c_name};
        my $name= $member->{pl_name};
        my $code= sprintf "    if (!hv_store(fields, %-12s, %2d, (sv=%s), 0)) goto store_fail;\n",
            qq{"$name"}, length($name), sv_create($member->{c_type}, "s->$member->{c_name}");
        if ($member->{defined_field}) {
            $code =~ s/^ *//;
            chomp $code;
            $code= "    if (s->$member->{defined_field} & $member->{defined_flag}) { $code }\n";
        }
        $c .= $code;
    }

    $c .= <<'@';
    return;
    store_fail:
        if (sv) sv_2mortal(sv);
        croak("Can't store field in supplied hash (tied maybe?)");
}
@
    return $c;
}

sub patch_file {
    my ($fname, $token, $new_content)= @_;
    my $begin_token= "BEGIN $token";
    my $end_token=   "END $token";
    open my $orig, "<", "$FindBin::Bin/../$fname" or die "open($fname): $!";
    my $new= File::Temp->new(DIR => "$FindBin::Bin/..", TEMPLATE => "${fname}_XXXX");
    while (<$orig>) {
        $new->print($_);
        last if index($_, $begin_token) >= 0;
    }
    $orig->eof and die "Didn't find $begin_token in $fname\n";
    $new->print($new_content);
    while (<$orig>) { if (index($_, $end_token) >= 0) { $new->print($_); last; } }
    $orig->eof and die "Didn't find $end_token in $fname\n";
    while (<$orig>) { $new->print($_) }
    $new->close or die "Failed to save $new";
    rename($new, "$FindBin::Bin/../$fname") or die "rename: $!";
}

my $out_xs= <<"@";

MODULE = X11::Xlib                PACKAGE = X11::Xlib::${goal}

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(${goal});
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::${goal}", sizeof($goal),
            (PerlXlib_struct_pack_fn*) &PerlXlib_${goal}_pack
        );
        memset((void*) sptr, 0, sizeof($goal));

void
_pack(s, fields, consume=0)
    ${goal} *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_${goal}_pack(s, fields, consume);

void
_unpack(s, fields)
    ${goal} *s
    HV *fields
    PPCODE:
        PerlXlib_${goal}_unpack_obj(s, fields, ST(0));

@
$out_xs .= generate_xs_accessor($_) for map { $members{$_} } sort keys %members;

my $out_pl= "\n";
my $out_const= "";

my $file_splice_token= "GENERATED X11_Xlib_${goal}";

my $out_c=  "\n" . generate_pack_c() . "\n" . generate_unpack_c() . "\n";
patch_file("Xlib.xs", $file_splice_token, $out_xs);
patch_file("PerlXlib.c", $file_splice_token, $out_c);
