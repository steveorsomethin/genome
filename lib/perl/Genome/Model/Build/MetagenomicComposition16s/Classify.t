#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
}

use strict;
use warnings;

use above 'Genome';

use Test::More;

use_ok('Genome::Model::Build::MetagenomicComposition16s::Classify') or die;

use_ok('Genome::Model::Build::MetagenomicComposition16s::TestBuildFactory') or die;
my ($build, $example_build) = Genome::Model::Build::MetagenomicComposition16s::TestBuildFactory->build_with_example_build_for_454;
ok($build && $example_build, 'Got build and example_build');

my @amplicon_sets = $build->amplicon_sets;
my @example_amplicon_sets = $example_build->amplicon_sets;
ok(@amplicon_sets && @example_amplicon_sets, 'Got amplicon sets');
for ( my $i = 0; $i < @example_amplicon_sets; $i++ ) {
    for my $file_name (qw/ processed_fasta_file processed_qual_file /) {
        my $file = $example_amplicon_sets[$i]->$file_name;
        die "File ($file_name: $file) does not exist!" if not -s $file;
        Genome::Sys->create_symlink($file, $amplicon_sets[$i]->$file_name);
    }
}
$build->amplicons_attempted(20);

my $cmd = Genome::Model::Build::MetagenomicComposition16s::Classify->create(build => $build);
ok($cmd, 'create classify cmd');
ok($cmd->execute, 'execute classify cmd');

is($build->amplicons_processed, 14, 'amplicons processed');
is($build->amplicons_processed_success, '0.70', 'amplicons processed success');
$build->amplicons_processed_success('0.70');
is($build->amplicons_classified, $build->amplicons_processed, 'amplicons classified matches processed: '.$build->amplicons_processed);
is($build->amplicons_classified_success, '1.00', 'amplicons classified success is 1.00');
is($build->amplicons_classification_error, 0, 'amplicons classified error is 0');

for ( my $i = 0; $i < @amplicon_sets; $i++ ) { 
    my $set_name = $amplicon_sets[$i]->name;
    is($set_name, $example_amplicon_sets[$i]->name, "set name: $set_name");
    my $diff_ok = Genome::Model::Build::MetagenomicComposition16s->diff_rdp(
        $example_amplicon_sets[$i]->classification_file,
        $amplicon_sets[$i]->classification_file,
    );
    ok($diff_ok, 'diff classification files');
    my $amplicons = $amplicon_sets[$i]->amplicon_iterator;
    my $example_amplicons = $example_amplicon_sets[$i]->amplicon_iterator;
    while ( my $amplicon = $amplicons->() ) {
        my $example_amplicon = $example_amplicons->();
        is($amplicon->{name}, $example_amplicon->{name}, 'matches example amplicon');
        ok($amplicon->{classification}, $amplicon->{name}.' has a classification');
        is_deeply([@{$amplicon->{classification}}[0..3]], [@{$example_amplicon->{classification}}[0..3]], 'classification matches');
    }
}

#print $build->data_directory."\n"; <STDIN>;
done_testing();
exit;


