require 'spec_helper'
require 'determinator/retrieve/file'

RSpec.describe Determinator::Retrieve::File do
  let(:described_instance) { described_class.new(root: dir) }
  let(:dir) { @temp_dir }
  let(:feature_id) { 'feature_1' }
  let(:feature_json) {{
    name: "Feature one",
    identifier: "feature",
    bucket_type: "id",
    target_groups: [{
      rollout: 65536,
      constraints: {}
    }],
    active: true,
    overrides: {}
  }}

  around do |test|
    Determinator.on_error { |e| raise e }

    Dir.mktmpdir do |dir|
      @temp_dir = dir
      path = File.join(dir, feature_id)
      File.open(path, 'w') do |f|
        f.write feature_json.to_json
      end
      test.run
    end
  end

  describe '#retrieve' do
    subject(:described_method) { described_instance.retrieve(feature_id) }

    it { should be_a Determinator::Feature }
    its(:name) { should eq 'Feature one' }
    its(:identifier) { should eq 'feature' }
    its(:bucket_type) { should eq :id }
    its(:target_groups) { should eq [ Determinator::TargetGroup.new(rollout: 65536) ] }
    its(:active) { should eq true }
    its(:overrides) { should be_empty }
  end
end