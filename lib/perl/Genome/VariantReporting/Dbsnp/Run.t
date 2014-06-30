#!/usr/bin/env genome-perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above "Genome";
use Sub::Install;
use Genome::Test::Factory::Model::ImportedVariationList;
use Genome::Test::Factory::Build;
use Genome::Model::Tools::DetectVariants2::Result::Vcf;
use Genome::Model::Tools::Sam::Readcount;
use Genome::Model::Tools::Bed::Convert::VcfToBed;
use Genome::VariantReporting::TestHelpers qw(test_cmd_and_result_are_in_sync);

use Test::More;

my $cmd_class = 'Genome::VariantReporting::Dbsnp::Run';
use_ok($cmd_class) or die;

my $factory = Genome::VariantReporting::Factory->create();
isa_ok($factory->get_class('runners', $cmd_class->name), $cmd_class);

my $result_class = 'Genome::VariantReporting::Dbsnp::RunResult';
use_ok($result_class) or die;

use_ok('Genome::Model::Tools::Joinx::VcfAnnotate') or die;

my $cmd = generate_test_cmd();
ok($cmd->execute(), 'Command executed');
is(ref($cmd->output_result), $result_class, 'Found software result after execution');

test_cmd_and_result_are_in_sync($cmd);

done_testing();

sub generate_test_cmd {
    Sub::Install::reinstall_sub({
        into => 'Genome::Model::Tools::Joinx::VcfAnnotate',
        as => 'execute',
        code => sub {my $self = shift; my $file = $self->output_file; `touch $file`; return 1;},
    });

    my $input_result = $result_class->__define__();
    Sub::Install::reinstall_sub({
        into => 'Genome::VariantReporting::Component::Expert::Result',
        as => 'output_file_path',
        code => sub {return 'some_file.vcf.gz';},
    });

    my $model = Genome::Test::Factory::Model::ImportedVariationList->setup_object();
    my $known_variants = Genome::Test::Factory::Build->setup_object(model_id => $model->id);
    Sub::Install::reinstall_sub({
        into => 'Genome::Model::Build::ImportedVariationList',
        as => 'snvs_vcf',
        code => sub {return 1},
    });
    my %params = (
        input_result => $input_result,
        known_variants  => $known_variants,
        variant_type     => 'snvs',
        info_string      => 'test',
        joinx_version          => '1.8',
    );

    my $cmd = $cmd_class->create(%params);
    return $cmd
}