#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Sub::Override;

my $pkg = 'Genome::Qc::Tool::Picard::MarkDuplicates';
use_ok($pkg);

my $data_dir = __FILE__.".d";

my $metrics_file = File::Spec->join($data_dir, 'output_file.txt');
my $temp_file = Genome::Sys->create_temp_file_path;

my $tool = $pkg->create(
    gmt_params => {
        input_file => $temp_file,
        metrics_file => $metrics_file,
        output_file => $temp_file,
        temp_directory => $temp_file,
        use_version => 1.123,
    }
);
ok($tool->isa($pkg), 'Tool created successfully');

# Value is different between workstations and blades
use Genome::Model::Tools::Picard::MarkDuplicates;
my $override = Sub::Override->new(
    'Genome::Model::Tools::Picard::MarkDuplicates::calculate_max_file_handles',
    sub {
        return 972;
    }
);

my @expected_cmd_line = (
    'java',
    '-Xmx4096m',
    '-XX:MaxPermSize=64m',
    '-cp',
    '/usr/share/java/ant.jar:/usr/share/java/picard-tools1.123/MarkDuplicates.jar',
    'picard.sam.markduplicates.MarkDuplicates',
    'ASSUME_SORTED=true',
    sprintf('INPUT=%s', $temp_file),
    'MAX_RECORDS_IN_RAM=500000',
    sprintf('METRICS_FILE=%s', $metrics_file),
    sprintf('OUTPUT=%s', $temp_file),
    'REMOVE_DUPLICATES=false',
    sprintf('TMP_DIR=%s', $temp_file),
    'VALIDATION_STRINGENCY=SILENT',
    'MAX_FILE_HANDLES=972',

);
is_deeply([$tool->cmd_line], [@expected_cmd_line], 'Command line list as expected');

my %expected_metrics = (
    'pct_duplicate_reads' => 0.005684,
    'number_of_optical_duplicates' => 0,
    'estimated_library_size' => 196212,
);
is_deeply({$tool->get_metrics}, {%expected_metrics}, 'Parsed metrics as expected');

$override->restore;

done_testing;
