require "spec_helper"
require 'determinator/retrieve/file'
require 'set'

describe Determinator::Control do
  context "determinator-standard-tests" do
    TESTS_WRITTEN_FOR = Gem::Dependency.new('determinator-standard-tests', '~> 1.1.6')
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

    context 'single bucketed, half rollout features should be on or off, randomly, for different calls' do
      let(:feature_name) { 'feature_flags/simple/half_rollout_single.json' }
      # standard deviations of confidence. 4 = 99.993; One in ~14k runs will be a false result
      let(:z) { 4 }
      # Acceptable error margin; 49/51 is acceptable as 50/50
      let(:e) { 0.01 }
      # n = Z^2 / 4 * E^2 (https://en.wikipedia.org/wiki/Checking_whether_a_coin_is_fair#Estimator_of_true_probability)
      let(:determinations) { ((z * z) / (4 * e * e)).ceil }
      # Given the number of determinations, what's the tolerable distance from exactly 50/50
      let(:leeway) { determinations * e }

      it 'should randomly give true or false results at different times' do
        totals = determinations.times.with_object({}) do |_, tots|
          outcome = determinator_instance.feature_flag_on?(feature_name)
          tots[outcome] ||= 0
          tots[outcome] += 1
        end

        expect(totals.keys).to contain_exactly(true, false)
        expect(totals[true]).to be_within(leeway).of(determinations / 2)
        expect(totals[false]).to be_within(leeway).of(determinations / 2)
      end
    end

    context 'with determination callback' do
      let(:callback) { double('callback') }

      before do
        determinator_instance.on_determination{ |name, args, determination| callback.call(name, args, determination) }
      end

      let(:feature_name) { 'feature_flags/simple/full_rollout_id.json' }

      it 'calls the callback' do
        expect(callback).to receive(:call).with(feature_name, hash_including(id: 1, properties: {a: 'b'}), true)
        outcome = determinator_instance.feature_flag_on?(feature_name, id: 1, properties: {a: 'b'})
        expect(outcome).to eq(true)
      end

      context 'missing feature' do
        let(:feature_name) { 'missing' }

        before do
          allow(error_logger).to receive(:call)
        end

        it 'calls the callback with the false outcome' do
          expect(callback).to receive(:call).with(feature_name, hash_including(id: 1, properties: {a: 'b'}), false)
          outcome = determinator_instance.feature_flag_on?(feature_name, id: 1, properties: {a: 'b'})
          expect(outcome).to eq(false)
        end
      end
    end
  end
end
