require "spec_helper"
require 'determinator/explainer'

describe Determinator::Explainer do
  let(:instance) { described_class.new }

  describe 'explain' do
    let(:block_outcome) { true }
    let(:perform) { instance.explain { block_outcome } }

    it 'executes block and returns hash of outcome and explanation' do
      expect(perform).to eq({outcome: block_outcome, explanation: []})
    end

    it 'leaves enabled flag in a disabled state on completion' do
      expect { perform }.to_not change { instance.enabled }
    end

    context 'with logs' do
      let(:feature) { FactoryBot.build(:feature) }
      let(:log_statement) { instance.log(:start, { feature: feature }) }
      let(:perform) { instance.explain { log_statement } }

      it 'returns explanation logs within explanation' do
        expect(perform[:explanation].first[:type]).to eq(:start)
      end

      it 'leaves logs in a clean state on completion' do
        expect { perform }.to_not change { instance.logs.length }
      end
    end
  end

  describe 'log' do
    let(:feature) { FactoryBot.build(:feature) }
    let(:perform) { instance.log(:start, { feature: feature }) }

    before do
      instance.enabled = true
    end

    it 'updates logs' do
      expect { perform }.to change { instance.logs.length }.by(1)
    end

    context 'with block' do
      let(:block_outcome) { true }
      let(:perform) { instance.log(:start, { feature: feature }) { block_outcome } }

      it 'yields block and returns result' do
        expect(perform).to eq(block_outcome)
      end

      it 'updates logs' do
        expect { perform }.to change { instance.logs.length }.by(1)
      end
    end
  end
end
