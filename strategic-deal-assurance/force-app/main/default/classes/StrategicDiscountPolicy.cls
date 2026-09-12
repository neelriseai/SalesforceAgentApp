/** BR-STRATEGIC-DISCOUNT: deterministic, bulk-safe policy; no record writes. */
public with sharing class StrategicDiscountPolicy {
    public class Input {
        @InvocableVariable(label='Opportunity Amount')
        public Decimal amount;
        @InvocableVariable(label='Discount Percent')
        public Decimal discountPercent;
        @InvocableVariable(label='Strategic Deal')
        public Boolean strategicDeal;
        @InvocableVariable(label='Regional VP Approver Id')
        public String regionalVpApproverId;
    }

    public class Output {
        @InvocableVariable public Boolean approvalRequired;
        @InvocableVariable public Boolean configurationValid;
        @InvocableVariable public String desiredStatus;
        @InvocableVariable public String reason;
        @InvocableVariable public String ruleVersion;
        @InvocableVariable public Datetime evaluatedAt;
        @InvocableVariable public String inputHash;
    }

    @InvocableMethod(label='Evaluate Strategic Discount Approval'
        description='BR-STRATEGIC-DISCOUNT: evaluates central policy without modifying records.')
    public static List<Output> evaluate(List<Input> inputs) {
        List<Output> results = new List<Output>();
        if (inputs == null || inputs.isEmpty()) {
            return results;
        }
        Strategic_Discount_Rule__mdt config = Strategic_Discount_Rule__mdt.getInstance('Default');
        Decimal minimumAmount = config == null ? null : config.Minimum_Amount_INR__c;
        Decimal threshold = config == null ? null : config.Discount_Threshold_Percent__c;
        String ruleVersion = config == null ? null : config.Rule_Version__c;
        Boolean active = config != null && config.Active__c == true;
        for (Input request : inputs) {
            results.add(evaluateOne(request, minimumAmount, threshold, active, ruleVersion));
        }
        return results;
    }

    @TestVisible
    private static Output evaluateOne(Input request, Decimal minimumAmount,
        Decimal threshold, Boolean active, String ruleVersion) {
        Output result = new Output();
        result.approvalRequired = false;
        result.configurationValid = false;
        result.ruleVersion = ruleVersion;
        result.evaluatedAt = System.now();
        result.inputHash = hashInput(request);

        if (active != true || minimumAmount == null || minimumAmount < 0
            || threshold == null || threshold < 0 || threshold > 100
            || String.isBlank(ruleVersion)) {
            result.desiredStatus = 'Configuration Error';
            result.reason = 'Strategic discount policy configuration is missing, inactive, or invalid.';
            return result;
        }
        result.configurationValid = true;
        result.approvalRequired = request != null && request.strategicDeal == true
            && request.amount != null && request.amount > minimumAmount
            && request.discountPercent != null && request.discountPercent >= threshold;
        if (result.approvalRequired && String.isBlank(request.regionalVpApproverId)) {
            result.desiredStatus = 'Configuration Error';
            result.reason = 'Regional VP approval is required, but no approver is configured.';
        } else if (result.approvalRequired) {
            result.desiredStatus = 'Pending Regional VP';
            result.reason = 'Strategic deal exceeds USD ' + canonicalDecimal(minimumAmount)
                + ' and discount threshold ' + canonicalDecimal(threshold)
                + '%. Regional VP approval is required.';
        } else {
            result.desiredStatus = 'Not Required';
            result.reason = 'The Opportunity does not exceed every configured strategic approval boundary.';
        }
        return result;
    }

    private static String canonicalDecimal(Decimal value) {
        return value == null ? 'null' : String.valueOf(value.setScale(2));
    }

    private static String hashInput(Input request) {
        String normalized = 'null';
        if (request != null) {
            normalized = String.join(new List<String>{
                String.valueOf(request.strategicDeal == true),
                canonicalDecimal(request.amount),
                canonicalDecimal(request.discountPercent),
                String.valueOf(!String.isBlank(request.regionalVpApproverId))
            }, '|');
        }
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(normalized)));
    }
}
