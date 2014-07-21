#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use above 'Genome';
use Test::Exception;
use Test::More;
use Genome::VariantReporting::BamReadcount::TestHelper qw(bam_readcount_line create_entry
    bam_readcount_line_deletion create_deletion_entry);

my $pkg = 'Genome::VariantReporting::BamReadcount::MinCoverageObservedInterpreter';
use_ok($pkg);
my $factory = Genome::VariantReporting::Framework::Factory->create();
isa_ok($factory->get_class('interpreters', $pkg->name), $pkg);

my $interpreter = $pkg->create(sample_names => ["S1", "S2", "S3"]);
lives_ok(sub {$interpreter->validate}, "Filter validates");
my $entry = create_entry(bam_readcount_line);

subtest 'all alt alleles' => sub {
    my %expected_return_values = (
        G => {
            min_coverage_observed =>  3,
        },
        C => {
            min_coverage_observed =>  1,
        },
        AA => {
            min_coverage_observed =>  3,
        },
    );

    is_deeply({$interpreter->interpret_entry($entry, ['G', 'C', 'AA'] )}, \%expected_return_values, "Entry gets interpreted correctly");
};

done_testing();
