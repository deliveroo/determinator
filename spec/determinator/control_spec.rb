require "spec_helper"
require 'determinator/retrieve/file'

describe Determinator::Control do
  context "determinator-standard-tests" do
    TESTS_WRITTEN_FOR = Gem::Dependency.new('determinator-standard-tests', '~> 0.1')
    STANDARDS_DIR = Pathname.new('spec/standard_cases')

    subject(:determinator_instance) do
      Determinator.on_error { |e| error_logger.call(e) }
      described_class.new(retrieval: test_files)
    end

    let(:error_logger) { double('error_logger') }
    let(:test_files) { Determinator::Retrieve::File.new(root: STANDARDS_DIR) }
    let(:standards_version) { STANDARDS_DIR.join('VERSION').read }

    it 'should be the expected major version for tests to work' do
      expect(TESTS_WRITTEN_FOR).to be_match('determinator-standard-tests', standards_version)
    end

    begin
      sections = JSON.parse(STANDARDS_DIR.join('examples.json').read)
    rescue Errno::ENOENT
      abort "Please run `git submodule update --init` to grab the Determinator Standard Tests"
    end

    def execute(example)
      feature = test_files.retrieve(example['feature'])
      method = feature.feature_flag? ? :feature_flag_on? : :which_variant

      determinator_instance.send(method,
        example['feature'],
        id: example['id'],
        guid: example['guid'],
        properties: example['properties']
      )
    end

    sections.each do |section|
      context section['section'] do
        section['examples'].each do |example|
          it example['why'] do
            if example.key?('returns')
              expect(error_logger).to receive(:call).with(StandardError).at_least(:once) if example['error']
              expect(execute(example)).to eq(example['returns'])
            else
              expect { execute(example) }.to raise_error StandardError
            end
          end
        end
      end
    end
  end
end
