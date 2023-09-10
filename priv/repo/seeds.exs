alias Membership.Repo

feature_1 = Membership.Feature.build("Author Document", "Author Document")
feature_2 = Membership.Feature.build("change settings", "change settings")

plan =
  Membership.Plan.build("Bronze", "Brass Plan", [feature_1, feature_2])

Repo.insert(plan)
