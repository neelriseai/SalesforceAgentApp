trigger DemoLeadRules on Lead (after update) {
    DemoBusinessRules.leads(Trigger.new, Trigger.oldMap);
}
