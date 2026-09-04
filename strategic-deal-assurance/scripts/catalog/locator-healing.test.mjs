import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {buildArtifacts} from './build-project-index.mjs';

const read=p=>fs.readFileSync(new URL('../../'+p,import.meta.url),'utf8');
const suite=JSON.parse(read('data/locator-healing-suite.json'));
const bundle='force-app/main/default/lwc/strategicDealWorkbench/strategicDealWorkbench';
test('six supplemental locator cases have complete actions and independent expected outcomes',()=>{
  assert.equal(suite.status,'NOT_RUN_BROWSER_SPECIFICATION');
  assert.deepEqual(suite.cases.map(c=>c.id),['LH-01','LH-02','LH-03','LH-04','LH-05','LH-06']);
  assert.equal(suite.cases.reduce((n,c)=>n+c.steps.length,0),20);
  for(const c of suite.cases) { assert.ok(c.objective && c.actor); for(const s of c.steps) assert.ok(s.action && s.expected); }
  assert.equal(suite.fixture.Amount,60000000);assert.equal(suite.fixture.Discount__c,15);
  assert.equal(suite.acceptance.wrongFieldWrites,0);assert.equal(suite.acceptance.healerImplementedHere,false);
  assert.equal(suite.implementationStatus.targetCount,9);
  assert.equal(suite.implementationStatus.universalXPathFailureGuaranteed,false);
  assert.equal(suite.implementationStatus.advancedNoExplicitHintVariant,'proposed; not implemented');
});
test('presentation exposes three variants and stable metadata hints without broad deployment',()=>{
  const xml=read(bundle+'.js-meta.xml'),html=read(bundle+'.html');
  assert.equal((xml.match(/datasource="baseline,reordered,regrouped"/g)||[]).length,2);
  assert.match(html,/data-field-api=\{field.apiName\}/);
  assert.match(html,/field-name=\{field.apiName\}/);
  assert.match(html,/data-action="save-evaluate"/);
  const scope=read('manifest/milestone-8-locator-demo.xml');
  assert.deepEqual([...scope.matchAll(/<members>([^<]+)<\/members>/g)].map(m=>m[1]),['strategicDealWorkbench']);
  assert.doesNotMatch(scope,/PermissionSet|CustomMetadata|FlexiPage|Profile/);
});
test('discovery graph links six cases, eight fields and both independently configured pages',()=>{
  const graph=JSON.parse(buildArtifacts().get('strategic-deal-assurance/knowledge/application-graph.json'));
  assert.equal(graph.nodes.filter(n=>n.kind==='locator-use-case').length,6);
  assert.deepEqual(graph.nodes.find(n=>n.id==='config:workbench.locatorVariant').implementationStatus,suite.implementationStatus);
  const edges=graph.edges.filter(e=>e.from==='config:workbench.locatorVariant'&&e.relation==='changes_locator_for');
  assert.deepEqual(edges.map(e=>e.to).sort(),suite.fields.map(f=>'field:Opportunity.'+f).sort());
  assert.equal(graph.edges.filter(e=>e.to==='config:workbench.locatorVariant'&&e.relation==='offers_configuration').length,2);
});
