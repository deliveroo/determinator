require 'determinator/explainer/messages'

module Determinator
  class Explainer
    attr_accessor :enabled
    attr_reader :logs

    def initialize
      @logs  = []
      @enabled = false
    end

    def explain
      @enabled = true
      { outcome: yield, explanation: @logs }
    ensure
      @logs = []
      @enabled = false
    end

    def log(type, args = {})
      result = block_given? ? yield : nil

      return result unless @enabled

      result.tap do |r|
        add(type, r, args)
      end
    end

    private

    def add(type, result, args = {})
      template = MESSAGES[type].fetch(result.to_s) { MESSAGES[type][:default] }
      return unless template

      args = convert_hash(
        args.merge(result: result)
          .transform_values { |v| v.respond_to?(:to_explain_params) ? v.to_explain_params : v }
      )

      @logs << template.dup.tap do |m|
        m[:title] = format(m[:title], args)
        m[:subtitle] = format(m[:subtitle], args) if m[:subtitle]
      end
      true
    end

    def convert_hash(hsh, path = "")
      hsh.each_with_object({}) do |(k, v), ret|
        key = "#{path}#{k}"

        if v.is_a?(Hash)
          ret.merge! convert_hash(v, "#{key}.")
        else
          ret[key.to_sym] = v
        end
      end
    end
  end
end
