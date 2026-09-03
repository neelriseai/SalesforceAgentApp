@IsTest
private class DemoBusinessRulesTest {
    @TestSetup static void setup() {
        insert as system new List<Account>{new Account(Name='SYN-RULE-A1'), new Account(Name='SYN-RULE-A2')};
        Account a = [SELECT Id FROM Account WHERE Name='SYN-RULE-A1' WITH SYSTEM_MODE];
        Contact c = new Contact(LastName='SYN-RULE-C1', AccountId=a.Id); insert as system c;
        insert as system new Opportunity(Name='SYN-RULE-O1', AccountId=a.Id, StageName='Prospecting', CloseDate=Date.today().addDays(30), Amount=100000);
        insert as system new Case(Subject='SYN-RULE-S1', AccountId=a.Id, ContactId=c.Id, Status='New', Origin='Web');
        insert as system new Task(Subject='SYN-RULE-T1', Status='Not Started', Priority='Normal', WhoId=c.Id);
        insert as system new Lead(LastName='SYN-RULE-L1', Company='Synthetic company', Status='Open - Not Contacted');
        Campaign campaign = new Campaign(Name='SYN-RULE-M1', IsActive=false); insert as system campaign;
        insert as system new CampaignMember(CampaignId=campaign.Id, ContactId=c.Id, Status='Sent');
    }
    private static void toggle(String key, Boolean value) {
        if (DemoBusinessRules.testRules == null) DemoBusinessRules.testRules = new Map<String, Demo_Business_Rule__mdt>();
        DemoBusinessRules.testRules.put(key, new Demo_Business_Rule__mdt(Enabled__c=value,
            Rule_Version__c='test-v1', Number_Value__c=100000, Required_Value__c='Working - Contacted'));
    }
    private static void denied(Database.SaveResult result, String code) {
        System.assertEquals(false, result.isSuccess(), 'Mutation must be rejected');
        System.assert(result.getErrors()[0].getMessage().contains(code), result.getErrors()[0].getMessage());
    }
    private static Opportunity opportunity() { return [SELECT Id, Name, Amount, StageName FROM Opportunity WHERE Name='SYN-RULE-O1' WITH SYSTEM_MODE]; }
    @IsTest static void baselineConfiguration() {
        List<String> keys = new List<String>{'Account_Reparent','Contact_Reparent','Lead_Qualification','Opportunity_Minimum',
            'Opportunity_Primary_Contact','Case_Resolution','Task_Due_Date','Campaign_Active'};
        for (String key : keys) {
            Demo_Business_Rule__mdt r = Demo_Business_Rule__mdt.getInstance(key);
            System.assertNotEquals(null, r, key);
            System.assertEquals(false, r.Enabled__c, 'Restore all demo switches before running baseline regression');
            System.assertEquals('baseline-off-v1', r.Rule_Version__c);
        }
        System.assertEquals(100000, Demo_Business_Rule__mdt.getInstance('Opportunity_Minimum').Number_Value__c);
        System.assertEquals('Working - Contacted', Demo_Business_Rule__mdt.getInstance('Lead_Qualification').Required_Value__c);
    }
    @IsTest static void accountToggleAndScope() {
        Account a = [SELECT Id, Name, ParentId FROM Account WHERE Name='SYN-RULE-A1' WITH SYSTEM_MODE];
        a.ParentId = [SELECT Id FROM Account WHERE Name='SYN-RULE-A2' WITH SYSTEM_MODE].Id;
        toggle('Account_Reparent', true);
        denied(Database.update(a, false, AccessLevel.SYSTEM_MODE), 'Account_Reparent');
        System.assertEquals(null, [SELECT ParentId FROM Account WHERE Id=:a.Id WITH SYSTEM_MODE].ParentId);
        a.Name='Outside scope'; // Renaming in the same transaction must not evade old-prefix check.
        denied(Database.update(a, false, AccessLevel.SYSTEM_MODE), 'Account_Reparent');
        toggle('Account_Reparent', false); update as system a;
        System.assertEquals(a.ParentId, [SELECT ParentId FROM Account WHERE Id=:a.Id WITH SYSTEM_MODE].ParentId);
        toggle('Account_Reparent', true); a.ParentId=null; update as system a;
    }
    @IsTest static void contactToggle() {
        Contact c = [SELECT Id, LastName, AccountId FROM Contact WITH SYSTEM_MODE LIMIT 1];
        Id original=c.AccountId;
        c.AccountId=[SELECT Id FROM Account WHERE Name='SYN-RULE-A2' WITH SYSTEM_MODE].Id;
        toggle('Contact_Reparent',true); denied(Database.update(c, false, AccessLevel.SYSTEM_MODE),'Contact_Reparent');
        System.assertEquals(original,[SELECT AccountId FROM Contact WHERE Id=:c.Id WITH SYSTEM_MODE].AccountId);
        toggle('Contact_Reparent',false); update as system c;
    }
    @IsTest static void minimumBoundaries() {
        toggle('Opportunity_Minimum',true);
        Opportunity o=opportunity(); o.StageName='Closed Won'; o.Amount=99999.99;
        denied(Database.update(o, false, AccessLevel.SYSTEM_MODE),'Opportunity_Minimum');
        o.Amount=null; denied(Database.update(o, false, AccessLevel.SYSTEM_MODE),'Opportunity_Minimum');
        o.Amount=100000; update as system o;
        o.Amount=100000.01; update as system o;
        toggle('Opportunity_Minimum',false); o.Amount=1; update as system o;
    }
    @IsTest static void minimumConfigurationErrors() {
        toggle('Opportunity_Minimum',true); Opportunity o=opportunity(); o.StageName='Closed Won';
        DemoBusinessRules.testRules.get('Opportunity_Minimum').Number_Value__c=-1;
        denied(Database.update(o, false, AccessLevel.SYSTEM_MODE),'DEMO_CONFIG');
        DemoBusinessRules.testRules.get('Opportunity_Minimum').Number_Value__c=null;
        denied(Database.update(o, false, AccessLevel.SYSTEM_MODE),'DEMO_CONFIG');
        DemoBusinessRules.testRules.get('Opportunity_Minimum').Rule_Version__c=' ';
        denied(Database.update(o, false, AccessLevel.SYSTEM_MODE),'DEMO_CONFIG');
        DemoBusinessRules.testRules.put('Opportunity_Minimum',null);
        denied(Database.update(o, false, AccessLevel.SYSTEM_MODE),'DEMO_CONFIG');
    }
    @IsTest static void primaryContactAndStageOnlyEvidence() {
        toggle('Opportunity_Primary_Contact',true); Opportunity o=opportunity(); o.StageName='Closed Won';
        denied(Database.update(o, false, AccessLevel.SYSTEM_MODE),'Opportunity_Primary_Contact');
        Contact c=[SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];
        OpportunityContactRole role=new OpportunityContactRole(OpportunityId=o.Id, ContactId=c.Id, IsPrimary=false, Role='Decision Maker');
        insert as system role; denied(Database.update(o, false, AccessLevel.SYSTEM_MODE),'Opportunity_Primary_Contact');
        role.IsPrimary=true; update as system role;
        Integer beforeCount=[SELECT COUNT() FROM Strategic_Deal_Evaluation__c WHERE Opportunity__c=:o.Id WITH SYSTEM_MODE];
        update as system o;
        System.assertEquals(beforeCount,[SELECT COUNT() FROM Strategic_Deal_Evaluation__c WHERE Opportunity__c=:o.Id WITH SYSTEM_MODE], 'Stage guard does not manufacture policy history');
        Opportunity direct=new Opportunity(Name='SYN-RULE-new-won',StageName='Closed Won',Amount=200000,CloseDate=Date.today());
        denied(Database.insert(direct, false, AccessLevel.SYSTEM_MODE),'Opportunity_Primary_Contact');
        toggle('Opportunity_Primary_Contact',false); insert as system direct;
    }
    @IsTest static void rulesCompose() {
        toggle('Opportunity_Minimum',true); toggle('Opportunity_Primary_Contact',true);
        Opportunity o=opportunity(); o.Amount=10; o.StageName='Closed Won';
        Database.SaveResult result=Database.update(o, false, AccessLevel.SYSTEM_MODE);
        System.assertEquals(false,result.isSuccess()); System.assert(result.getErrors().size() >= 1);
        o.Amount=100000; denied(Database.update(o,false,AccessLevel.SYSTEM_MODE),'Opportunity_Primary_Contact');
        System.assertEquals('Prospecting',[SELECT StageName FROM Opportunity WHERE Id=:o.Id WITH SYSTEM_MODE].StageName);
    }
    @IsTest static void caseResolutionToggle() {
        toggle('Case_Resolution',true);
        Case c=[SELECT Id,Status,Demo_Resolution__c FROM Case WITH SYSTEM_MODE LIMIT 1]; c.Status='Closed';
        denied(Database.update(c, false, AccessLevel.SYSTEM_MODE),'Case_Resolution');
        c.Demo_Resolution__c='   '; denied(Database.update(c, false, AccessLevel.SYSTEM_MODE),'Case_Resolution');
        c.Demo_Resolution__c='Synthetic issue resolved and verified.'; update as system c;
        toggle('Case_Resolution',false); c.Demo_Resolution__c=null; update as system c;
        toggle('Case_Resolution',true);
        denied(Database.insert(new Case(Subject='SYN-RULE-NewClosed',Status='Closed',Origin='Web'),false,AccessLevel.SYSTEM_MODE),'Case_Resolution');
    }
    @IsTest static void taskDueDateToggle() {
        toggle('Task_Due_Date',true);
        Task t=[SELECT Id,Status,ActivityDate FROM Task WITH SYSTEM_MODE LIMIT 1]; t.Status='Completed';
        denied(Database.update(t, false, AccessLevel.SYSTEM_MODE),'Task_Due_Date');
        t.ActivityDate=Date.today().addDays(-1); update as system t; // Presence, not future-date validation.
        toggle('Task_Due_Date',false); t.ActivityDate=null; update as system t;
        toggle('Task_Due_Date',true);
        denied(Database.insert(new Task(Subject='SYN-RULE-NewCompleted',Status='Completed',Priority='Normal'),false,AccessLevel.SYSTEM_MODE),'Task_Due_Date');
    }
    @IsTest static void campaignToggleAndNoop() {
        toggle('Campaign_Active',true);
        CampaignMember member=[SELECT Id,CampaignId,Status FROM CampaignMember WITH SYSTEM_MODE LIMIT 1];
        update as system member; // Unchanged response allowed even on inactive campaign.
        member.Status='Responded'; denied(Database.update(member, false, AccessLevel.SYSTEM_MODE),'Campaign_Active');
        update as system new Campaign(Id=member.CampaignId,IsActive=true); update as system member;
        update as system new Campaign(Id=member.CampaignId,IsActive=false);
        toggle('Campaign_Active',false); member.Status='Sent'; update as system member;
        toggle('Campaign_Active',true); DemoBusinessRules.testRules.get('Campaign_Active').Rule_Version__c='';
        member.Status='Responded'; denied(Database.update(member, false, AccessLevel.SYSTEM_MODE),'DEMO_CONFIG');
    }
    private static Database.LeadConvertResult convert(Lead lead) {
        Database.LeadConvert request=new Database.LeadConvert(); request.setLeadId(lead.Id);
        request.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true WITH SYSTEM_MODE LIMIT 1].MasterLabel);
        request.setDoNotCreateOpportunity(true); request.setSendNotificationEmail(false);
        return Database.convertLead(request,false);
    }
    @IsTest static void nativeLeadQualificationAndRollback() {
        toggle('Lead_Qualification',true);
        Lead lead=[SELECT Id,Status,IsConverted FROM Lead WITH SYSTEM_MODE LIMIT 1];
        Integer accountsBefore=[SELECT COUNT() FROM Account WITH SYSTEM_MODE], contactsBefore=[SELECT COUNT() FROM Contact WITH SYSTEM_MODE];
        Database.LeadConvertResult deniedConversion=convert(lead);
        System.assertEquals(false,deniedConversion.isSuccess(),'Native conversion must execute the guard');
        System.assert(deniedConversion.getErrors()[0].getMessage().contains('Lead_Qualification'));
        System.assertEquals(false,[SELECT IsConverted FROM Lead WHERE Id=:lead.Id WITH SYSTEM_MODE].IsConverted);
        System.assertEquals(accountsBefore,[SELECT COUNT() FROM Account WITH SYSTEM_MODE]);
        System.assertEquals(contactsBefore,[SELECT COUNT() FROM Contact WITH SYSTEM_MODE]);
        lead.Status='Working - Contacted'; update as system lead;
        System.assertEquals(true,convert(lead).isSuccess());
    }
    @IsTest static void leadDisabledAndInvalidConfig() {
        Lead lead=[SELECT Id FROM Lead WITH SYSTEM_MODE LIMIT 1]; toggle('Lead_Qualification',true);
        DemoBusinessRules.testRules.get('Lead_Qualification').Required_Value__c=null;
        Database.LeadConvertResult result=convert(lead);
        System.assertEquals(false,result.isSuccess()); System.assert(result.getErrors()[0].getMessage().contains('DEMO_CONFIG'));
        toggle('Lead_Qualification',false); System.assertEquals(true,convert(lead).isSuccess());
    }
    @IsTest static void unrelatedEditsAndScope() {
        for(String key:new List<String>{'Account_Reparent','Contact_Reparent','Opportunity_Minimum','Opportunity_Primary_Contact','Case_Resolution','Task_Due_Date','Campaign_Active'}) toggle(key,true);
        Account a=[SELECT Id FROM Account WHERE Name='SYN-RULE-A1' WITH SYSTEM_MODE]; a.Description='Unrelated edit'; update as system a;
        Contact c=[SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1]; c.Title='Synthetic Buyer'; update as system c;
        Opportunity o=opportunity(); o.StageName='Qualification'; update as system o;
        insert as system new Case(Subject='Outside demo scope',Status='Closed',Origin='Web');
        insert as system new Task(Subject='Outside demo scope',Status='Completed',Priority='Normal');
        insert as system new Opportunity(Name='Outside demo scope',StageName='Closed Won',CloseDate=Date.today(),Amount=1);
    }
    @IsTest static void bulkAccountsPartialSuccess() {
        List<Account> rows=new List<Account>();
        for(Integer i=0;i<200;i++) rows.add(new Account(Name='SYN-RULE-BULK-'+i));
        insert as system rows; Id parent=[SELECT Id FROM Account WHERE Name='SYN-RULE-A1' WITH SYSTEM_MODE].Id;
        for(Integer i=0;i<200;i++) { rows[i].Description='Updated'; if(i<100) rows[i].ParentId=parent; }
        toggle('Account_Reparent',true); Test.startTest();
        List<Database.SaveResult> results=Database.update(rows, false, AccessLevel.SYSTEM_MODE);
        Test.stopTest();
        for(Integer i=0;i<200;i++) System.assertEquals(i>=100,results[i].isSuccess(),'Independent partial-save result');
    }
    @IsTest static void bulkPrimaryUsesOneQuery() {
        List<Opportunity> rows=new List<Opportunity>();
        for(Integer i=0;i<200;i++) rows.add(new Opportunity(Name='SYN-RULE-BULK-O'+i,StageName='Prospecting',CloseDate=Date.today(),Amount=100000));
        insert as system rows; Contact c=[SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];
        List<OpportunityContactRole> roles=new List<OpportunityContactRole>();
        for(Opportunity o:rows) {roles.add(new OpportunityContactRole(OpportunityId=o.Id,ContactId=c.Id,IsPrimary=true)); o.StageName='Closed Won';}
        insert as system roles; toggle('Opportunity_Primary_Contact',true);
        Test.startTest(); update as system rows; System.assert(Limits.getQueries()<=2,'No SOQL in per-record loops'); Test.stopTest();
        System.assertEquals(200,[SELECT COUNT() FROM Opportunity WHERE Name LIKE 'SYN-RULE-BULK-O%' AND StageName='Closed Won' WITH SYSTEM_MODE]);
    }
}
