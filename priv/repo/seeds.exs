alias Membership.Repo

plan =
  Membership.Plan.build("Brass", "Brass Plan")

Repo.insert(plan)
