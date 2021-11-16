require 'determinator/retrieve/http_retriever'
require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Determinator::Retrieve::HttpRetriever do
  let(:client) {
    Faraday.new(base_url)
  }
  let(:base_url) { 'http://actortracking.dev' }
  let(:service_name) { 'MY-SERVICE' }
  let(:feature_id) { 'some-feature' }
  let(:feature_json) { {
    name: "Feature one",
    identifier: "feature",
    bucket_type: "id",
    structured_bucket: "request.customer.guid",
    target_groups: [{
                      rollout: 65536,
                      constraints: {}
                    }],
    active: true,
    overrides: {}
  } }
  let(:expected_url) { "#{base_url}/features/#{feature_id}" }

  describe '#retrieve' do
    subject(:retrieve) { described_class.new(params).retrieve(feature_id) }

    context 'when client is injected' do
      let(:params) { { connection: client } }

      context 'when the client is a Faraday connection' do
        include_examples 'retrieve tests'
      end

      context 'when the client is not a Faraday connection' do
        let(:client) { 'CLIENT' }

        it 'raises an ArgumentError' do
          expect { retrieve }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'hooks' do
    subject { described_class.new(params) }
    let(:retrieve) { subject.retrieve(feature_id) }

    context 'when use before hook' do
      let(:foo_bar) { double('FooBar') }
      let(:params) { { connection: client } }

      before :each do
        allow(foo_bar).to receive(:some_method).and_return(true)

        allow(Determinator).to receive(:notice_error)
        stub_request(:get, expected_url).
          to_return(status: 200, body: feature_json.to_json)
      end

      it 'runs block in retrieve' do
        expect(foo_bar).to receive(:some_method).once
        subject.before_retrieve do
          foo_bar.some_method
        end
        retrieve
      end

      it 'does not run block if retrieve is not called' do
        expect(foo_bar).not_to receive(:some_method)
        subject.before_retrieve do
          foo_bar.some_method
        end
        subject
      end
    end

    context 'when use after hook' do
      let(:foo_bar) { double('FooBar') }
      let(:params) { { connection: client } }

      before :each do
        allow(foo_bar).to receive(:some_method).and_return(true)

        allow(Determinator).to receive(:notice_error)
      end

      context 'when success response' do
        before :each do
          stub_request(:get, expected_url).
            to_return(status: 200, body: feature_json.to_json)
        end

        it 'runs block in retrieve and returns 200 status' do
          expect(foo_bar).to receive(:some_method).once
          subject.after_retrieve do |res, err|
            foo_bar.some_method
            expect(res).to eq 200
            expect(err).to be_nil
          end
          retrieve
        end
      end

      context 'when response has 404 status' do
        before :each do
          stub_request(:get, expected_url).
            to_return(status: 404, body: feature_json.to_json)
        end

        it 'runs block in retrieve and return 404 status' do
          expect(foo_bar).to receive(:some_method).once
          subject.after_retrieve do |res, err|
            foo_bar.some_method
            expect(res).to eq 404
            expect(err).to be_nil
          end
          retrieve
        end
      end

      context 'when response failed' do
        before :each do
          allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(StandardError)
        end

        it 'runs block in retrieve and return 500 status' do
          expect(foo_bar).to receive(:some_method).once
          subject.after_retrieve do |res, err|
            foo_bar.some_method
            expect(res).to eq 500
            expect(err).to be_instance_of(StandardError)
          end
          retrieve
        end

        it 'does not raise error' do
          expect { retrieve }.not_to raise_error
        end
      end

      it 'does not run block if retrieve is not called' do
        expect(foo_bar).not_to receive(:some_method)
        subject.after_retrieve do |res|
          foo_bar.some_method
        end
        subject
      end
    end
  end
end
