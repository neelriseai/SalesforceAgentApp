trigger DemoContactRules on Contact (before update) {
    DemoBusinessRules.contacts(Trigger.new, Trigger.oldMap);
}
