# lambda.pl -- An example program for Data::Variant
#
# Copyright (c) 2004 Viktor Leijon (leijon@ludd.ltu.se) All rights reserved. 
# This program is free software; you can redistribute it and/or modify 
# it under the same terms as Perl itself. 
#
#
# This example program losely follows chapter 5 (Untyped lambda calculus)
# in Benjamin C. Pierce, Types and Programing Languages, but any failures are 
# undoubtedly my own. (Also, he uses call by value, I don't).
#
use warnings;
use strict;
use Carp;
use Switch;
use Data::Variant;
use Data::Dumper;

sub Abstraction; sub Application; sub Variable;

# First define the terms in lambda calculus.
register_variant("Term","Variable <STRING>","Abstraction <STRING> Term",
		 "Application Term Term");

# Then a little context
my %context;

# A few builtins (Church coded booleans)
$context{tru} = Abstraction("t", (Abstraction "f", (Variable "t")));
$context{fls} = Abstraction("t", (Abstraction "f", (Variable "f")));


# Two test expressions.
my $exp1 = Application (
    Application ((Variable "tru"), (Variable "branch1")) ,
    Variable("branch2"));

my $exp2 = Application (
    Application ((Variable "fls"), (Variable "branch1")) ,
    Variable("branch2"));
    

print "Expression: " . simpl_print($exp1) . "\n";
print "Evaluated : " . simpl_print(simpl_eval($exp1,\%context)) . "\n";
print "Expression: " . simpl_print($exp2) . "\n";
print "Evaluated : " . simpl_print(simpl_eval($exp2,\%context)) . "\n";


#
# Simple evaluator
# NOTE: Context handling is awful. No alpha conversion, no removal of 
# variables, there are so many ways this could go bad on anything except
# carefully crafted testcases.
#
sub simpl_eval {
    my($term, $ctx) = @_;
    confess "Need context" unless (defined $ctx);
    my ($str, $t1, $t2,$t3,$t4);
    switch($term->match()) {
	case (mkpat "Application", $t1, $t2) {	 
	    if (match $t1,"Abstraction",$str,$t3) {
		return simpl_eval($t3, expnd_ctx($ctx,$str,$t2));
	    }
	    my $new_t1 = simpl_eval($t1,$ctx);
	    return simpl_eval(Application($new_t1,$t2),$ctx);
	}
	case (mkpat "Variable", $str) {
	    if (exists $ctx->{$str}) {
		return simpl_eval($ctx->{$str},$ctx);
	    } else { 
		return $term;
	    }
	}
	default { return $term };
    }
    return $term;
}

sub expnd_ctx {
    my ($ctx,$key,$val) = @_;
    $ctx->{$key} = $val;
    return $ctx;
}
 

#
# Simple printer
#  No intelligence about when to use parantheses.
#
sub simpl_print {
    my $expr = shift;
    my ($str,$t1,$t2);
    switch ($expr->match()) {
	case (mkpat "Variable", $str) {
	    return "$str";
	}
	case (mkpat "Abstraction", $str, $t1) {
	    return "\\$str .(" . simpl_print($t1) . ")";
	}
	case (mkpat "Application",$t1,$t2) {
	    return "(" . simpl_print($t1) . " " . simpl_print($t2) . ")";
	}
    }
}
