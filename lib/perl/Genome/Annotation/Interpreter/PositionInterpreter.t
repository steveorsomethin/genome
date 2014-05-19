#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::Exception;
use Test::More;
use Genome::File::Vcf::Entry;

my $pkg = "Genome::Annotation::Interpreter::PositionInterpreter";
use_ok($pkg);

subtest "one alt allele" => sub {
    my $interpreter = $pkg->create();
    lives_ok(sub {$interpreter->validate}, "Interpreter validates");

    my %expected_return_values = (
        C => {
            chromosome_name => '1',
            start           => 10,
            stop            => 10,
            reference       => 'A',
            variant         => 'C'
        }
    );
    my $entry = create_entry();
    is_deeply({$interpreter->interpret_entry($entry, ['C'])}, \%expected_return_values, "Entry gets interpreted correctly");
};


subtest "two alt allele" => sub {
    my $interpreter = $pkg->create();
    lives_ok(sub {$interpreter->validate}, "Interpreter validates");

    my %expected_return_values = (
        C => {
            chromosome_name => '1',
            start           => 10,
            stop            => 10,
            reference       => 'A',
            variant         => 'C'
        },
        G => {
            chromosome_name => '1',
            start           => 10,
            stop            => 10,
            reference       => 'A',
            variant         => 'G'
        },
    );
    my $entry = create_entry();
    is_deeply({$interpreter->interpret_entry($entry, ['C', 'G'])}, \%expected_return_values, "Entry gets interpreted correctly");
};

sub create_vcf_header {
    my $header_txt = <<EOS;
##fileformat=VCFv4.1
##FILTER=<ID=PASS,Description="Passed all filters">
##FILTER=<ID=BAD,Description="This entry is bad and it should feel bad">
##INFO=<ID=A,Number=1,Type=String,Description="Info field A">
##INFO=<ID=C,Number=A,Type=String,Description="Info field C (per-alt)">
##INFO=<ID=E,Number=0,Type=Flag,Description="Info field E">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">
##FORMAT=<ID=FT,Number=.,Type=String,Description="Filter">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	S1	S2	S3	S4
EOS
    my @lines = split("\n", $header_txt);
    my $header = Genome::File::Vcf::Header->create(lines => \@lines);
    return $header
}

sub create_entry {
    my @fields = (
        '1',            # CHROM
        10,             # POS
        '.',            # ID
        'A',            # REF
        'C,G',            # ALT
        '10.3',         # QUAL
        'PASS',         # FILTER
        'A=B;C=8,9;E',  # INFO
        'GT:DP',     # FORMAT
        "0/1:12",   # FIRST_SAMPLE
    );

    my $entry_txt = join("\t", @fields);
    my $entry = Genome::File::Vcf::Entry->new(create_vcf_header(), $entry_txt);
    return $entry;
}

done_testing;