#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
};

use above "Genome";

use Test::Exception;
use Test::More;

my $class = 'Genome::InstrumentData::Command::Import::WorkFlow::Inputs';
use_ok($class) or die;

my @source_files = (qw/ in.1.fastq in.2.fastq /);
my $original_data_path = join(',', @source_files);
my $inputs = $class->create(
    source_files => $original_data_path,
    description => 'imported',
    instrument_data_properties => [qw/ 
        downsample_ratio=0.7
        import_source_name=TGI
        this=that
    /],
);
ok($inputs, 'create inputs');

my %instrument_data_properties = (
    downsample_ratio => 0.7,
    description => 'imported',
    import_source_name => 'TGI',
    original_data_path => $original_data_path,
    this => 'that', 
);
is_deeply(
    $inputs->for_worklflow,
    {
        source_files => \@source_files,
        instrument_data_properties => \%instrument_data_properties,
    },
    'for_worklflow',
);
is_deeply( $inputs->source_files, \@source_files, 'source_files');
is_deeply(
    $inputs->instrument_data_properties,
    \%instrument_data_properties,
    'instrument_data_properties',
);

# ERRORS
throws_ok(
    sub { $class->create(); },
    qr/No source files\!/,
    "create failed w/o source files",
);

throws_ok(
    sub {
        $class->create(
            source_files => 'in.bam',
            instrument_data_properties => [qw/ foo=bar foo=baz /],
        );
    },
    qr/Multiple values for instrument data property! foo => bar, baz/,
    "execute failed w/ duplicate key, diff value for instdata properties",
);

throws_ok(
    sub {
        $class->create(
            source_files => 'in.bam',
            description => 'imported',
            instrument_data_properties => [qw/ description=inported /],
        );
    },
    qr/Multiple values for instrument data property! description => imported, inported/,
    "execute failed w/ duplicate key, diff value for description",
);

throws_ok(
    sub{
        $class->create(
            source_files => 'in.bam',
            instrument_data_properties => [qw/ 
            description=
            /],
        );
    },
    qr#Failed to parse with instrument data property label/value! description=#,
    "execute failes w/ missing value",
);

done_testing();
