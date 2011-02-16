# Template::Zoom::Specification - Zoom Specification class
#
# Copyright (C) 2010-2011 Stefan Hornburg (Racke) <racke@linuxia.de>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

package Template::Zoom::Specification;

use strict;
use warnings;

use Template::Zoom::Iterator;

=head1 NAME

Template::Zoom::Specification - Specification class for Template::Zoom

=head1 SYNOPSIS

    $xml_spec = new Template::Zoom::Specification::XML;
    $spec = $xml_spec->parse_file('spec.xml');
    $spec->set_iterator('cart', $cart);

    $conf_spec = new Template::Zoom::Specification::Scoped;
    $spec = $conf_spec->parse_file('spec.conf);

=head1 DESCRIPTION

    Specification class for Template::Zoom.

=cut

# Constructor

sub new {
	my ($class, $self);
	my (%params);

	$class = shift;
	%params = @_;

	$self = \%params;

	# lookup hash for elements by class
	$self->{classes} = {};

	# lookup hash for elements by id
	$self->{ids} = {};
	
	bless $self;
}

sub container_add {
	my ($self, $new_containerref) = @_;
	my ($containerref, $container_name, $class);

	$container_name = $new_containerref->{container}->{name};

	$containerref = $self->{containers}->{$new_containerref->{container}->{name}} = {input => {}};

	$class = $new_containerref->{container}->{class} || $container_name;

	$self->{classes}->{$class} = {%{$new_containerref->{container}}, type => 'container'};

	return $containerref;
}

sub list_add {
	my ($self, $new_listref) = @_;
	my ($listref, $list_name, $class);

	$list_name = $new_listref->{list}->{name};

	$listref = $self->{lists}->{$new_listref->{list}->{name}} = {input => {}};

	$class = $new_listref->{list}->{class} || $list_name;

	$self->{classes}->{$class} = {%{$new_listref->{list}}, type => 'list'};

	if (exists $new_listref->{list}->{iterator}) {
		$listref->{iterator} = $new_listref->{list}->{iterator};
	}

	# loop through filters for this list
	for my $filter (@{$new_listref->{filter}}) {
		$listref->{filter}->{$filter->{name}} = $filter;
	}

	# loop through inputs for this list
	for my $input (@{$new_listref->{input}}) {
		$listref->{input}->{$input->{name}} = $input;
	}

	# loop through sorts for this list
	for my $sort (@{$new_listref->{sort}}) {
		$listref->{sort}->{$sort->{name}} = $sort;
	}
	
	# loop through params for this list
	for my $param (@{$new_listref->{param}}) {
		$class = $param->{class} || $param->{name};
		$self->{classes}->{$class} = {%{$param}, type => 'param', list => $list_name};	
	}

	# loop through paging for this list
	for my $paging (@{$new_listref->{paging}}) {
		if (exists $listref->{paging}) {
			die "Only one paging allowed per list\n";
		}
		$listref->{paging} = $paging;
		$class = $paging->{class} || $paging->{name};
		$self->{classes}->{$class} = {%{$paging}, type => 'paging', list => $list_name};	
	}
	
	return $listref;
}

sub form_add {
	my ($self, $new_formref) = @_;
	my ($formref, $form_name, $id, $class);

	$form_name = $new_formref->{form}->{name};

	$formref = $self->{forms}->{$new_formref->{form}->{name}} = {input => {}};

	if ($id = $new_formref->{form}->{id}) {
		$self->{ids}->{$id} = {%{$new_formref->{form}}, type => 'form'};
	}
	else {
		$class = $new_formref->{form}->{class} || $form_name;

		$self->{classes}->{$class} = {%{$new_formref->{form}}, type => 'form'};
	}
	
	# loop through inputs for this form
	for my $input (@{$new_formref->{input}}) {
		$formref->{input}->{$input->{name}} = $input;
	}
	
	# loop through params for this form
	for my $param (@{$new_formref->{param}}) {
		$class = $param->{class} || $param->{name};

		$self->{classes}->{$class} = {%{$param}, type => 'param', form => $form_name};	
	}

	# loop through fields for this form
	for my $field (@{$new_formref->{field}}) {
		if (exists $field->{id}) {
			$self->{ids}->{$field->{id}} = {%{$field}, type => 'field', form => $form_name};
		}
		else {
			$class = $field->{class} || $field->{name};
			$self->{classes}->{$class} = {%{$field}, type => 'field', form => $form_name};
		}
	}
	
	return $formref;
}

sub value_add {
	my ($self, $new_valueref) = @_;
	my ($valueref, $value_name, $id, $class);
	
	$value_name = $new_valueref->{value}->{name};

	$valueref = $self->{values}->{$new_valueref->{value}->{name}} = {};
	
	if ($id = $new_valueref->{value}->{id}) {
		$self->{ids}->{$id} = {%{$new_valueref->{value}}, type => 'value'};
	}
	else {
		$class = $new_valueref->{value}->{class} || $value_name;

		$self->{classes}->{$class} = {%{$new_valueref->{value}}, type => 'value'};
	}
use Data::Dumper;
print Dumper($valueref);
	return $valueref;
}	

sub i18n_add {
	my ($self, $new_i18nref) = @_;
	my ($i18nref, $i18n_name, $id, $class);

	$i18n_name = $new_i18nref->{value}->{name};
	
	$i18nref = $self->{i18n}->{$new_i18nref->{value}->{name}} = {};
	
	if ($id = $new_i18nref->{value}->{id}) {
		$self->{ids}->{$id} = {%{$new_i18nref->{value}}, type => 'i18n'};
	}
	else {
		$class = $new_i18nref->{value}->{class} || $i18n_name;

		$self->{classes}->{$class} = {%{$new_i18nref->{value}}, type => 'i18n'};
	}
	
	return $i18nref;
}

sub list_iterator {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{iterator};
	}
}

sub list_inputs {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{input};
	}
}

sub list_sorts {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{sort};
	}
}

sub list_filters {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{filter};
	}
}

sub form_inputs {
	my ($self, $form_name) = @_;

	if (exists $self->{forms}->{$form_name}) {
		return $self->{forms}->{$form_name}->{input};
	}
}

sub iterator {
	my ($self, $name) = @_;

	if (exists $self->{iters}->{$name}) {
		return $self->{iters}->{$name};
	}
}

sub set_iterator {
	my ($self, $name, $iter) = @_;
	my ($iter_ref);

	$iter_ref = ref($iter);

	if ($iter_ref eq 'ARRAY') {
		$iter = new Template::Zoom::Iterator($iter);
	}
	
	$self->{iters}->{$name} = $iter;
}

sub resolve_iterator {
	my ($self, $input) = @_;
	my ($input_ref, $iter);

	$input_ref = ref($input);

	if ($input_ref eq 'ARRAY') {
		$iter = new Template::Zoom::Iterator($input);
	}
	elsif ($input_ref) {
		# iterator already resolved
		$iter = $input_ref;
	}
	elsif (exists $self->{iters}->{$input}) {
		$iter = $self->{iters}->{$input};
	}
	else {
		die "Failed to resolve iterator $input.";
	}

	return $iter;
}

sub element_by_class {
	my ($self, $class) = @_;

	if (exists $self->{classes}->{$class}) {
		return $self->{classes}->{$class};
	}

	return;
}

sub element_by_id {
	my ($self, $id) = @_;

	if (exists $self->{ids}->{$id}) {
		return $self->{ids}->{$id};
	}

	return;
}


sub list_paging {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{paging};
	}	
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-zoom at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Zoom>.
=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
	
1;
