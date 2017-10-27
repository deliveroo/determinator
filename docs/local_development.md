# Local development

Because Determinator depends on features defined elsewhere, local development is supported by two pieces of software.

## `RSpec::Determinator` for automated testing

When writing tests for your code that makes use of Determinator you can use some RSpec helpers:

```ruby
require 'rspec/determinator'

RSpec.describe YourClass, :determinator_support do

  context "when the actor is in variant_a" do
    # This allows testing of the experiment being in a specific variant
    forced_determination(:experiment_name, 'variant_a')

    it "should respond in a way that is defined by variant_a" do
      # … etc
    end
  end

  context "when the actor is not in the experiment" do
    # This allows testing of the experiment being off
    forced_determination(:experiment_name, false)

    it "should respond in a way that is defined by being out of the experiment" do
      # … etc
    end
  end

  context "when the actor is not from France" do
    before { ensure_the_actor_is_not_from_france }
    # This allows testing of target group constraint functionality
    forced_determination(:experiment_name, 'variant_b', only_for: { country: 'fr' })

    it "should respond in a way that is defined by being out of the experiment" do
      # … etc
    end
  end

  context "when the constraints are defined dynamically" do
    forced_determination(:experiment_name, 'variant_b', only_for: constraints)
    let(:constraints) { { employee: true } }

    it "should respond in a way that shows employees the experiment" do
      # … etc
    end
  end

  context "when the actor has a specified id" do
    before { ensure_the_actor_has_id_123 }
    # This allows testing of override functionality
    forced_determination(:experiment_name, 'variant_b', only_for: { id: '123' })

    it "should respond in a way that is defined by variant_b" do
      # … etc
    end
end
```

Note that you can use Symbols for either the constraint declaration (`only_for`) or the outcome declaration and that variable or method will be called and the result used for that value. This is particularly helpful for examples which use the `let` scope declarations for cleaner tests.

## Fake Florence for local execution

[Fake Florence](https://github.com/deliveroo/fake_florence) is a command line utility which operates a determinator compatible server and provides tooling for easy editing of feature flags and experiments.

```bash
$ gem install fake_florence
Fake Florence has been installed. Run `flo help` for more information.
1 gem installed

$ flo start
Flo is now running at https://flo.dev
Use other commands to create or edit Feature flags and Experiments.
See `flo help` for more information

$ flo create my_experiment
      create  ~/.flo/features/my_experiment.yaml
my_experiment created and opened for editing
```

Then in your service, configured with `discovery_url: 'https://flo.dev'`, experiments and feature flags will retrieved and posted from Fake Florence:

```ruby
determinator.which_variant(:my_experiment, id: 123)
"anchovy"
```

More information can be found on the [Fake Florence](https://github.com/deliveroo/fake_florence) project page.
