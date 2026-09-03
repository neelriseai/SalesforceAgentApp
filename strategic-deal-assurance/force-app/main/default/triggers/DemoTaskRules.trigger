trigger DemoTaskRules on Task (before insert, before update) {
    DemoBusinessRules.tasks(Trigger.new, Trigger.oldMap);
}
