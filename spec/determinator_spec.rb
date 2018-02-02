require "spec_helper"

describe Determinator do
  describe '::VERSION' do
    subject { described_class::VERSION }

    it { should match(%r{\A\d+\.\d+\.\d+\z}) }
  end

  describe '::on_error and ::notice_error' do
    it 'sets the error logger callback' do
      error = StandardError.new "Some error"
      error_notified = false

      described_class.on_error do |err|
        error_notified = true if err == error
      end

      described_class.notice_error(error)
      expect(error_notified).to be true
    end
  end

  describe '::on_determination and ::notice_determination' do
    it 'sets the determination callback' do
      id = 'id'
      guid = 'guid'
      feature = FactoryGirl.create(:feature)
      determination = 'variant'

      determiantion_notified = false

      described_class.on_determination do |i, g, f, d|
        if i == id && g = guid && f == feature && d == determination
          determiantion_notified = true
        end
      end

      described_class.notice_determination(id, guid, feature, determination)
      expect(determiantion_notified).to be true
    end
  end
end
