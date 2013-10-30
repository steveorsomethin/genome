#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Test::Exception;

use Genome::Disk::Detail::Allocation::CreationParameters;


my $EXAMPLE_PARAMETERS = {
    kilobytes_requested => 1024,
    owner_class_name => 'UR::Value',
    owner_id => 'silly owner',
    allocation_path => 'foo/bar',
    disk_group_name => 'testing-disk-group',
    group_subdirectory => 'testing-dir',
};

subtest create_with_missing_required_param_fails => sub {
    plan tests => 1;

    my %params = %$EXAMPLE_PARAMETERS;

    delete $params{owner_id};
    dies_ok { Genome::Disk::Detail::Allocation::CreationParameters->create(
            %params);} 'dies with missing required params';
};

done_testing;
