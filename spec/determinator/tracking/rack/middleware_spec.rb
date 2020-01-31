require 'spec_helper'
require 'determinator/tracking/rack/middleware'

describe Determinator::Tracking::Rack::Middleware do
  let(:status) { 200 }
  let(:headers) { {} }
  let(:response) { 'foo' }
  let(:app) { double(call: [status, headers, response]) }
  let(:env) { double }
  let(:subject) { described_class.new(app) }

  describe '#call' do
    it 'returns the status, headers and response' do
      expect(subject.call(env)).to eq([status, headers, response])
    end
    context 'when reporting is enabled' do
      before do
        $_test_request = nil
        Determinator::Tracking.on_request{ |r| $_test_request = r }
      end

      after do
        $_test_request = nil
        Determinator::Tracking.clear_hooks!
      end

      it 'reports a request' do
        expect{ subject.call(env) }.to change{ $_test_request }
          .from(nil).to instance_of(Determinator::Tracking::Request)
      end

      it 'sets the error to false' do
        subject.call(env)
        expect($_test_request.error).to eq(false)
      end

      it 'sets the status' do
        subject.call(env)
        expect($_test_request.attributes[:status]).to eq(status)
      end

      context 'when the request errors' do
        before do
          allow(app).to receive(:call).and_raise
        end

        it 'sets the error to true' do
          subject.call(env) rescue nil
          expect($_test_request.error).to eq(true)
        end

        it 'raises the error' do
          expect { subject.call(env) }.to raise_error
        end
      end
    end
  end
end
