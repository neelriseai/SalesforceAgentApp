trigger DemoCampaignMemberRules on CampaignMember (before update) {
    DemoBusinessRules.campaignMembers(Trigger.new, Trigger.oldMap);
}
