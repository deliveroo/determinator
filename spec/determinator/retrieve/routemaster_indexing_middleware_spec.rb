require "spec_helper"

describe Determinator::Retrieve::RoutemasterIndexingMiddleware do
  let(:instance) { described_class.new(app) }
  let(:app) { double 'app' }
  let(:redis) { double 'redis' }

  EnvStruct = Struct.new(:body)

  before do
    allow(::Routemaster::Config).to receive(:cache_redis).and_return(redis)
    allow(app).to receive(:call)
  end

  describe '#call' do
    subject(:method_call) { instance.call(env) }

    context 'when called with a non-feature in the body' do
      let(:env) { EnvStruct.new({ '_links': {} }.to_json) }

      it 'should call the next app in the middleware chain' do
        expect(app).to receive(:call).with(env)
        method_call
      end

      it 'should not interact with redis' do
        expect(redis).to_not receive(:set)
        method_call
      end
    end

    context 'when called with a feature in the body' do
      let(:env) { EnvStruct.new({
        id: 1,
        name: feature_name,
        bucket_type: :id
      }.to_json) }
      let(:feature_id) { 1 }
      let(:feature_name) { 'my_name' }

      it 'should call the next app in the middleware chain' do
        allow(redis).to receive(:set)
        expect(app).to receive(:call).with(env)
        method_call
      end

      it 'should store the feature name to id lookup in redis' do
        expect(redis).to receive(:set).with(
          "determinator_index:#{feature_name}",
          feature_id
        )
        method_call
      end
    end
  end
end
