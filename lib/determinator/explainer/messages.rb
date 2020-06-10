module Determinator
  class Explainer
    MESSAGES = {
      start: {
        default: {
          type: :start,
          title: 'Determinating %<feature.name>s',
          subtitle: 'The given ID, GUID and properties will be used to determine which target groups this actor is in, and will deterministically return an outcome for the visibility of this feature for them.'
        }
      },
      feature_active: {
        'true' => { type: :continue, title: 'Feature is active' },
        'false' => { type: :fail, title: 'Feature is inactive', subtitle: 'Every actor is excluded' }
      },
      feature_overridden_for: {
        'false' => { type: :pass, title: 'No matching override found'  }
      },
      override_value: {
        default: {
          type: :success,
          title: 'Matching override found for this actor with id: %<id>s',
          subtitle: 'Determinator will return "%<result>s" for this actor and this feature in any system that is correctly set up.'
        }
      },
      excluded_from_rollout: {
        'true' => {
          type: :fail,
          title: 'Determinated to be outside the %<target_group.rollout_percent>s',
          subtitle: 'This actor is excluded'
        },
        'false' => {
          type: :continue,
          title: 'Determinated to be inside the %<target_group.rollout_percent>s',
          subtitle: 'This actor is included'
        }
      },
      require_variant_determination: {
        'false' => {
          type: :success,
          title: 'Feature flag on for this actor',
          subtitle: 'Determinator will return true for this actor and this feature in any system that is correctly set up.'
        }
      },
      missing_identifier: {
        default: {
          type: :fail,
          title: 'No %<identifier_type>s given, cannot determinate',
          subtitle: 'For %<identifier_type>s bucketed features an %<identifier_type>s must be given to have the possibility of being included.'
        }
      },
      chosen_variant: {
        default: {
          type: :success,
          title: 'In the "%<result>s" variant',
          subtitle: 'Determinator will return "%<result>s" for this actor and this feature in any system that is correctly set up.'
        }
      },
      unknown_bucket: {
        default: {
          type: :fail,
          title: 'Unknown bucket type',
          subtitle: 'The bucket type "%<feature.bucket_type>s" is not understood by Determinator. All actors will be excluded.'
        }
      },
      check_target_group: {
        default: {
          type: :target_group,
          title: 'Checking "%<target_group.name>s" target group',
          subtitle: 'An actor must match at least one non-zero target group in order to be included.'
        }
      },
      possible_match_target_group: {
        'true' => {
          type: :continue,
          title: 'Matches the "%<target_group.name>s" target group',
          subtitle: 'Matching this target group allows this actor a %<target_group.rollout_percent>s percent chance of being included.'
        },
        'false' => {
          type: :pass,
          title: 'Didn\'t match the "%<target_group.name>s" target group',
          subtitle: 'Actor can\'t be included as part of this target group.'
        }
      },
      chosen_target_group: {
        '' => {
          type: :fail,
          title: 'No matching target groups',
          subtitle: 'No matching target groups have a rollout larger than 0 percent. This actor is excluded.'
        },
        default: {
          type: :info,
          title: '%<result.rollout_percent>s percent chance of being included',
          subtitle: 'The largest matching rollout percentage is %<result.rollout_percent>s, giving this actor a percent chance of being included.'
        }
      },
      check_fixed_determination: {
        default: {
          type: :target_group,
          title: 'Checking "%<fixed_determination.name>s" fixed determination',
          subtitle: 'Matching an actor based on the constraints provided.'
        }
      },
      possible_match_fixed_determination: {
        'false' => {
          type: :pass,
          title: 'Didn\'t match the "%<fixed_determination.name>s" fixed determination',
          subtitle: 'Actor can\'t be included as part of this fixed determination.'
        }
      },
      chosen_fixed_determination: {
        default: {
          type: :success,
          title: 'Matching fixed determination found for this actor with name: "%<fixed_determination.name>s"',
          subtitle: 'Determinator will return "%<result>s" for this actor and this feature in any system that is correctly set up.'
        },
      }
    }.freeze
  end
end
