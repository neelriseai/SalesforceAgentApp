@IsTest
private class StrategicDealApprovalControllerTest {
    @TestSetup static void users() {
        Id profileId=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' WITH SYSTEM_MODE LIMIT 1].Id;
        List<User> people=new List<User>();
        for(String alias:new List<String>{'sdaown','sdavp'}) {
            people.add(new User(Alias=alias,LastName='Synthetic '+alias,Email=alias+'@example.invalid',
                Username=alias+'.'+UserInfo.getOrganizationId()+'.'+System.now().getTime()+'@example.invalid',
                ProfileId=profileId,TimeZoneSidKey='Asia/Kolkata',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US'));
        }
        insert as system people;
        Map<String,Id> sets=new Map<String,Id>();
        for(PermissionSet p:[SELECT Id,Name FROM PermissionSet WHERE Name IN ('Strategic_Deal_User','Regional_VP_Approver') WITH SYSTEM_MODE]) { sets.put(p.Name,p.Id); }
        insert as system new List<PermissionSetAssignment>{
            new PermissionSetAssignment(AssigneeId=people[0].Id,PermissionSetId=sets.get('Strategic_Deal_User')),
            new PermissionSetAssignment(AssigneeId=people[1].Id,PermissionSetId=sets.get('Regional_VP_Approver'))};
    }
    private static User person(String alias) { return [SELECT Id FROM User WHERE Alias=:alias WITH SYSTEM_MODE LIMIT 1]; }
    private static Opportunity makeDeal(Decimal discount, Boolean sameUser) {
        User owner=person('sdaown'); User vp=person('sdavp');
        Opportunity deal=new Opportunity(Name='SYN-Approval-Test',StageName='Prospecting',CloseDate=Date.today().addDays(30),
            Amount=60000000,Discount__c=discount,Strategic_Deal__c=true,Regional_VP_Approver__c=sameUser?owner.Id:vp.Id);
        System.runAs(owner) { insert as user deal; }
        return deal;
    }
    private static void submit(Id id) { System.runAs(person('sdaown')) { StrategicDealApprovalController.act(id,'Submit'); } }
    private static String status(Id id) { return [SELECT Approval_Status__c FROM Opportunity WHERE Id=:id WITH SYSTEM_MODE].Approval_Status__c; }
    private static void denied(Id id,String action) {
        Boolean blocked=false;
        try { StrategicDealApprovalController.act(id,action); } catch(AuraHandledException expected) { blocked=true; }
        System.assert(blocked,'Unauthorized/invalid transition must fail');
    }
    @IsTest static void submitLocksAndAssignedVpApproves() {
        Opportunity deal=makeDeal(15.01,false); submit(deal.Id);
        System.runAs(person('sdaown')) {
            StrategicDealApprovalController.State state=StrategicDealApprovalController.getState(deal.Id);
            System.assertEquals('Pending',state.status); System.assert(!state.canDecide && state.canRecall && !state.canSubmit);
            denied(deal.Id,'Approve'); denied(deal.Id,'Submit');
            Boolean locked=false;
            try { update as user new Opportunity(Id=deal.Id,Discount__c=20); } catch(DmlException expected) { locked=expected.getDmlStatusCode(0)=='ENTITY_IS_LOCKED'; }
            System.assert(locked,'Owner cannot edit during approval');
        }
        System.runAs(person('sdavp')) {
            System.assert(StrategicDealApprovalController.getState(deal.Id).canDecide,'Assigned VP can decide');
            StrategicDealApprovalController.act(deal.Id,'Approve');
        }
        System.assertEquals('Approved',status(deal.Id));
        System.assertEquals(1,[SELECT COUNT() FROM Strategic_Deal_Evaluation__c WHERE Opportunity__c=:deal.Id WITH SYSTEM_MODE],'Approval must not generate duplicate policy evidence');
        System.runAs(person('sdaown')) {
            update as user new Opportunity(Id=deal.Id,Name='SYN-Unlocked After Approval');
            StrategicDealApprovalController.State state=StrategicDealApprovalController.getState(deal.Id);
            System.assertEquals('Approved',state.status); System.assert(!state.history.isEmpty());
            System.assert(!JSON.serialize(state).contains(String.valueOf(deal.Id)),'DTO excludes record IDs');
        }
    }
    @IsTest static void rejectionUnlocksAndRequiresNewEvaluation() {
        Opportunity deal=makeDeal(20,false); submit(deal.Id);
        System.runAs(person('sdavp')) { StrategicDealApprovalController.act(deal.Id,'Reject'); }
        System.assertEquals('Rejected',status(deal.Id));
        System.runAs(person('sdaown')) {
            denied(deal.Id,'Submit');
            update as user new Opportunity(Id=deal.Id,Discount__c=21);
            System.assert(StrategicDealApprovalController.getState(deal.Id).canSubmit);
            StrategicDealApprovalController.act(deal.Id,'Submit');
        }
        System.assertEquals(2,[SELECT COUNT() FROM ProcessInstance WHERE TargetObjectId=:deal.Id WITH SYSTEM_MODE]);
    }
    @IsTest static void ownerCanRecallAndResubmit() {
        Opportunity deal=makeDeal(20,false); submit(deal.Id);
        System.runAs(person('sdavp')) { denied(deal.Id,'Recall'); }
        System.runAs(person('sdaown')) {
            StrategicDealApprovalController.act(deal.Id,'Recall');
            System.assertEquals('Removed',StrategicDealApprovalController.getState(deal.Id).status);
            update as user new Opportunity(Id=deal.Id,Name='SYN-Unlocked After Recall');
            System.assertEquals('Pending Regional VP',status(deal.Id));
            StrategicDealApprovalController.act(deal.Id,'Submit');
        }
    }
    @IsTest static void exactBoundaryCannotSubmit() {
        Opportunity deal=makeDeal(15,false);
        System.runAs(person('sdaown')) { denied(deal.Id,'Submit'); }
        System.assertEquals(0,[SELECT COUNT() FROM ProcessInstance WHERE TargetObjectId=:deal.Id WITH SYSTEM_MODE]);
    }
    @IsTest static void selfApprovalBlockedByNativeEntryAlso() {
        Opportunity deal=makeDeal(20,true);
        System.runAs(person('sdaown')) {
            System.assert(StrategicDealApprovalController.getState(deal.Id).needsSeparateApprover);
            denied(deal.Id,'Submit');
            Approval.ProcessSubmitRequest request=new Approval.ProcessSubmitRequest(); request.setObjectId(deal.Id);
            request.setProcessDefinitionNameOrId('Strategic_Opportunity_Regional_VP'); request.setSkipEntryCriteria(false);
            Boolean blocked=false;
            try { blocked=!Approval.process(request).isSuccess(); } catch(DmlException expected) { blocked=true; }
            System.assert(blocked,'Native API must not bypass self-approval guard');
        }
    }
    @IsTest static void onlyOwnerSubmitsAndNoArbitraryActions() {
        Opportunity deal=makeDeal(20,false);
        System.runAs(person('sdavp')) { denied(deal.Id,'Submit'); }
        System.runAs(person('sdaown')) { denied(deal.Id,'Delete'); denied(null,'Submit'); denied(UserInfo.getUserId(),'Submit'); }
    }
    @IsTest static void staleStoredPolicyCannotSubmit() {
        Opportunity deal=makeDeal(15,false);
        update as system new Opportunity(Id=deal.Id,Approval_Status__c='Pending Regional VP');
        System.runAs(person('sdaown')) { denied(deal.Id,'Submit'); }
        System.assertEquals(0,[SELECT COUNT() FROM ProcessInstance WHERE TargetObjectId=:deal.Id WITH SYSTEM_MODE]);
    }
}
