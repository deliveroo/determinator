require "spec_helper"

describe Determinator::Retrieve::Routemaster do
  let(:instance) { described_class.new(discovery_url: discovery_url) }
  let(:discovery_url) { 'https://flo.dev' }
  let(:routemaster) { double('routemaster') }
  let(:routemaster_app) { double('routemaster app') }
  let(:cache_redis) { double('redis') }

  before do
    allow_any_instance_of(::Routemaster::APIClient).to receive(:discover).and_return(routemaster)
    allow(::Routemaster::Drain::Caching).to receive(:new).and_return(routemaster_app)

    allow(::Routemaster::Config).to receive(:cache_redis).and_return(cache_redis)
    allow(cache_redis).to receive(:get).with("determinator_index:#{feature_id}").and_return(feature_id)
  end

  describe '#retrieve' do
    subject(:method_call) { instance.retrieve(feature_id) }
    let(:feature_name) { 'My Feature' }
    let(:feature_id) { feature_name.parameterize }
    let(:override) { { user_id: rand(100), variant: 'blue'} }

    let(:routemaster_scope) { double('routemaster scope') }

    shared_examples 'correctly parses Feature objects' do
      before do
        # Mocking routemaster
        allow(routemaster).to receive(:feature).and_return(routemaster_scope)
      end

      context 'when the request feature exists in Florence' do
        before do
          expect(routemaster_scope).to receive(:show).with(feature_id).and_return(hateoas_response)
        end

        it 'should collect the raw feature details from routemaster' do
          # expectation in before block
          method_call
        end

        it { should be_kind_of(Determinator::Feature) }

        its(:name) { should eq feature_name }
        its(:identifier) { should eq 'a' }
        its(:bucket_type) { should eq :id }
        its(:variants) { should eq('red' => 1, 'blue' => 1) }
        its(:overrides) { should eq(override[:user_id].to_s => override[:variant])}
        its(:target_groups) { should eq [
          Determinator::TargetGroup.new(
            rollout: 32_768,
            constraints: {}
          ),
          Determinator::TargetGroup.new(
            rollout: 1_000,
            constraints: {
              'country' => ['uk']
            }
          )
        ] }

        context "when given a cache retriver" do
          let(:instance) { described_class.new(discovery_url: discovery_url, retrieval_cache: cache_double) }
          let(:cache_double){ double('cache_double') }

          it "should call fetch, returning a routemaster object " do
            expect(cache_double).to receive(:fetch) { |&block| block.call }
            expect(subject).to be_kind_of(Determinator::Feature)
          end
        end
      end

      context "when the requested feature isn't present in Florence" do
        before do
          allow(routemaster_scope).to receive(:show).with(feature_id).and_raise(
            ::Routemaster::Errors::ResourceNotFound.new({})
          )
        end

        it { should be_nil }
      end
    end

    let(:hateoas_response) { Hashie::Mash.new(
      body: {
        id: feature_id,
        name: feature_name,
        identifier: 'a',
        bucket_type: 'id',
        active: true,
        target_groups: [
          {
            rollout: 32_768,
            constraints: {}
          },{
            rollout: 1_000,
            constraints: {
              country: 'uk'
            }
          }
        ],
        variants: {
          red: 1,
          blue: 1
        },
        overrides: {
          override[:user_id] => override[:variant]
        }
      }
    ) }

    include_examples 'correctly parses Feature objects'
  end
end
