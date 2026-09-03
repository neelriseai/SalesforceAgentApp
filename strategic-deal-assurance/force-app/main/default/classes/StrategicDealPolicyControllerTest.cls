/** BR-STRATEGIC-DISCOUNT: parent-authorized history DTO and negative access tests. */
@IsTest
private class StrategicDealPolicyControllerTest {
    @TestSetup static void users() {
        Id profileId=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' WITH SYSTEM_MODE LIMIT 1].Id;
        List<User> people=new List<User>();
        for (String alias : new List<String>{'sduiok','sduideny'}) {
            people.add(new User(Alias=alias, LastName='Synthetic UI ' + alias, Email=alias+'@example.invalid',
                Username=alias+'.'+UserInfo.getOrganizationId()+'.'+System.now().getTime()+'@example.invalid',
                ProfileId=profileId, TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US',
                EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US'));
        }
        insert as system people;
        Id permissionId=[SELECT Id FROM PermissionSet WHERE Name='Strategic_Deal_User' WITH SYSTEM_MODE LIMIT 1].Id;
        insert as system new PermissionSetAssignment(AssigneeId=people[0].Id, PermissionSetId=permissionId);
    }
    private static User allowed() { return [SELECT Id FROM User WHERE Alias='sduiok' WITH SYSTEM_MODE LIMIT 1]; }
    private static Opportunity createDeal() {
        String stage=[SELECT MasterLabel FROM OpportunityStage WHERE IsActive=true AND IsClosed=false WITH SYSTEM_MODE ORDER BY SortOrder LIMIT 1].MasterLabel;
        Opportunity value=new Opportunity(Name='SYN-UI-Controller', StageName=stage, CloseDate=Date.today().addDays(30),
            Amount=60000000, Discount__c=20, Strategic_Deal__c=true, Regional_VP_Approver__c=UserInfo.getUserId());
        insert as user value;
        return value;
    }
    @IsTest static void allowedParentReturnsNarrowHistoryWithoutDirectObjectAccess() {
        System.runAs(allowed()) {
            Opportunity value=createDeal();
            System.assertEquals(false, Strategic_Deal_Evaluation__c.SObjectType.getDescribe().isAccessible(), 'No direct evidence read grant');
            StrategicDealPolicyController.PolicyView view=StrategicDealPolicyController.getPolicy(value.Id);
            System.assertEquals('Pending Regional VP', view.status, 'Live Flow result');
            System.assertEquals('USD', view.currencyCode, 'USD only');
            System.assertEquals(50000000, view.amountThreshold, 'Active amount config');
            System.assertEquals(15, view.discountThreshold, 'Active discount config');
            System.assertEquals('baseline-15', view.appliedRuleVersion, 'Applied rule');
            System.assertEquals('baseline-15', view.activeRuleVersion, 'Current rule');
            System.assertEquals(true, view.ruleActive, 'Active rule');
            System.assertEquals(1, view.history.size(), 'One evidence row');
            System.assertEquals(60000000, view.history[0].amount, 'Authorized amount snapshot');
            System.assertEquals(20, view.history[0].discount, 'Authorized discount snapshot');
            System.assertEquals(view.status, view.history[0].outcome, 'Correlated outcome');
            String serialized=JSON.serialize(view);
            System.assert(!serialized.contains(String.valueOf(value.Id)), 'No parent ID in rendered DTO');
            System.assert(!serialized.contains(String.valueOf(UserInfo.getUserId())), 'No identity in DTO');
        }
    }
    @IsTest static void historyIsBoundedToFiveNewestSnapshots() {
        System.runAs(allowed()) {
            Opportunity value=createDeal();
            // Sequential edits model six separate business changes, not a bulk service pattern.
            update as user new Opportunity(Id=value.Id, Discount__c=21);
            update as user new Opportunity(Id=value.Id, Discount__c=22);
            update as user new Opportunity(Id=value.Id, Discount__c=23);
            update as user new Opportunity(Id=value.Id, Discount__c=24);
            update as user new Opportunity(Id=value.Id, Discount__c=25);
            update as user new Opportunity(Id=value.Id, Discount__c=26);
            StrategicDealPolicyController.PolicyView view=StrategicDealPolicyController.getPolicy(value.Id);
            System.assertEquals(5, view.history.size(), 'Bounded history');
            System.assertEquals(26, view.history[0].discount, 'Newest snapshot first');
        }
    }
    @IsTest static void parentDeniedEvenWhenEvidenceExists() {
        Id dealId;
        System.runAs(allowed()) { dealId=createDeal().Id; }
        User denied=[SELECT Id FROM User WHERE Alias='sduideny' WITH SYSTEM_MODE LIMIT 1];
        System.runAs(denied) { assertDenied(dealId); }
    }
    @IsTest static void invalidAndMissingParentsFailSafely() {
        System.runAs(allowed()) {
            assertDenied(null);
            assertDenied(UserInfo.getUserId());
            assertDenied(Id.valueOf('006000000000001AAA'));
        }
    }
    private static void assertDenied(Id recordId) {
        Boolean denied=false;
        try { StrategicDealPolicyController.getPolicy(recordId); }
        catch (AuraHandledException expected) {
            denied=true;
            System.assertEquals('Policy information is unavailable or you do not have access.', expected.getMessage(), 'Safe uniform error');
        }
        System.assertEquals(true, denied, 'Parent access must gate the system-mode history reader');
    }
}
