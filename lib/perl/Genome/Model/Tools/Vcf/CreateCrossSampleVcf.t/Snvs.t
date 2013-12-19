#!/usr/bin/env genome-perl

use strict;
use warnings;

use above 'Genome';
use Test::More;
use Genome::Model::Tools::Vcf::CreateCrossSampleVcf::TestHelpers qw(
    test_cmd
);

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{NO_LSF} = 1;
};

my $VERSION = 'snvs-2';
my $use_mg = 0;
test_cmd('snvs', $VERSION, $use_mg);

done_testing();
