/** BR-STRATEGIC-DISCOUNT: read-only DTO boundary for the policy card. */
public with sharing class StrategicDealPolicyController {
    public class PolicyView {
        @AuraEnabled public String status;
        @AuraEnabled public String reason;
        @AuraEnabled public String appliedRuleVersion;
        @AuraEnabled public Datetime evaluatedAt;
        @AuraEnabled public String activeRuleVersion;
        @AuraEnabled public Decimal amountThreshold;
        @AuraEnabled public Decimal discountThreshold;
        @AuraEnabled public Boolean ruleActive;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public List<EvaluationView> history;
    }
    public class EvaluationView {
        @AuraEnabled public String outcome;
        @AuraEnabled public String ruleVersion;
        @AuraEnabled public Datetime evaluatedAt;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal discount;
    }

    @AuraEnabled(cacheable=true)
    public static PolicyView getPolicy(Id opportunityId) {
        try {
            if (opportunityId == null || opportunityId.getSObjectType() != Opportunity.SObjectType) {
                throw safeError();
            }
            // Authorize record sharing AND all returned Opportunity fields before reading history.
            List<Opportunity> parents = [SELECT Approval_Status__c, Approval_Reason__c,
                Policy_Rule_Version__c, Policy_Evaluated_At__c, Amount, Discount__c FROM Opportunity
                WHERE Id=:opportunityId WITH USER_MODE LIMIT 1];
            if (parents.isEmpty()) { throw safeError(); }
            Opportunity parent=parents[0];
            PolicyView view=new PolicyView();
            view.status=parent.Approval_Status__c;
            view.reason=parent.Approval_Reason__c;
            view.appliedRuleVersion=parent.Policy_Rule_Version__c;
            view.evaluatedAt=parent.Policy_Evaluated_At__c;
            view.currencyCode='USD';
            Strategic_Discount_Rule__mdt rule=Strategic_Discount_Rule__mdt.getInstance('Default');
            view.ruleActive=rule != null && rule.Active__c == true;
            if (rule != null) {
                view.activeRuleVersion=rule.Rule_Version__c;
                view.amountThreshold=rule.Minimum_Amount_INR__c;
                view.discountThreshold=rule.Discount_Threshold_Percent__c;
            }
            // Private-only helper cannot be invoked by the client independently of the parent gate.
            view.history=new AuthorizedHistoryReader().read(opportunityId);
            return view;
        } catch (Exception ignored) {
            throw safeError();
        }
    }

    private static AuraHandledException safeError() {
        String message='Policy information is unavailable or you do not have access.';
        AuraHandledException error=new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }

    // Deliberate, narrow privilege elevation: evidence is not directly readable by ordinary users.
    // Only getPolicy calls this after a WITH USER_MODE parent/field check. No writes or IDs in DTOs.
    private without sharing class AuthorizedHistoryReader {
        public List<EvaluationView> read(Id authorizedOpportunityId) {
            List<EvaluationView> summaries=new List<EvaluationView>();
            for (Strategic_Deal_Evaluation__c row : [SELECT Outcome__c, Rule_Version__c,
                Evaluated_At__c, Amount_INR__c, Discount_Percent__c
                FROM Strategic_Deal_Evaluation__c WHERE Opportunity__c=:authorizedOpportunityId
                WITH SYSTEM_MODE ORDER BY Evaluated_At__c DESC, CreatedDate DESC, Id DESC LIMIT 5]) {
                EvaluationView item=new EvaluationView();
                item.outcome=row.Outcome__c; item.ruleVersion=row.Rule_Version__c;
                item.evaluatedAt=row.Evaluated_At__c; item.amount=row.Amount_INR__c;
                item.discount=row.Discount_Percent__c; summaries.add(item);
            }
            return summaries;
        }
    }
}
