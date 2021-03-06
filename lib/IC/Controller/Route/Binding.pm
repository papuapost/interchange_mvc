package IC::Controller::Route::Binding;

use strict;
use warnings;

use Moose;

has controller_parameters => (is => 'rw', isa => 'HashRef', default => sub { return {}; },);
has url_names   => (is => 'rw', isa => 'ArrayRef', default => sub { return []; }, );
has name_map    => (is => 'rw', isa => 'HashRef', default => sub { return {}; }, );
has parameters  => (is => 'rw', isa => 'HashRef', default => sub { return {}; }, );
has controller  => (is => 'rw', );
has action      => (is => 'rw', );
has href        => (is => 'rw', );
has route_handler => (is => 'rw', );

my $collect_params = sub {
    my $self = shift;
    my %params
        = map {
            (
                (defined($self->name_map->{$_}) ? $self->name_map->{$_} : $_ ),
                $self->parameters->{$_},
            )
        }
        keys %{ $self->parameters || {} }
    ;
    my @keys = keys %{ $self->controller_parameters };
    @params{@keys} = @{$self->controller_parameters}{@keys};
    return \%params;
};

my $url_map = sub {
    my $self = shift;
    my %urls;
    @urls{@{ $self->url_names }} = (1) x @{ $self->url_names };
    return \%urls;
};

# collects all parameters (mapping parameters combined with controller parameters)
# and filters out those that are in url_names (with no flag) or not in url_names (with
# flag), meaning GET and URL, respectively.
my $parameter_filter = sub {
    my ($self, $not_flag) = @_;
    my $params = $self->$collect_params();
    my $urls = $self->$url_map();
    delete @$params{ grep { defined($urls->{$_}) == defined($not_flag) } keys %$params };
    return $params;
};

sub url_parameters {
    my $self = shift;
    return $self->$parameter_filter();
}

sub get_parameters {
    my $self = shift;
    return $self->$parameter_filter(1);
}

1;

__END__

=pod

=head1 NAME

IC::Controller::Route::Binding -- objects for representing parameters that
are "bound" to a particular controller/action/parameter set

=head1 DESCRIPTION

Within an arbitrary controller action, some specific set of parameters is
necessary in order for URLs to be generated that link back to that action.  The
controller/action and their associated routes may accept various parameters through
the URL, while other less formal parameters may be expected within GET variables.  All
of these considerations go into determining how to build navigational links within
an MVC application.

B<IC::Controller::Route::Binding> provides a means by which a particular controller
may communicate this information to other entities, such that said entities can create
links that go back into the respective controller.  The basic problem this solves:

=over

=item *

Controller A uses widget B in certain situations.

=item *

Widget B requires a certain set of named parameters.  Controller A, as the
caller of widget B, naturally is responsible for providing those parameters

=item *

Controller A maps various parameters (expressed in the URL or in GET space)
through to the corresponding parameters expected by widget B.

=item *

Widget B needs to be able to render links that are relative to controller A,
and needs those links to be able to express the relevant parameters expected by
controller A for mapping back to widget B.

=item *

Solution: Controller A gives widget B a B<IC::Controller::Route::Binding>
instance containing the information needed for widget B to build links back to
the controller as appropriate for that controller; widget B uses said
B<IC::Controller::Route::Binding> instance when building links to ensure that
its parameters play nice with the controller.

=back

=head1 USAGE

A B<IC::Controller::Route::Binding> object would be used in coordination
by a particular controller and a particular widget.  The assumption is that the
controller needs to use the widget, and the widget needs to be able to generate
URLs (for links, forms, etc.) that can affect the widget's behaviors, presentation,
etc. through the controller's public interface (i.e. through URLs supported by that
controller).

It is a given that the widget has its own public interface (specifically, attributes
that can be set on it or passed into the constructor, Moose-style), and the controller
uses this public interface in some manner appropriate for the controller itself within
its relevant actions.  This is a critical point: the controller must not be basing
its use of the widget on implementation details of the widget -- only on the widget's
public interface.  Encapsulate!  I mean it!

The basic usage scenario of B<IC::Controller::Route::Binding>: a controller wants
the URLs generated by a particular widget to go through a particular action on the
controller.  The widget shouldn't know the details of the controller, so the controller
puts the relevant information necessary for navigating it within a binding object.  The
widget uses the binding object to generate links that will work with the widget itself
and fit within the controller's expectations.

The controller sets any name/value combinations that it must receive in the binding
object's B<controller_parameters> hash.  Furthermore, it specifies any parameters
that should be expressed through the actual URL portion and not through GET variables
by name in the B<url_names> list.  Finally, the controller indicates via the B<name_map>
any parameters of its own whose names differ from the corresponding parameters within
the widget but that are responsible for the values received by those corresponding widget
parameters.

The widget, in turn, uses the binding object any time it needs to figure out what
the parameters for a URL generation call should be; the widget puts its own, native
parameter name/value pairs into the B<parameters> hash, and then can use the
B<url_parameters> and B<get_parameters> methods to find out what the ultimate parameter
set needs to be for a given link.  The binding object handles name mapping, effectively
resolving the widget's local parameter needs with the controller's higher-level needs.

  package Foo;
  use Some::Widget;
  use Moose;
  extends qw(IC::Controller);
  
  sub some_action {
      my $self = shift;
      # apparently, this controller action is dependent on receiving parameter "bar".
      # we better ensure that the widget knows to pass along that parameter...
      die 'no love, sir.'
          unless $self->do_something( $self->parameters->{bar} )
      ;
      my $widget = Some::Widget->new;
      # controller uses the "foo" parameter to populate widget's "data" parameter.
      # hence, a mapping is in order.
      $widget->data( $self->parameters->{foo} );

      # let's suppose that "bar" is communicated through the URL, but "foo" is through
      # a GET/POST variable.
      # let's further suppose that $widget has a "binding" attribute where it expects
      # to be given a binding object.
      $widget->binding(
          IC::Controller::Route::Binding->new(
              controller    => $self->registered_name,
              action        => 'some_action',
              controller_parameters => {
                  bar   => $self->parameters->{bar},
              },
              url_names => [qw( bar )],
              name_map  => {
                  data  => 'foo', # tells widget to name the "data" parameter "foo".
              },
          )
      );
      
      $widget->do_your_thing();
      ...
  }

On the widget side of the picture...

  package Some::Widget;
  use IC::Controller::Route::Helper;
  use Moose;
  has binding => (is => 'rw', isa => 'IC::Controller::Route::Binding', );
  has data => (is => 'rw',);
  
  sub do_your_thing {
      my $self = shift;
      # the widget puts whatever parameters it needs into the binding object
      # without regard for names, url/get, etc.
      $self->binding->parameters({
          data => $self->data . ' widgetified!',
      });
      # Now use the url routine to build the link with the binding object.
      # the link will go through the calling controller, but with the 'data'
      # parameter modified by the widget as above.
      my $href = url( binding => $self->binding );
      ...
  }
  
=head1 ATTRIBUTES

Per usual, all attributes are Moose-style.

=over

=item B<controller>

The name of the controller to be associated with this URL information.

=item B<action>

The name of the action associated with this URL information (see B<controller>).

=item B<href>

An arbitrary "page" name associated with this URL information.

=item B<route_handler>

A route handler package/object for handling routing.

=item B<controller_parameters>

A hashref containing name/value pairs required by the controller in order to generate
a URL that will return the controller to the desired state (state which the binding
object effectively represents).

The names and values within this will be built into any parameter listing generated
by the B<IC::Controller::Route::Binding> object.  Whether the parameters are used
as URL or GET parameters depends on the the object's B<url_names> list.

=item B<url_names>

An arrayref listing the names of parameters that the controller can accept within the
URL parameters.  When generating a resolved parameter list, the B<url_names> are
considered to determine if any given parameter should be handed to routing as a URL
parameter or a GET parameter.

=item B<name_map>

A hashref with name/value pairs representing the mapping from controller parameter
names to corresponding widget parameter names.  Thus, if controller A always passes
its parameter "foo" to the widget's parameter "bar", B<name_map> would have an entry:

  foo => 'bar',

The key side of the hash pertains to parameter names specific to the controller; the
value side corresponds to parameters/attributes that should be part of the respective
widget's public interface.

In other words, the B<name_map> is the controller's way of expressing to a widget, via
a B<IC::Controller::Route::Binding> object, "hey you, I use parameter X in order to
provide you with parameter Y; if you need to pass yourself a certain value in parameter Y
through me, use my parameter X."

=item B<parameters>

The hash of name/value parameter pairs that the widget using the binding object needs
to express itself through a given link.

=back

=head1 METHODS

=over

=item B<get_parameters()>

Returns a hash list of GET name/value pairs that can be used in a URL generation routine
(see B<IC::Controller::Route::Helper> or B<IC::Controller>'s url() method); these
are based on resolving the B<parameters> required for the relevant widget with B<name_map>,
along with any B<controller_parameters>, which are not found in the B<url_names> list.

In other words, the parameters are combined with controller parameters, mapped properly,
then cross-reference with B<url_names> so you only get the parameters that should be
expressed via GET variables.  Make sense?

=item B<url_parameters()>

Returns a hash list of URL-space name/value pairs that can be used in a URL generation
routine, based on resolved the B<parameters> for the relevant widget with the B<name_map>,
along with B<controller_parameters>, all determined to be in the B<url_names> list.

More simply: this will return any name/value params that should go into a URL based
on B<parameters> (mapped via B<name_map>) combined with B<controller_parameters> that all
show up in the B<url_names> list.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see: http://www.gnu.org/licenses/ 

=cut
