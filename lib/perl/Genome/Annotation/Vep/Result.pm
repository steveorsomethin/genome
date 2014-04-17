package Genome::Annotation::Vep::Result;

use strict;
use warnings FATAL => 'all';
use Genome;
use Sys::Hostname;

class Genome::Annotation::Vep::Result {
    is => 'Genome::Annotation::Detail::Result',
    has_input => [
        ensembl_version => {
            is => 'String',
        },
        feature_list_ids_and_tags => {
            is => 'String',
            is_many => 1,
        },
        input_result => {
            is => 'Genome::SoftwareResult',
        },
        species => {
            is => 'String',
        },
    ],
    has_param => [
        variant_type => { is => 'Text', },
        polyphen => { is => 'String', },
        sift => { is => 'String', },
        condel => { is => 'String', },
        terms => {is => 'String', },
        regulatory => {is => 'Boolean',},
        gene => {is => 'Boolean',},
        most_severe => {is => 'Boolean',},
        per_gene => {is => 'Boolean',},
        hgnc => {is => 'Boolean',},
        coding_only => {is => 'Boolean',},
        canonical => {is => 'Boolean',},
        plugins => {is => 'String',
                    is_many => 1},
        plugins_version => {is => 'String',},
    ],
};

sub output_filename {
    return 'vep.vcf';
}

sub _run {
    my $self = shift;

    my @custom_annotation_inputs;
    for my $feature_list_and_tag ($self->feature_list_ids_and_tags) {
        my ($id, $tag) = split(":", $feature_list_and_tag);
        my $feature_list = Genome::FeatureList->get($id);
        push @custom_annotation_inputs, join("@",
            $feature_list->get_tabix_and_gzipped_bed_file,
            $tag,
            "bed",
            "overlap",
            "0",
        );
    }

    my %params = $self->param_hash;
    delete $params{variant_type};
    delete $params{test_name};

    my $vep_command = Genome::Db::Ensembl::Command::Run::Vep->create(
        input_file => $self->input_result->output_file_path,
        output_file => File::Spec->join($self->temp_staging_directory, $self->output_filename),
        ensembl_version => $self->ensembl_version,
        custom => \@custom_annotation_inputs,
        format => "vcf",
        vcf => 1,
        quiet => 0,
        %params,
    );

    unless ($vep_command->execute) {
        die $self->error_message("Failed to execute vep");
    }

    return;
}