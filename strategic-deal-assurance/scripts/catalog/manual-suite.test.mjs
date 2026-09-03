import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const suite=JSON.parse(fs.readFileSync(path.join(root,'data/manual-test-suite.json'),'utf8'));
test('manual cases have unique IDs, steps, fixtures, cleanup and honest status',()=>{
  assert.equal(new Set(suite.cases.map(c=>c.id)).size,suite.cases.length);
  assert.equal(suite.cases.length,42);
  for(const c of suite.cases) {
    for(const key of ['id','objective','actor','precondition','cleanup','evidence','negative']) assert.ok(c[key],`${c.id} ${key}`);
    assert.ok(c.fixtures.length); assert.ok(c.steps.length>=3);
    for(const step of c.steps) assert.ok(step.length===2 && step.every(v=>typeof v==='string' && v.length>10));
    assert.equal(c.executionStatus,'NOT_RUN');
  }
});
test('every approved rule has metadata, default disabled, mapped trigger and tests',()=>{
  assert.equal(suite.rules.length,8);
  for(const r of suite.rules) {
    const xml=fs.readFileSync(path.join(root,`force-app/main/default/customMetadata/Demo_Business_Rule.${r.key}.md-meta.xml`),'utf8');
    assert.match(xml,/<field>Enabled__c<\/field><value xsi:type="xsd:boolean">false<\/value>/);
    assert.ok(fs.existsSync(path.join(root,`force-app/main/default/triggers/${r.trigger}.trigger`)));
    assert.ok(suite.cases.some(c=>c.id.startsWith('RULE-') && c.ruleKeys.includes(r.key)));
  }
});
test('independent strategic boundary assertions remain explicit',()=>{
  const exact=suite.cases.find(c=>c.id==='POLICY-03');
  assert.equal(exact.data.Discount__c,15); assert.equal(exact.data.expectedStatus,'Not Required');
  const above=suite.cases.find(c=>c.id==='POLICY-04');
  assert.equal(above.data.Discount__c,15.01); assert.equal(above.data.expectedStatus,'Pending Regional VP');
});
