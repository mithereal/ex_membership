alias Membership.Repo

feature_1 = Membership.Feature.create("Author Document", "Author Document")
feature_2 = Membership.Feature.create("change settings", "change settings")

plan = Membership.Plan.create("Bronze", "Bronze Plan")

Membership.Feature.grant(feature_1, plan)
Membership.Member.grant(feature_2, plan)
