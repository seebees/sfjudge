my $dinn_file = shift @ARGV;

die "Couldn't open '$dinn_file'" unless open INN, "$dinn_file";


$category = "";
$linenum = 0;

%fparam = ( 
	"faire"    => { "args" => 1, "use" => "faire | {line1} [| {line2}]... ", },	
	"category" => { "args" => 3, "use" => "category | {small} | {long} | {normalscore} [| {extra}...]", }, 
	"heading"  => { "args" => 0, "use" => "heading", }, 
	"fatline"  => { "args" => 0, "use" => "fatline", }, 
	"thinline" => { "args" => 0, "use" => "thinline   (same as fatline)", }, 
	"section"  => { "args" => 2, "use" => "section ", }, 
	"rbullet"  => { "args" => 1, "use" => "rbullet | {score} [ | {description} ]*", }, 
	"lbullet"  => { "args" => 1, "use" => "lbullet | {score} [ | {description} ]*", }, 
	"scorebox" => { "args" => 0, "use" => "scorebox ", }, 
);

$num_category = 0;
$num_section = 0;
$num_bullet = 0;

$faire_block = "";

@popstack = ();

while( <INN> )
{
	chomp;
	$linenum++;
	next if /^\s*#/;
	my @parts = split /[|]/;
	next unless @parts;

	s/^\s+//, s/\s+$// foreach @parts;

	my $x = lc shift @parts;

	next if( $x eq "{" );

	if( $x eq "}" )
	{
		while( @popstack )	# safe, won't go below zero elements
		{
			my $element = pop @popstack;
			last if $element eq "{";
			push @{$html{ $category }}, $element;
		}
		next;
	}

	$function = $x;

	if( ! exists $fparam{ $function } )
	{
		printf STDERR "LINE: %d '%s' unknown\n", $linenum, $function;
		printf OUT    "LINE: %d '%s' unknown\n", $linenum, $function;
		next;
	}

	if( $fparam{ $function }{ "args" } > scalar @parts )
	{
		printf STDERR "LINE %d: [%s] not enough args (%s)\n", $linenum, $function, $fparam{ $function }{ "use" };
		printf OUT    "LINE %d: [%s] not enough args (%s)\n", $linenum, $function, $fparam{ $function }{ "use" };
		next;
	}

	if( $function eq "faire" )
	{
		$faire_block = "<div id=\"header\">\n"
				. "<p style=\"font-size: 5px;\">&nbsp;</p>\n";
		$faire_block .= "<p>\n";
		$faire_block .= join "<br/>", @parts;
		$faire_block .= "\n";
		$faire_block .= "</p>\n";
		$faire_block .= "</div>\n";
	}
	elsif( $function eq "heading" )
	{
		push @{$html{ $category }}, "\n";
		push @{$html{ $category }}, "<img id=\"fatline\" src=\"sfj-rubric-fatline.jpg\" />\n";
		push @{$html{ $category }}, "\n";

		push @{$html{ $category }}, "<div class=\"section\" id=\"chooser\">\n";
		push @{$html{ $category }}, "<p style=\"font-size: 5px;\">&nbsp;</p>\n";
		push @{$html{ $category }}, "<form name=\"category_"
									. $category
									. "\" action=\"phys_select.asp\" method=\"get\" \n";
		push @{$html{ $category }}, "style=\"margin-left: 5px; margin-top: 16px; \">\n";
		push @{$html{ $category }}, "Enter an exhibit number: \n";
		push @{$html{ $category }}, "<input type=\"text\" name=\"exhibit\" size=5 />\n";
		push @{$html{ $category }}, "<input type=\"submit\" name=\"Submit\" />\n";
		push @{$html{ $category }}, "</form>\n";
		push @{$html{ $category }}, "</div>\n";
	}
	elsif( $function eq "scorebox" )
	{
		push @popstack, "{";
		push @{$html{ $category }}, "<div class=\"submission\" id=\"submission\">\n";
		push @popstack, "</div>\n";

		push @{$html{ $category }}, "<form name=\"category_phys\" action=\"phys_action.asp\" method=\"get\" style=\"margin-left: 0px; margin-top: 0px; \">\n";

		push @popstack, "</form>\n";
		push @popstack, "<input type=\"submit\" value=\"Next >>\" />\n";
		push @popstack, "<input type=\"submit\" value=\"Exit\" />\n";
		push @popstack, "<input type=\"submit\" value=\"Submit\" />\n";
		push @popstack, "<input type=\"submit\" value=\"<< Next\" />\n";
		push @popstack, "<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n";

		push @popstack, "\n";
		push @popstack, "<img id=\"fatline\" src=\"sfj-rubric-fatline.jpg\" />\n";
		push @popstack, "\n";

	}
	elsif( $function eq "fatline" 
		|| $function eq "thinline" )
	{
		push @{$html{ $category }}, "\n";
		push @{$html{ $category }}, "<img id=\"fatline\" src=\"sfj-rubric-fatline.jpg\" />\n";
		push @{$html{ $category }}, "\n";
	}
	elsif( $function eq "section" )
	{
		my $section_name = shift @parts;
		my $section_desc = shift @parts;

		push @popstack, "{";

		push @{$html{ $category }}, "<div class=\"section\" id=\"section$num_section\">\n";
		push @popstack, "</div>\n";
		$num_section++;

		push @{$html{ $category }}, "<span class=\"category\">" . $section_name . "</span>\n";
		push @{$html{ $category }}, "<span style=\"align: right\">" . $section_desc . "</span>\n";
		$num_bullet = 0;
	}
	elsif( $function eq "rbullet" )
	{
		my $value = shift @parts;
		my $question = shift @parts;

		unless( $num_bullet++ )
		{
			push @{$html{ $category }}, "<table class=\"rbullet\" id=\"" 
				. sprintf( "s%d", $num_section ) 
				. "\" width=400px style=\"color:white;\" >\n";
			push @{$html{ $category }}, "<colgroup>\n";
			push @{$html{ $category }}, "<col width=90% />\n";
			push @{$html{ $category }}, "<col width=5% />\n";
			push @{$html{ $category }}, "<col width=5% />\n";
			push @{$html{ $category }}, "</colgroup>\n";
			push @popstack, "</table>\n";
		}
		push @{$html{ $category }}, "<tr>"
		. "<td>" . $question . "</td>"
		. "<td>" . $value . "</td>"
		. "<td><input type=\"radio\" name=\"" . sprintf( "s%d", $num_section ) . "\" value=\"" . $value . "\" /></td>"
		. "</tr>\n";
	}
	elsif( $function eq "lbullet" )
	{
		my $value = shift @parts;
		my $question = shift @parts;

		unless( $num_bullet++ )
		{
			push @{$html{ $category }}, "<table class=\"lbullet\" id=\"" 
				. sprintf( "s%d", $num_section ) 
				. "\" width=400px style=\"color:white;\" >\n";
			push @{$html{ $category }}, "<colgroup>\n";
			push @{$html{ $category }}, "<col width=5% />\n";
			push @{$html{ $category }}, "<col width=5% />\n";
			push @{$html{ $category }}, "<col width=90% />\n";
			push @{$html{ $category }}, "</colgroup>\n";
			push @popstack, "</table>\n";
		}
		push @{$html{ $category }}, 
		"<tr>"
		. "<td><input type=\"radio\" name=\"" . sprintf( "s%d", $num_section ) . "\" value=\"" . $value . "\" /></td>"
		. "<td>" . $value    . "</td>"
		. "<td>" . $question . "</td>"
		. "</tr>\n";
	}
	elsif( $function eq "category" )
	{
		my $id           = shift @parts;
		my $description  = shift @parts;
		my $total_points = shift @parts;
		my $extra        = shift @parts;

		$num_section = 0;

		if( $category ne "" )
		{
			# closure - close off the last catetory
			push @{$html{ $category }}, "<! ...closure... !>\n";
		}
		$category = $id;

		if( exists $html{ $category } )
		{
			print STDERR "Overloading (replacing) category $category\n";
			print OUT    "Overloading (replacing) category $category\n";
		}

		@{$html{ $category }} = ();

		# preamble
		push @{$html{ $category }}, 
			sprintf "<! category '%s' named '%s' points: %d [extra = '%s'] !>\n", 
			$category, 
			$description, 
			$total_points, 
			$extra;

		if( $extra =~ /^clone/ )
		{
			$extra =~ s/^\S+\s+//;
			if( ! exists $html{ $extra } )
			{
				printf STDERR "Cannot clone category '%s' (clones must follow definitions)\n", $extra;
				printf OUT    "Cannot clone category '%s' (clones must follow definitions)\n", $extra;
			}
			else
			{
				printf STDERR "Cloned '%s' to '%s'\n", $extra, $category;
				printf OUT    "Cloned '%s' to '%s'\n", $extra, $category;

				@{$html{ $category }} = @{$html{ $extra }};
				$category = "";		# preventing double closure
			}
			next;
		}
		else
		{
			next;
		}
	}
}

while( @popstack )	# cleanup of stack.
{
	my $element = pop @popstack;
	next if $element eq "{";
	push @{$html{ $category }} , "<! unbalanced stack !>" . $element;
}

print "<html>\n";
print "<head>\n";
print "<link href=\"sfjudge.css\" rel=\"stylesheet\" type=\"text/css\"/>\n";
print "</head>\n";
print "<body>\n";
print $faire_block;
print join "", @{$html{ "phys" }};
print "</body>\n";
print "</html>\n";

__DATA__
__END__
