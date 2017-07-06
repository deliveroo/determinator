FactoryGirl.define do
  factory :feature, class: Determinator::Feature do
    sequence :name
    identifier { name }
    bucket_type :guid
    active false

    # Not an experiment by default
    variants Hash.new

    overrides Hash.new
    target_groups { [
      create(:target_group,
        rollout: rollout,
        constraints: constraints
      )
    ] }

    transient do
      rollout 32_768
      constraints Hash.new
    end

    trait :full_rollout do
      rollout 65_536
      constraints Hash.new
    end

    trait :with_overrides do
      overrides Hash[[['123', false]]]
    end

    trait :active do
      active true
    end

    factory :experiment, class: Determinator::Feature do
      variants Hash[[['a', 1], ['b', 2]]]
    end
  end
end
