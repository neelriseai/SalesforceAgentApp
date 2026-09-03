/** BR-STRATEGIC-DISCOUNT: internal Lightning adapter to Salesforce native approvals, not REST. */
public with sharing class StrategicDealApprovalController {
    private static final String PROCESS='Strategic_Opportunity_Regional_VP';
    public class HistoryRow {
        @AuraEnabled public String status;
        @AuraEnabled public Datetime occurredAt;
    }
    public class State {
        @AuraEnabled public String status;
        @AuraEnabled public Boolean locked;
        @AuraEnabled public Boolean canSubmit;
        @AuraEnabled public Boolean canDecide;
        @AuraEnabled public Boolean canRecall;
        @AuraEnabled public Boolean needsSeparateApprover;
        @AuraEnabled public List<HistoryRow> history;
    }
    private class Context {
        Opportunity deal;
        ProcessInstance process;
        Id workItemId;
        Id actorId;
    }
    @AuraEnabled(cacheable=true)
    public static State getState(Id opportunityId) {
        try { return view(load(opportunityId)); }
        catch(Exception ignored) { throw safeError(); }
    }
    @AuraEnabled
    public static void act(Id opportunityId, String action) {
        Savepoint checkpoint=Database.setSavepoint();
        try {
            Context context=load(opportunityId);
            State state=view(context);
            Approval.ProcessRequest request;
            if(action=='Submit' && state.canSubmit) {
                // Check the current central policy again, not only a previously stored label.
                StrategicDiscountPolicy.Input input=new StrategicDiscountPolicy.Input();
                input.amount=context.deal.Amount; input.discountPercent=context.deal.Discount__c;
                input.strategicDeal=context.deal.Strategic_Deal__c;
                input.regionalVpApproverId=context.deal.Regional_VP_Approver__c;
                StrategicDiscountPolicy.Output result=StrategicDiscountPolicy.evaluate(new List<StrategicDiscountPolicy.Input>{input})[0];
                if(result.desiredStatus!='Pending Regional VP' || result.ruleVersion!=context.deal.Policy_Rule_Version__c) { throw safeError(); }
                Approval.ProcessSubmitRequest submit=new Approval.ProcessSubmitRequest();
                submit.setObjectId(opportunityId); submit.setSubmitterId(UserInfo.getUserId());
                submit.setProcessDefinitionNameOrId(PROCESS); submit.setSkipEntryCriteria(false);
                request=submit;
            } else if(((action=='Approve' || action=='Reject') && state.canDecide) || (action=='Recall' && state.canRecall)) {
                Approval.ProcessWorkitemRequest decision=new Approval.ProcessWorkitemRequest();
                decision.setWorkitemId(context.workItemId);
                decision.setAction(action=='Recall'?'Removed':action);
                request=decision;
            } else { throw safeError(); }
            Approval.ProcessResult result=Approval.process(request);
            if(!result.isSuccess()) { throw safeError(); }
        } catch(Exception ignored) { Database.rollback(checkpoint); throw safeError(); }
    }
    private static Context load(Id opportunityId) {
        if(opportunityId==null || opportunityId.getSObjectType()!=Opportunity.SObjectType) { throw safeError(); }
        List<Opportunity> parents=[SELECT Id,OwnerId,Name,Amount,Discount__c,Strategic_Deal__c,
            Regional_VP_Approver__c,Regional_VP_Approver__r.IsActive,Approval_Status__c,Policy_Rule_Version__c
            FROM Opportunity WHERE Id=:opportunityId WITH USER_MODE LIMIT 1];
        if(parents.isEmpty()) { throw safeError(); }
        Context context=new Context(); context.deal=parents[0];
        // Native process data is summarized only after parent sharing/FLS authorization.
        Set<Id> definitions=new Map<Id,ProcessDefinition>([SELECT Id FROM ProcessDefinition WHERE DeveloperName=:PROCESS AND TableEnumOrId='Opportunity' WITH SYSTEM_MODE]).keySet();
        List<ProcessInstance> instances=[SELECT Id,Status,SubmittedById,
            (SELECT Id,ActorId FROM Workitems LIMIT 2),
            (SELECT StepStatus,CreatedDate FROM Steps ORDER BY CreatedDate DESC LIMIT 10)
            FROM ProcessInstance WHERE TargetObjectId=:opportunityId AND ProcessDefinitionId IN :definitions
            WITH SYSTEM_MODE ORDER BY CreatedDate DESC,Id DESC LIMIT 1];
        if(!instances.isEmpty()) {
            context.process=instances[0];
            if(context.process.Workitems.size()==1) {
                context.workItemId=context.process.Workitems[0].Id;
                context.actorId=context.process.Workitems[0].ActorId;
            }
        }
        return context;
    }
    private static State view(Context context) {
        State state=new State(); Opportunity deal=context.deal;
        Boolean pending=context.process!=null && context.process.Status=='Pending';
        Boolean separate=deal.Regional_VP_Approver__c!=null && deal.Regional_VP_Approver__c!=deal.OwnerId && deal.Regional_VP_Approver__r.IsActive;
        state.needsSeparateApprover=!separate;
        state.status=context.process==null?'Not submitted':context.process.Status;
        // This process always locks pending requests; no org-wide Apex lock/unlock API is needed.
        state.locked=pending;
        state.canSubmit=!state.locked && !pending && deal.OwnerId==UserInfo.getUserId() && separate && deal.Name.startsWith('SYN-') && deal.Approval_Status__c=='Pending Regional VP';
        state.canDecide=pending && context.workItemId!=null && context.actorId==UserInfo.getUserId() && context.process.SubmittedById!=UserInfo.getUserId();
        state.canRecall=pending && context.workItemId!=null && context.process.SubmittedById==UserInfo.getUserId();
        state.history=new List<HistoryRow>();
        if(context.process!=null) {
            for(ProcessInstanceStep step:context.process.Steps) {
                HistoryRow row=new HistoryRow(); row.status=step.StepStatus; row.occurredAt=step.CreatedDate;
                state.history.add(row);
            }
        }
        return state;
    }
    private static AuraHandledException safeError() {
        String message='Approval action unavailable. Check record access, ownership, assigned approver, current policy and approval state, then refresh.';
        AuraHandledException error=new AuraHandledException(message); error.setMessage(message); return error;
    }
}
