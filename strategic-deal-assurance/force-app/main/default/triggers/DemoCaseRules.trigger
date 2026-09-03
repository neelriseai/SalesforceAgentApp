trigger DemoCaseRules on Case (before insert, before update) {
    DemoBusinessRules.cases(Trigger.new, Trigger.oldMap);
}
