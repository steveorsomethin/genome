#!/usr/bin/env genome-perl
use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above 'Genome';
use Genome::Test::Factory::SoftwareResult::User;
use Test::More;

my $class = "Genome::Model::RnaSeq::DetectFusionsResult::Chimerascan::FixedReadLength::Index";
use_ok($class);

my $data_dir = Genome::Config::get('test_inputs')."/Genome-Model-RnaSeq-DetectFusionsResult-ChimerascanResult-Index/v2";

my $reference_model = Genome::Model::ImportedReferenceSequence->create(
    name => '1 chr test model',
    subject => Genome::Taxon->get(name => 'human'),
    processing_profile => Genome::ProcessingProfile->get(name => 'chromosome-fastas'),
);

my $reference_build = Genome::Model::Build::ImportedReferenceSequence->create(
    model => $reference_model,
    fasta_file => $data_dir . "/all_sequences.fa",
    data_directory => $data_dir,
    version => '37'
);

my $result_users = Genome::Test::Factory::SoftwareResult::User->setup_user_hash(
    reference_sequence_build => $reference_build,
);

my $annotation_model = Genome::Model::ImportedAnnotation->create(
    name => '1 chr test annotation',
    subject => $reference_model->subject,
    processing_profile => Genome::ProcessingProfile->get(name => 'imported-annotation.ensembl'),
    reference_sequence => $reference_build,
);

my $annotation_build = Genome::Model::Build::ImportedAnnotation->__define__(
    version => 'v1',
    model => $annotation_model,
    data_directory => '/gscmnt/ams1180/info/model_data/2772828715/build131029280',
);

#hack to shorten results
my $tx_sub = $annotation_build->can('transcript_iterator');
no warnings qw(redefine once);
*Genome::Model::Build::ImportedAnnotation::transcript_iterator = sub {
    my $self = shift;
    my %p = @_;
    $p{chrom_name} = 'GL000191.1';
    $self->warning_message('Transcript Iterator hardcoded to chromosome ' . $p{chrom_name} . ' for test.');
    return $tx_sub->($self, %p);
};
use warnings qw(redefine);

my $result = $class->get_or_create(
    version => "0.4.3",
    bowtie_version => "0.12.5",
    reference_build => $reference_build,
    annotation_build => $annotation_build,
    picard_version => 1.82,
    users => $result_users,
);

isa_ok($result, $class);

done_testing();

1;
