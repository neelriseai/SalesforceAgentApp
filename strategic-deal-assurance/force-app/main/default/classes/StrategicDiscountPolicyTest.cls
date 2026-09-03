/** BR-STRATEGIC-DISCOUNT; framework=apex; independent baseline-15 oracles. */
@IsTest
private class StrategicDiscountPolicyTest {
    private static StrategicDiscountPolicy.Input request(Boolean strategic, Decimal amount,
        Decimal discount, String approver) {
        StrategicDiscountPolicy.Input value = new StrategicDiscountPolicy.Input();
        value.strategicDeal = strategic;
        value.amount = amount;
        value.discountPercent = discount;
        value.regionalVpApproverId = approver;
        return value;
    }

    private static StrategicDiscountPolicy.Output baseline(StrategicDiscountPolicy.Input value) {
        return StrategicDiscountPolicy.evaluateOne(value, 50000000, 15, true, 'baseline-15');
    }

    private static void assertOutcome(StrategicDiscountPolicy.Output result,
        Boolean required, String status) {
        System.assertEquals(required, result.approvalRequired, 'Approval flag');
        System.assertEquals(status, result.desiredStatus, 'Policy outcome');
        System.assertEquals(true, result.configurationValid, 'Valid policy configuration');
        System.assertEquals('baseline-15', result.ruleVersion, 'Applied rule version');
        System.assertEquals(64, result.inputHash.length(), 'SHA-256 hex length');
        System.assertNotEquals(null, result.evaluatedAt, 'Evaluation time');
        System.assert(!String.isBlank(result.reason), 'Meaningful explanation');
    }

    // OBL-AMOUNT-EXACT
    @IsTest static void exactAmountDoesNotRequireApproval() {
        assertOutcome(baseline(request(true, 50000000, 20, 'approver-a')), false, 'Not Required');
        assertOutcome(baseline(request(true, 49999999.99, 20, 'approver-a')), false, 'Not Required');
    }

    // OBL-DISCOUNT-EXACT
    @IsTest static void exactDiscountDoesNotRequireApproval() {
        assertOutcome(baseline(request(true, 50000000.01, 15, 'approver-a')), false, 'Not Required');
        assertOutcome(baseline(request(true, 60000000, 14.99, 'approver-a')), false, 'Not Required');
    }

    // OBL-DISCOUNT-ABOVE
    @IsTest static void aboveBothBoundariesRequiresApproval() {
        StrategicDiscountPolicy.Output result = baseline(request(true, 50000000.01, 15.01, 'approver-a'));
        assertOutcome(result, true, 'Pending Regional VP');
        System.assert(result.reason.contains('50000000.00'), 'Reason includes amount boundary');
        System.assert(result.reason.contains('USD'), 'User-approved USD policy, no FX conversion');
        System.assert(!result.reason.contains('INR'), 'No legacy currency in user-facing explanation');
        System.assert(result.reason.contains('15.00%'), 'Reason includes discount boundary');
    }

    // OBL-NON-STRATEGIC
    @IsTest static void nonStrategicIsNotRouted() {
        assertOutcome(baseline(request(false, 60000000, 20, null)), false, 'Not Required');
        assertOutcome(baseline(request(null, 60000000, 20, null)), false, 'Not Required');
    }

    // OBL-MISSING-APPROVER
    @IsTest static void missingAndBlankApproverFailClosed() {
        for (String approver : new List<String>{null, '', '   '}) {
            StrategicDiscountPolicy.Output result = baseline(request(true, 60000000, 20, approver));
            assertOutcome(result, true, 'Configuration Error');
            System.assert(result.reason.contains('no approver'), 'Missing approver explanation');
        }
    }

    // OBL-NULL-INPUT
    @IsTest static void optionalNullInputsAreSafe() {
        assertOutcome(baseline(null), false, 'Not Required');
        assertOutcome(baseline(request(true, null, 20, null)), false, 'Not Required');
        assertOutcome(baseline(request(true, 60000000, null, null)), false, 'Not Required');
        System.assertEquals(0, StrategicDiscountPolicy.evaluate(null).size(), 'Null batch is empty');
        System.assertEquals(0, StrategicDiscountPolicy.evaluate(new List<StrategicDiscountPolicy.Input>()).size(), 'Empty batch');
    }

    private static void assertBadConfig(Decimal amount, Decimal discount, Boolean active, String version) {
        StrategicDiscountPolicy.Output result = StrategicDiscountPolicy.evaluateOne(
            request(true, 60000000, 20, 'approver-a'), amount, discount, active, version);
        System.assertEquals(false, result.configurationValid, 'Configuration must fail closed');
        System.assertEquals('Configuration Error', result.desiredStatus, 'Never silently approve invalid configuration');
        System.assertEquals(false, result.approvalRequired, 'No numeric decision from invalid policy');
        System.assert(result.reason.contains('configuration'), 'Configuration error reason');
    }

    // OBL-INVALID-CONFIG
    @IsTest static void invalidConfigurationFailsClosed() {
        assertBadConfig(null, null, false, null);
        assertBadConfig(50000000, 15, false, 'baseline-15');
        assertBadConfig(50000000, 15, null, 'baseline-15');
        assertBadConfig(null, 15, true, 'baseline-15');
        assertBadConfig(-1, 15, true, 'baseline-15');
        assertBadConfig(50000000, null, true, 'baseline-15');
        assertBadConfig(50000000, -1, true, 'baseline-15');
        assertBadConfig(50000000, 101, true, 'baseline-15');
        assertBadConfig(50000000, 15, true, ' ');
    }

    // OBL-HASH
    @IsTest static void hashesAreStableNormalizedAndNonIdentifying() {
        StrategicDiscountPolicy.Output first = baseline(request(true, Decimal.valueOf('60000000.0'), Decimal.valueOf('20.0'), 'approver-a'));
        StrategicDiscountPolicy.Output second = baseline(request(true, Decimal.valueOf('60000000.00'), Decimal.valueOf('20.00'), 'approver-b'));
        System.assertEquals(first.inputHash, second.inputHash, 'Scale and present approver identity must not change hash');
        System.assertEquals(first.desiredStatus, second.desiredStatus, 'Stable decision');
        System.assertEquals(first.reason, second.reason, 'Stable explanation');
        System.assert(!first.reason.contains('approver-a'), 'No approver identity in reason');
        System.assertNotEquals(first.inputHash, baseline(request(true, 60000000, 20, null)).inputHash, 'Approver presence is material');
        System.assertNotEquals(first.inputHash, baseline(request(true, 60000000.01, 20, 'a')).inputHash, 'Amount is material');
        System.assertNotEquals(first.inputHash, baseline(request(true, 60000000, 20.01, 'a')).inputHash, 'Discount is material');
        System.assertNotEquals(first.inputHash, baseline(request(false, 60000000, 20, 'a')).inputHash, 'Strategic flag is material');
    }

    // OBL-BULK: actual deployed Custom Metadata, not injected test-only policy.
    @IsTest static void deployedBaselineHandlesTwoHundredOrderedInputs() {
        List<StrategicDiscountPolicy.Input> inputs = new List<StrategicDiscountPolicy.Input>();
        for (Integer i = 0; i < 200; i++) {
            inputs.add(request(Math.mod(i, 2) == 0, 60000000, 20, 'approver-a'));
        }
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();
        List<StrategicDiscountPolicy.Output> results = StrategicDiscountPolicy.evaluate(inputs);
        System.assertEquals(queriesBefore, Limits.getQueries(), 'No SOQL queries');
        System.assertEquals(dmlBefore, Limits.getDmlStatements(), 'Pure evaluation performs no DML');
        Test.stopTest();
        System.assertEquals(200, results.size(), 'One result per input');
        for (Integer i = 0; i < 200; i++) {
            Boolean required = Math.mod(i, 2) == 0;
            assertOutcome(results[i], required, required ? 'Pending Regional VP' : 'Not Required');
        }
    }

    // OBL-AMOUNT-EXACT, OBL-DISCOUNT-EXACT/ABOVE: independent deployed-config oracles.
    @IsTest static void deployedConfigMatchesFifteenPercentContract() {
        Strategic_Discount_Rule__mdt config = Strategic_Discount_Rule__mdt.getInstance('Default');
        System.assertNotEquals(null, config, 'Default custom metadata is deployed');
        System.assertEquals(true, config.Active__c, 'Policy active');
        System.assertEquals(50000000, config.Minimum_Amount_INR__c, 'Independent amount oracle');
        System.assertEquals(15, config.Discount_Threshold_Percent__c, 'Independent discount oracle');
        List<StrategicDiscountPolicy.Output> results = StrategicDiscountPolicy.evaluate(new List<StrategicDiscountPolicy.Input>{
            request(true, 50000000, 20, 'a'),
            request(true, 50000000.01, 15, 'a'),
            request(true, 50000000.01, 15.01, 'a'),
            request(true, 60000000, 20, null),
            request(true, 60000000, 10.01, 'a'),
            null
        });
        System.assertEquals(6, results.size(), 'Preserve null input position');
        assertOutcome(results[0], false, 'Not Required');
        assertOutcome(results[1], false, 'Not Required');
        assertOutcome(results[2], true, 'Pending Regional VP');
        assertOutcome(results[3], true, 'Configuration Error');
        assertOutcome(results[4], false, 'Not Required');
        assertOutcome(results[5], false, 'Not Required');
    }
}
