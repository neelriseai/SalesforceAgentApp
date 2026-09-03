trigger DemoOpportunityRules on Opportunity (before insert, before update) {
    DemoBusinessRules.opportunities(Trigger.new, Trigger.oldMap);
}
