/** Configurable synthetic-demo save guards. No writes, notifications, or permission bypasses. */
public with sharing class DemoBusinessRules {
    @TestVisible private static Map<String, Demo_Business_Rule__mdt> testRules;
    private static Map<String, Demo_Business_Rule__mdt> cachedRules;

    private static Demo_Business_Rule__mdt rule(String key) {
        if (Test.isRunningTest() && testRules != null && testRules.containsKey(key)) return testRules.get(key);
        if (cachedRules == null) cachedRules = Demo_Business_Rule__mdt.getAll();
        return cachedRules.get(key);
    }
    private static Boolean scoped(String value) {
        return value != null && (value.startsWith('SYN-MM-') || value.startsWith('SYN-RULE-'));
    }
    private static Boolean inScope(String currentValue, String oldValue) {
        return scoped(currentValue) || scoped(oldValue);
    }
    private static Boolean enabled(SObject row, String key) {
        Demo_Business_Rule__mdt config = rule(key);
        if (config == null || (config.Enabled__c && String.isBlank(config.Rule_Version__c))) {
            row.addError('DEMO_CONFIG: Missing rule or version: ' + key);
            return false;
        }
        return config.Enabled__c;
    }
    private static void reject(SObject row, String key, String message) {
        row.addError('DEMO_RULE ' + key + ': ' + message);
    }

    public static void accounts(List<Account> rows, Map<Id, Account> previous) {
        for (Account row : rows) {
            Account old = previous.get(row.Id);
            if (inScope(row.Name, old.Name) && row.ParentId != old.ParentId && enabled(row, 'Account_Reparent'))
                reject(row, 'Account_Reparent', 'Parent Account changes are disabled for this demo.');
        }
    }
    public static void contacts(List<Contact> rows, Map<Id, Contact> previous) {
        for (Contact row : rows) {
            Contact old = previous.get(row.Id);
            if (inScope(row.LastName, old.LastName) && row.AccountId != old.AccountId && enabled(row, 'Contact_Reparent'))
                reject(row, 'Contact_Reparent', 'Contact Account changes are disabled for this demo.');
        }
    }
    // After-update addError rolls back the whole native conversion, including new records.
    public static void leads(List<Lead> rows, Map<Id, Lead> previous) {
        for (Lead row : rows) {
            Lead old = previous.get(row.Id);
            if (inScope(row.LastName, old.LastName) && row.IsConverted && !old.IsConverted && enabled(row, 'Lead_Qualification')) {
                String required = rule('Lead_Qualification').Required_Value__c;
                if (String.isBlank(required)) row.addError('DEMO_CONFIG: Lead_Qualification requires a status.');
                else if (old.Status != required) reject(row, 'Lead_Qualification', 'Save the required qualification status before converting.');
            }
        }
    }
    public static void opportunities(List<Opportunity> rows, Map<Id, Opportunity> previous) {
        List<Opportunity> requirePrimary = new List<Opportunity>();
        Set<Id> ids = new Set<Id>();
        for (Opportunity row : rows) {
            Opportunity old = previous == null ? null : previous.get(row.Id);
            if (!inScope(row.Name, old == null ? null : old.Name) || row.StageName != 'Closed Won') continue;
            if (enabled(row, 'Opportunity_Minimum')) {
                Decimal minimum = rule('Opportunity_Minimum').Number_Value__c;
                if (minimum == null || minimum < 0) row.addError('DEMO_CONFIG: Opportunity_Minimum needs a non-negative USD amount.');
                else if (row.Amount == null || row.Amount < minimum)
                    reject(row, 'Opportunity_Minimum', 'Closed Won requires Amount at or above the configured USD minimum.');
            }
            if (enabled(row, 'Opportunity_Primary_Contact')) {
                requirePrimary.add(row);
                if (row.Id != null) ids.add(row.Id);
            }
        }
        Set<Id> withPrimary = new Set<Id>();
        if (!ids.isEmpty()) {
            for (OpportunityContactRole role : [SELECT OpportunityId FROM OpportunityContactRole
                    WHERE OpportunityId IN :ids AND IsPrimary = true WITH USER_MODE]) withPrimary.add(role.OpportunityId);
        }
        for (Opportunity row : requirePrimary) if (!withPrimary.contains(row.Id))
            reject(row, 'Opportunity_Primary_Contact', 'Add a primary contact role before saving Closed Won.');
    }
    public static void cases(List<Case> rows, Map<Id, Case> previous) {
        for (Case row : rows) {
            Case old = previous == null ? null : previous.get(row.Id);
            if (inScope(row.Subject, old == null ? null : old.Subject) && row.Status == 'Closed'
                    && enabled(row, 'Case_Resolution') && String.isBlank(row.Demo_Resolution__c))
                reject(row, 'Case_Resolution', 'Enter Demo Resolution before saving a Closed case.');
        }
    }
    public static void tasks(List<Task> rows, Map<Id, Task> previous) {
        for (Task row : rows) {
            Task old = previous == null ? null : previous.get(row.Id);
            if (inScope(row.Subject, old == null ? null : old.Subject) && row.Status == 'Completed'
                    && enabled(row, 'Task_Due_Date') && row.ActivityDate == null)
                reject(row, 'Task_Due_Date', 'Enter a Due Date before saving a Completed task.');
        }
    }
    public static void campaignMembers(List<CampaignMember> rows, Map<Id, CampaignMember> previous) {
        Demo_Business_Rule__mdt config = rule('Campaign_Active');
        if (config != null && !config.Enabled__c) return;
        Set<Id> ids = new Set<Id>();
        for (CampaignMember row : rows) if (row.Status != previous.get(row.Id).Status) ids.add(row.CampaignId);
        if (ids.isEmpty()) return;
        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([SELECT Id, Name, IsActive FROM Campaign WHERE Id IN :ids WITH USER_MODE]);
        for (CampaignMember row : rows) {
            if (row.Status == previous.get(row.Id).Status) continue;
            Campaign campaign = campaigns.get(row.CampaignId);
            if (campaign == null) row.addError('DEMO_CONFIG: Cannot verify campaign access.');
            else if (scoped(campaign.Name) && enabled(row, 'Campaign_Active') && !campaign.IsActive)
                reject(row, 'Campaign_Active', 'Activate the campaign before changing a member response.');
        }
    }
}
