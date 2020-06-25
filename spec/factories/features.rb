FactoryGirl.define do
  factory :feature, class: Determinator::Feature do
    sequence :name
    identifier { name }
    bucket_type :guid
    structured_bucket nil
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

    trait :active do
      active true
    end

    trait :structured do
      structured_bucket 'request.customer.guid'
    end

    factory :experiment, class: Determinator::Feature do
      variants Hash[[['a', 1], ['b', 2]]]
    end
  end
end
