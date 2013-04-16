#! /usr/bin/perl -w
use locale;
use Encode;

# Read a dictionary-based list of wordforms
%correct = ();
open (FILEIN, "<wforms_full.txt");
while (<FILEIN>)
	{
	chomp;
	++$correct{$_};
	}
close (FILEIN);

# Read a hand-crafted list of substitutions
%subst = ();
open (FILEIN, "<substitution.txt");
while (<FILEIN>)
	{
	chomp;
	($old, $new) = split (/\t/, $_);
	$subst{$old} = $new;
	}
close (FILEIN);

%seen = ();
$current_dir = "./t/";
opendir (INPUT, $current_dir) or die "No such directory: $current_dir";
while (defined ($handle = readdir(INPUT)))
	{
	unless ($handle =~ /^\.{1,2}$/)
		{
		print "Working on $handle...\n";
		$inhandle = $current_dir . $handle;
		@contents = ();
		open (FILEIN, "<$inhandle");
		while (<FILEIN>)
			{
			chomp;
			push @contents, $_;
			}
		close (FILEIN);
		for $i (0..$#contents-1)
			{
			if (length($contents[$i]) > 1 && length($contents[$i+1]) > 1 && !$correct{lc($contents[$i])} && !$correct{lc($contents[$i])})
				{
				$hyp = $contents[$i] . $contents[$i+1];
				($a1, $a2) = (lc($hyp), lc($hyp));
				$a2 =~ s/^�/�/g;
				# Case 1: the wordform is known (or is an integer)
				if (($correct{$hyp}) or ($correct{$a1}) or ($correct{$a2}))
					{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $hyp}; }
				# Case 2: the wordform can be substituted for something known
				elsif ($subst{lc($hyp)})
					{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $subst{lc($hyp)}}; }
				elsif ($subst{$hyp})
					{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $subst{$hyp}}; }
				else
					{
					$hyp = refine($hyp);
					# Case 3: refined wordform is known
					if (($correct{$hyp}) or ($correct{lc($hyp)}))
						{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $hyp}; }
					# Case 4: refined wordform can be substituted for something known
					elsif ($subst{lc($hyp)})
						{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $subst{lc($hyp)}}; }
					elsif ($subst{$hyp})
						{ ++$seen{$contents[$i] . "\t" . $contents[$i+1] . "\t" . $subst{$hyp}}; }
					}
				}
			}
		}
	}

open (FILEOUT, ">glue.txt");
foreach (keys %seen) { print FILEOUT "$_\t$seen{$_}\n"; }
close (FILEOUT);

##################################

sub refine
	{
	$s = shift @_;

	# � => �
	$s =~ s/(�|�)�(�|�|�)/$1�$2/g;
	$s =~ s/�(�|�)/�$1/g;
	$s =~ s/����/����/g;

	# � => �
	$s =~ s/��/��/g;

	# � <=> �, �
	$s =~ s/���/���/g;
	$s =~ s/(�|�|�)��/$1��/g;
	$s =~ s/�(�|��)/�$1/g;
	$s =~ s/���/���/g;
	$s =~ s/���$/���/g;
	$s =~ s/���(�|�)/���$1/g;
	$s =~ s/����/����/g;
	$s =~ s/����/����/g;
	$s =~ s/���/���/g;

	# � => �, �
	$s =~ s/(�|�|�)�/$1�/g;
	$s =~ s/��(�|�)/��$1/g;
	$s =~ s/��(�|�|�)/��$1/g;
	$s =~ s/���(�|�)/��$1/g;

	# �� => several letters
	$s =~ s/���/��/g;
	$s =~ s/^���/��/g;
	$s =~ s/�񳳳/����/g;

	# � => �
	$s =~ s/���/���/g;
	$s =~ s/��(�|�|�|�)/��$1/g;
	$s =~ s/��(�|�|�)/��$1/g;
	$s =~ s/�\'(�|�)/�\'$1/g;
	$s =~ s/��(�|�|�|�|�)/��$1/g;
	$s =~ s/(^|[�������])��(�|�|�|�|�)/$1��$2/g;
	$s =~ s/��(�|�)/���/g;
	$s =~ s/\'��/'��/g;

	# varia
	$s =~ s/��/�/g;
	$s =~ s/����/�����/ig;
	$s =~ s/���/���/g;
	$s =~ s/^����(�|�)/����$1/g;
	$s =~ s/^����(�|�|�|��)/����$1/g;
	$s =~ s/�����/�����/g;
	$s =~ s/\-//g;

	return $s;
	}