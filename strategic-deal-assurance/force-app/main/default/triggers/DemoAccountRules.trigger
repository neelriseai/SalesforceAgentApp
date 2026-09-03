trigger DemoAccountRules on Account (before update) {
    DemoBusinessRules.accounts(Trigger.new, Trigger.oldMap);
}
