module Determinator
  class Explainer
    EVENTS_TO_METHODS = {
      [:call, Determinator::Control, :determinate] => :start_determination,
      [:return, Determinator::Feature, :active?] => :feature_active?,
      [:return, Determinator::Feature, :overridden_for?] => :override?,
      [:return, Determinator::Feature, :override_value_for] => :override_match,
      [:b_call, Determinator::Control, :filtered_target_groups] => :check_target_group,
      [:b_return, Determinator::Control, :filtered_target_groups] => :target_group_match?,
      [:return, Determinator::Control, :choose_target_group] => :choosen_target_group,
      [:return, Determinator::Control, :actor_identifier] => :actor,
      [:return, Determinator::Control, :included_in_rollout?] => :included_in_rollout?,
      [:return, Determinator::Control, :variant_for] => :choosen_variant,
      [:return, Determinator::Control, :require_variant_determination?] => :feature_flag_on?,
    }.freeze

    EVENTS_TO_MONITOR = EVENTS_TO_METHODS.keys.freeze

    MESSAGES = {
      start: {
        type: :start,
        title: 'Determinating %<feature_name>s',
        subtitle: 'The given ID, GUID and properties will be used to determine which target groups this actor is in, and will deterministically return an outcome for the visibility of this feature for them.'
      },
      feature_active: { type: :continue, title: 'Feature is active' },
      feature_inactive: { type: :fail, title: 'Feature is inactive', subtitle: 'Every actor is excluded' },
      no_matching_override: { type: :pass, title: 'No matching override found'  },
      override_match: {
        type: :success,
        title: 'Matching override found for this actor with id: %<id>s',
        subtitle: 'Determinator will return "%<determination>s" for this actor and this feature in any system that is correctly set up.'
      },
      check_target_group: {
        type: :target_group,
        title: 'Checking "%<tg_name>s" target group',
        subtitle: 'An actor must match at least one non-zero target group in order to be included.'
      },
      match_target_group: {
        type: :continue,
        title: 'Matches the "%<tg_name>s" target group',
        subtitle: 'Matching this target group allows this actor a %<percentage>s percent chance of being included.'
      },
      no_match_target_group: {
        type: :pass,
        title: 'Didn\'t match the "%<tg_name>s" target group',
        subtitle: 'Actor can\'t be included as part of this target group.'
      },
      chosen_target_group: {
        type: :info,
        title: '%<percentage>s percent chance of being included',
        subtitle: 'The largest matching rollout percentage is %<percentage>s, giving this actor a %<percentage>s percent chance of being included.'
      },
      no_matching_target_groups: {
        type: :fail,
        title: 'No matching target groups',
        subtitle: 'No matching target groups have a rollout larger than 0%. This actor is excluded.'
      },
      no_id: {
        type: :fail,
        title: 'No ID given, cannot determinate',
        subtitle: 'For ID bucketed features an ID must be given to have the possibility of being included.'
      },
      no_guid: {
        type: :fail,
        title: 'No GUID given, cannot determinate',
        subtitle: 'For GUID bucketed features an GUID must be given to have the possibility of being included.'
      },
      unknown_bucket: {
        type: :fail,
        title: 'Unknown bucket type',
        subtitle: 'The bucket type "%<bucket_type>s" is not understood by Determinator. All actors will be excluded.'
      },
      excluded_from_rollout: {
        type: :fail,
        title: 'Determinated to be outside the %<percentage>s',
        subtitle: 'This actor is excluded'
      },
      included_in_rollout: {
        type: :continue,
        title: 'Determinated to be inside the %<percentage>s',
        subtitle: 'This actor is included'
      },
      feature_flag_on: {
        type: :success,
        title: 'Feature flag on for this actor',
        subtitle: 'Determinator will return true for this actor and this feature in any system that is correctly set up.'
      },
      variant: {
        type: :success,
        title: 'In the "%<variant>s" variant',
        subtitle: 'Determinator will return "%<variant>s" for this actor and this feature in any system that is correctly set up.'
      },
    }.freeze

    def initialize
      @trace = configure_tracer
      @result = []
    end

    def explain
      trace.enable
      outcome = yield
      { outcome: outcome, explanation: result }
    ensure
      trace.disable
    end

    private

    attr_reader :trace, :result

    def configure_tracer
      TracePoint.new(:call, :return, :b_call, :b_return) do |tp|
        key = [tp.event, tp.defined_class, tp.method_id]
        if EVENTS_TO_MONITOR.include?(key)
          param_names = tp.self.method(tp.method_id).parameters.map(&:last)

          args = param_names.map { |n| [n, @trace.binding.eval(n.to_s)] }.to_h

          send(EVENTS_TO_METHODS[key], tp, args)
        end
      end
    end

    def start_determination(tp, args)
      @result << MESSAGES[:start].dup.tap { |m| m[:title] = format(m[:title], feature_name: args[:feature].name) }
    end

    def feature_active?(tp, _)
      @result << (tp.return_value == true ? MESSAGES[:feature_active] : MESSAGES[:feature_inactive])
    end

    def override?(tp, _)
      @result << MESSAGES[:no_matching_override] if tp.return_value == false
    end

    def override_match(tp, args)
      @result << MESSAGES[:override_match].dup.tap do |m|
        m[:title] = format(m[:title], id: args[:id])
        m[:subtitle] = format(m[:subtitle], determination: tp.return_value)
      end
    end

    def check_target_group(tp, args)
      if args.key?(:tg)
        @result << MESSAGES[:check_target_group].dup.tap { |m| m[:title] = format(m[:title], tg_name: args[:tg].name || 'no name') }
      end
    end

    def target_group_match?(tp, args)
      return unless args.key?(:tg)
      if tp.return_value == true
        @result << MESSAGES[:match_target_group].dup.tap do |m|
          m[:title] = format(m[:title], tg_name: args[:tg].name || 'no name')
          m[:subtitle] = format(m[:subtitle], percentage: args[:tg].percentage)
        end
      else
        @result << MESSAGES[:no_match_target_group].dup.tap do |m|
          m[:title] = format(m[:title], tg_name: args[:tg].name || 'no name')
        end
      end
    end

    def choosen_target_group(tp, _)
      if tp.return_value.is_a? Determinator::TargetGroup
        @result << MESSAGES[:chosen_target_group].dup.tap do |m|
          m[:title] = format(m[:title], percentage: tp.return_value.percentage)
          m[:subtitle] = format(m[:subtitle], percentage: tp.return_value.percentage)
        end
      else
        @result << MESSAGES[:no_matching_target_groups]
      end
    end

    def actor(tp, args)
      if !tp.return_value
        if [:id, :guid].include?(args[:feature].bucket_type)
          @result << MESSAGES["no_#{args[:feature].bucket_type}".to_sym]
        else
          @result << MESSAGES[:unknown_bucket].dup.tap { |m| m[:subtitle] =  format(m[:subtitle], bucket_type: args[:feature].bucket_type) }
        end
      end
    end

    def included_in_rollout?(tp, args)
      message = (tp.return_value == true ? MESSAGES[:included_in_rollout] : MESSAGES[:excluded_from_rollout])

      @result << message.dup.tap { |m| m[:title] =  format(m[:title], percentage: args[:target_group].percentage) }
    end

    def choosen_variant(tp, _)
      @result << MESSAGES[:variant].dup.tap do |m|
        m[:title] = format(m[:title], variant: tp.return_value)
        m[:subtitle] = format(m[:subtitle], variant: tp.return_value)
      end
    end

    def feature_flag_on?(tp, _)
      @result << MESSAGES[:feature_flag_on] if tp.return_value == false
    end
  end
end
