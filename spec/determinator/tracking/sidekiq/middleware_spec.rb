require 'spec_helper'
require 'sidekiq/testing'
require 'determinator/tracking/sidekiq/middleware'

Sidekiq::Testing.server_middleware do |chain|
  chain.add Determinator::Tracking::Sidekiq::Middleware
end
Sidekiq::Testing.inline!

class TestWorker
  include Sidekiq::Worker

  def perform(arg)
    raise 'test error' if arg == 'error'
  end
end

describe Determinator::Tracking::Sidekiq::Middleware do
  after do
    Sidekiq::Worker.clear_all
  end

  describe '#call' do
    # it 'returns the status, headers and response' do
    #   expect(subject.call(env)).to eq([status, headers, response])
    # end

    context 'when reporting is enabled' do
      before do
        @test_request = nil
        Determinator::Tracking.on_request { |r| @test_request = r }
      end

      after do
        @test_request = nil
        Determinator::Tracking.clear_hooks!
      end

      it 'reports a request' do
        expect{ TestWorker.perform_async('foo') }.to change{ @test_request }
          .from(nil).to instance_of(Determinator::Tracking::Request)
      end

      it 'sets the error to false' do
        TestWorker.perform_async('foo')
        expect(@test_request.error).to eq(false)
      end

      it 'sets the status' do
        TestWorker.perform_async('foo')
        expect(@test_request.attributes[:queue]).to eq('default')
      end

      it 'sets the endpoint' do
        TestWorker.perform_async('foo')
        expect(@test_request.endpoint).to eq('TestWorker')
      end

      context 'when the request errors' do
        it 'sets the error to true' do
          TestWorker.perform_async('error') rescue nil
          expect(@test_request.error).to eq(true)
        end

        it 'raises the error' do
          expect { TestWorker.perform_async('error') }.to raise_error('test error')
        end
      end
    end
  end
end
