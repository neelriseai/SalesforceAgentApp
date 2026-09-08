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
});
test('REST source is read-only, bounded and parent-gated',()=>{
  const body=read('force-app/main/default/classes/StrategicDealAgentApi.cls');
  assert.match(body,/@RestResource\(urlMapping='\/sda\/v1\/policy\/\*'\)/);
  assert.match(body,/@HttpGet/);assert.doesNotMatch(body,/@HttpPost|@HttpPatch|@HttpDelete/);
  assert.match(body,/FROM Opportunity WHERE Id=:opportunityId WITH USER_MODE LIMIT 1/);
  assert.match(body,/MAX_LIMIT=50/);assert.match(body,/Cache-Control','no-store/);
  assert.match(body,/WHERE Opportunity__c=:opportunityId[\s\S]*WITH SYSTEM_MODE/);
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
