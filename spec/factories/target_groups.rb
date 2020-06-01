FactoryGirl.define do
  factory :target_group, class: Determinator::TargetGroup do
    sequence :name
    rollout 65_536
    constraints Hash.new('property' => 'value')
  end
end
