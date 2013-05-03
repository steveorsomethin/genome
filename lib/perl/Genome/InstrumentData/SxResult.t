#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
    $ENV{NO_LSF} = 1;
};

require File::Compare;
use Test::More;

use above 'Genome';

use_ok('Genome::InstrumentData::SxResult');
use_ok('Genome::InstrumentData::InstrumentDataTestObjGenerator');

my $data_dir = $ENV{GENOME_TEST_INPUTS} . '/Genome-InstrumentData-SxResult';

my ($instrument_data) = Genome::InstrumentData::InstrumentDataTestObjGenerator::create_solexa_instrument_data($data_dir.'/inst_data/-6666/archive.bam');
my $read_processor = '';
my $output_file_count = 2;
my $output_file_type = 'sanger';

my %sx_result_params = (
    instrument_data_id => $instrument_data->id,
    read_processor => $read_processor,
    output_file_count => $output_file_count,
    output_file_type => $output_file_type,
    test_name => ($ENV{GENOME_SOFTWARE_RESULT_TEST_NAME} || undef),
);

my $sx_result = Genome::InstrumentData::SxResult->get_or_create(%sx_result_params);
isa_ok($sx_result, 'Genome::InstrumentData::SxResult', 'successful run');
my $get_sx_result = Genome::InstrumentData::SxResult->get(%sx_result_params);
is_deeply($get_sx_result, $sx_result, 'Re-got sx reult');

my @read_processor_output_files = $sx_result->read_processor_output_files;
ok(@read_processor_output_files, 'produced read processor output files');
is_deeply(\@read_processor_output_files, [map { $instrument_data->id.'.'.$_.'.fastq' } (qw/ 1 2 /)], 'correctly names read processor output files');

my $read_processor_output_metric_file = $sx_result->read_processor_output_metric_file;
my $read_processor_input_metric_file = $sx_result->read_processor_input_metric_file;
ok($read_processor_output_metric_file, 'produced read processor output metric file');
ok($read_processor_input_metric_file, 'produced read processor input metric file');

$sx_result_params{output_file_count} = 1;
my $sx_result3 = Genome::InstrumentData::SxResult->get_with_lock(%sx_result_params);
ok(!$sx_result3, 'request with different (yet unrun) parameters returns no result');

my $sx_result4 = Genome::InstrumentData::SxResult->get_or_create(%sx_result_params);
isa_ok($sx_result4, 'Genome::InstrumentData::SxResult', 'successful run');
isnt($sx_result4, $sx_result, 'produced different result');

# use output file config [should be same output as above]
my %sx_result_params_with_config = (
    instrument_data_id => $instrument_data->id,
    read_processor => $read_processor,
    output_file_config => [ 
        'basename='.$instrument_data->id.'.1.fastq:type=sanger:name=fwd', 'basename='.$instrument_data->id.'.2.fastq:type=sanger:name=rev',
    ],
    test_name => ($ENV{GENOME_SOFTWARE_RESULT_TEST_NAME} || undef),
);

my $sx_result_with_config = Genome::InstrumentData::SxResult->get_or_create(%sx_result_params_with_config);
isa_ok($sx_result_with_config, 'Genome::InstrumentData::SxResult', 'successful run w/ config');
my $get_sx_result_with_config = Genome::InstrumentData::SxResult->get(%sx_result_params_with_config);
is_deeply($get_sx_result_with_config, $sx_result_with_config, 'Re-got sx result w/ config');
isnt($get_sx_result_with_config->output_dir, $sx_result->output_dir, 'Output dirs do not match b/c we reran SX');
my @output_files = $sx_result->read_processor_output_files;
ok(@output_files, 'produced read processor output files w/ config');
for ( my $i = 0; $i < @read_processor_output_files; $i++ ) {
    is($output_files[$i], $read_processor_output_files[$i], 'correctly named read processor output files');
    is(
        File::Compare::compare($sx_result_with_config->output_dir.'/'.$output_files[$i], $sx_result->output_dir.'/'.$read_processor_output_files[$i]),
        0,
        "Output file $i matches!",
    );
}

# fails
ok( # no config or count
    !Genome::InstrumentData::SxResult->create(
        instrument_data_id => $instrument_data->id,
        read_processor => $read_processor,
    ),
    'Did not create sx result w/ config w/o basename',
);
ok( # no basename in output file config
    !Genome::InstrumentData::SxResult->create(
        instrument_data_id => $instrument_data->id,
        read_processor => $read_processor,
        output_file_config => [ 'type=sanger' ],
    ),
    'Did not create sx result w/ config w/o basename',
);
ok( # invalid basename in output file config
    !Genome::InstrumentData::SxResult->create(
        instrument_data_id => $instrument_data->id,
        read_processor => $read_processor,
        output_file_config => [ 'basename=/carter:type=sanger' ],
    ),
    'Did not create sx result w/ config w/o basename',
);
ok( # invalid basename in output file config
    !Genome::InstrumentData::SxResult->create(
        instrument_data_id => $instrument_data->id,
        read_processor => $read_processor,
        output_file_config => [ 'basename=johnny cash:type=sanger' ],
    ),
    'Did not create sx result w/ config w/o basename',
);
ok( # no type in output file config
    !Genome::InstrumentData::SxResult->create(
        instrument_data_id => $instrument_data->id,
        read_processor => $read_processor,
        output_file_config => [ 'basename=carter' ],
    ),
    'Did not create sx result w/ config w/o basename',
);

done_testing;
