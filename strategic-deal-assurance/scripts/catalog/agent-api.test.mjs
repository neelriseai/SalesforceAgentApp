import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {buildArtifacts} from './build-project-index.mjs';

const read=p=>fs.readFileSync(new URL('../../'+p,import.meta.url),'utf8');
const suite=JSON.parse(read('data/agent-api-test-suite.json'));
test('external API specification has six honest, non-destructive cases',()=>{
  assert.equal(suite.status,'NOT_RUN_EXTERNAL_API_SPECIFICATION');
  assert.deepEqual(suite.cases.map(c=>c.id),['API-01','API-02','API-03','API-04','API-05','API-06']);
  for(const c of suite.cases){assert.ok(c.objective);assert.ok(c.steps.length>=3);}
  assert.equal(suite.acceptance.directEvidenceCrud,false);
  assert.equal(suite.acceptance.deleteGranted,false);
  assert.equal(suite.acceptance.metadataAdminGranted,false);
  assert.equal(suite.responseSchemaVersion,'1.1.0');
  assert.match(suite.acceptance.deploymentStatus,/local candidate/);
  assert.match(suite.acceptance.hackathonAdministratorSmokeStatus,/not run for response schema 1\.1\.0/);
  assert.match(suite.acceptance.dedicatedIdentitySuiteStatus,/not run/);
});
test('REST source is read-only, bounded and parent-gated',()=>{
  const body=read('force-app/main/default/classes/StrategicDealAgentApi.cls');
  assert.match(body,/@RestResource\(urlMapping='\/sda\/v1\/policy\/\*'\)/);
  assert.match(body,/@HttpGet/);assert.doesNotMatch(body,/@HttpPost|@HttpPatch|@HttpDelete/);
  assert.match(body,/FROM Opportunity WHERE Id=:opportunityId WITH USER_MODE LIMIT 1/);
  assert.match(body,/MAX_LIMIT=50/);assert.match(body,/Cache-Control','no-store/);
  assert.match(body,/WHERE Opportunity__c=:opportunityId[\s\S]*WITH SYSTEM_MODE/);
});
test('schema 1.1 source binds every response to the authorized requested parent',()=>{
  const body=read('force-app/main/default/classes/StrategicDealAgentApi.cls');
  const contract=JSON.parse(read('contracts/agent-interface.json'));
  const api=contract.capabilities.find(value=>value.id==='api.custom.rest');
  assert.match(body,/'schemaVersion'=>'1\.1\.0'/);
  assert.match(body,/'id'=>opportunityId/);
  assert.match(body,/'opportunityId'=>opportunityId/);
  assert.doesNotMatch(body,/'(?:ownerId|userId|callerId)'\s*=>/i);
  assert.equal(api.responseSchemaVersion,'1.1.0');
  assert.match(api.deploymentStatus,/local candidate/);
  const tests=read('force-app/main/default/classes/StrategicDealAgentApiTest.cls');
  for(const method of ['allHistoryRowsBindOnlyRequestedParent','deletedAndInaccessibleParentsHaveIdenticalSafeResponse'])
    assert.ok(tests.includes('@IsTest static void '+method+'()'));
  assert.match(tests,/System\.assertEquals\('1\.1\.0',body\.get\('schemaVersion'\)\)/);
});
test('source operations cover all independently owned baseline members without embedded IDs',()=>{
  const operations=JSON.parse(read('contracts/source-operations.json'));
  const baseline=JSON.parse(read('data/baseline-15-plan.json'));
  const dataset=operations.syntheticDatasets[0];
  const markers=dataset.predicates.find(value=>value.field==='NextStep');
  assert.equal(dataset.identityField,'Id');
  assert.equal(dataset.exactCardinality,baseline.cases.length);
  assert.deepEqual(markers.values,baseline.cases.map(value=>baseline.dataset+'|'+value.key).sort());
  assert.deepEqual(dataset.predicates.find(value=>value.field==='OwnerId'),
    {field:'OwnerId',operator:'EQUALS',valueSource:'CURRENT_ENROLLED_ACTOR',values:[]});
  for(const operation of [...operations.standardRest,...operations.customRest]){
    assert.equal(operation.requestExpansion,'EACH_DATASET_RECORD');
    assert.equal(operation.datasetId,dataset.datasetId);
    assert.equal(operation.minimumCardinality,1);assert.equal(operation.maximumCardinality,1);
    for(const field of operation.responseFields){assert.equal(typeof field.required,'boolean');assert.equal(typeof field.nullable,'boolean');}
    assert.ok(operation.variables.some(value=>value.datasetField==='Id'));
  }
  assert.equal(operations.standardRest[0].responseFields.find(value=>value.path==='Amount').nullable,true);
  assert.equal(operations.standardRest[0].responseFields.find(value=>value.path==='Discount__c').nullable,true);
});
test('source custom projection explicitly binds bounded history without user exposure',()=>{
  const operation=JSON.parse(read('contracts/source-operations.json')).customRest[0];
  assert.deepEqual(operation.datasetFieldPaths,{Id:'opportunity.id'});
  assert.deepEqual(operation.responseFields.find(value=>value.path==='schemaVersion').expectedLiteral,{value:'1.1.0'});
  assert.deepEqual(operation.responseFields.find(value=>value.path==='objectApiName').expectedLiteral,{value:'Opportunity'});
  assert.deepEqual(operation.parentBindings,[{collectionPath:'history[]',parentIdPath:'opportunityId',datasetField:'Id',maximumCardinality:20}]);
  assert.ok(operation.responseFields.some(value=>value.path==='history[].opportunityId'&&value.required&&!value.nullable));
  assert.ok(operation.responseFields.some(value=>value.path==='opportunity.id'&&value.required&&!value.nullable));
  assert.ok(!operation.responseFields.some(value=>/ownerId|userId|callerId/i.test(value.path)));
});
test('every declared source node is an exact source graph identity',()=>{
  const contract=JSON.parse(read('contracts/agent-interface.json'));
  assert.deepEqual(contract.sourceOperations,{schemaVersion:'1.0.0',locator:'strategic-deal-assurance/contracts/source-operations.json'});
  const graph=JSON.parse(buildArtifacts().get('strategic-deal-assurance/knowledge/application-graph.json'));
  const operations=JSON.parse(read('contracts/source-operations.json'));
  for(const operation of [...operations.standardRest,...operations.customRest,...operations.syntheticDatasets,...operations.browserIntents])
    assert.ok(graph.nodes.some(node=>node.id===operation.sourceNodeId),operation.sourceNodeId);
});
test('integration permissions have no direct evidence, delete, all-record or metadata grant',()=>{
  const body=read('force-app/main/default/permissionsets/Change_Assurance_Integration.permissionset-meta.xml');
  assert.match(body,/<apexClass>StrategicDealAgentApi<\/apexClass>/);
  assert.doesNotMatch(body,/<object>Strategic_Deal_Evaluation__c<\/object>/);
  assert.doesNotMatch(body,/<allowDelete>true<\/allowDelete>|<viewAllRecords>true<\/viewAllRecords>|<modifyAllRecords>true<\/modifyAllRecords>|ModifyMetadata/);
  for(const object of ['Account','Contact','Lead','Opportunity','OpportunityContactRole','Case','Task','Campaign','CampaignMember']) assert.match(body,new RegExp(`<object>${object}</object>`));
});
test('graph links API cases to source and requirement',()=>{
  const graph=JSON.parse(buildArtifacts().get('strategic-deal-assurance/knowledge/application-graph.json'));
  assert.equal(graph.nodes.filter(n=>n.kind==='api-use-case').length,6);
  for(const c of suite.cases) assert.ok(graph.edges.some(e=>e.from==='use-case:'+c.id&&e.to==='apex:StrategicDealAgentApi'));
});
