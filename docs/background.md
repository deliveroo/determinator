# Terminology & Background

**Florence** is a suite of tools which help run experiments and feature flags (_collectively called **features**_), **Determinator** is the client-side component which implements the algorithm for figuring out what to show to whom.

**Feature flags** are used as a way to switch on and off functionality for specific actors across an entire ecosystem, where an **actor** might be a customer, a rider, or any identifiable agent using those systems.

**Experiments** are, at this stage, really just [A/B tests](https://en.wikipedia.org/wiki/A/B_testing) where an actor is repeatably shown either one **variant** of the product or another. The activity of large numbers of actors can be analysed to determine if one variant was, statistically speaking, better than the other for a given metric.

## Targeting actors

Florence also provides a very flexible way to target specific actors for new features or experiments. Every feature has one or more **target groups** associated with it each for which specifies a _rollout_ fraction and any number of _constraints_.

For a given feature an actor is part of a target group if the actor's **properties** are a match with the target group's **constraints** (ie. the feature's constraints are a subset of the actor's properties). For example, a customer may have a property `employee: 'false'`; this actor would _not_ be part of a target group with the constraint `employee: 'true'`, but _would_ be part of a target group with no constraints.

If an actor is in no target groups, then the feature (whether it is a feature flag or an experiment) will be off for that actor. If an actor is in more than one target group, then the most permissive target group is chosen.

Target groups also have a **rollout** fraction which represents how many actors should be included or excluded from the feature. For example this allows a feature to be on for 95% of people using it, or to be rolled out to 100% of employees, but only 5% of non-employees.

## Experiments vs. Feature Flags

Experiments in Florence are Feature flags which also allocate an experimental **variant** to the actors invovled. The variants chosen are also chosen deterministically, so the same actor will always see the same experiment.

For example an experiment which tested whether the 🎉 or the 🙌 emoji was better in a given situation by showing 80% of all non-employees one or the other (in a 50/50 split) would have:

- One target group, with a rollout of 80% and a single constraint that `employee` must be `false`
- Two variants, one called `party popper` and one called `high ten`, with the same **weight** as each other (so the split is equal)

## Determinism

Whether an actor is rolled out to or not and which variant they see is calculated [deterministically](https://en.wikipedia.org/wiki/Deterministic_system). This is so that two isolated systems, if they have the same list of experiments and feature flags, will have _the same outcomes_ for every actor, feature flag and experiment.

In order to ensure that the same actor sees the same things _every time_ a [cryptographically secure hashing function](https://en.wikipedia.org/wiki/Cryptographic_hash_function) is applied to a combination of an actor's identifier (eg. their ID or their anonymous ID) and the feature's name and the resulting information is used to determine what the specified actor will see.

This is so that there is no need for a centralised database of which actors should be shown which variants, and which actors should be in hold out groups for experiments (this removes the need for [locks](https://en.wikipedia.org/wiki/Lock_%28computer_science%29) which become very complex in distributed environments).

This algorithm is also organised so that, when increasing and lowering rollout fractions, the same actors will be included and excluded at each fraction.

## Overrides

The determination algorithm also allows **overrides** which allow specified actors to receive the given outcome even if the algorithm would normally give them another. This is particularly helpful for testing in production environments, where a product manager might have a feature turned on for only them, or to switch themselves between the two variants of an experiment to ensure both work as expected.

Overrides should be used sparingly and only for temporary changes; for situations where even a small group of actors should see a specific feature consider whether the actor has an attribute which defines whether they should see it or not, and instead deliver that as a property so that a target group can specify just them. A simple example of this is 'VIPs', rather than specifying them as `override: true` for a feature flag, they should instead have the property `vip: true`, with an equivalent constraint on a 100% rollout target group.
