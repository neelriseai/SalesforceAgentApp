import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {buildArtifacts,repoRoot,trackedCandidates} from './build-project-index.mjs';

const artifacts=buildArtifacts();
const graph=JSON.parse(artifacts.get('strategic-deal-assurance/knowledge/application-graph.json'));
const index=JSON.parse(artifacts.get('strategic-deal-assurance/knowledge/project-index.json'));
test('catalog generation is deterministic',()=>assert.deepEqual([...buildArtifacts()],[...artifacts]));
test('node identities and edge targets are valid',()=>{
  const ids=new Set(graph.nodes.map(n=>n.id));
  assert.equal(ids.size,graph.nodes.length);
  assert.equal(new Set(graph.edges.map(e=>e.id)).size,graph.edges.length);
  for(const e of graph.edges) {assert.ok(ids.has(e.from));assert.ok(ids.has(e.to));}
});
test('every indexed source and reading entry exists',()=>{
  for(const row of index.files) {assert.ok(fs.existsSync(path.join(repoRoot,row.path)));assert.match(row.sha256NormalizedLf,/^[0-9a-f]{64}$/);}
  for(const p of index.readOrder) assert.ok(fs.existsSync(path.join(repoRoot,p)) || artifacts.has(p));
});
test('graph includes fixture population and all 42 manual cases and new rules',()=>{
  assert.equal(graph.nodes.filter(n=>n.kind==='synthetic-fixture').length,554);
  assert.equal(graph.nodes.filter(n=>n.kind==='saved-report').length,5);
  assert.equal(graph.nodes.filter(n=>n.kind==='list-view').length,3);
  assert.equal(graph.nodes.filter(n=>n.kind==='manual-use-case').length,42);
  assert.equal(graph.nodes.filter(n=>n.kind==='permission-set').length,6);
  assert.equal(graph.nodes.filter(n=>n.kind==='apex-test').length,6);
  assert.equal(graph.nodes.filter(n=>n.kind==='apex-trigger').length,7);
  assert.equal(graph.nodes.filter(n=>n.id.startsWith('config:Demo_Business_Rule.')).length,8);
});
test('integration limitations and strict boundaries are represented',()=>{
  const req=graph.nodes.find(n=>n.id==='requirement:BR-STRATEGIC-DISCOUNT');
  assert.equal(req.discountComparison,'>');assert.equal(req.discount,15);assert.equal(req.amount,50000000);
  const contract=JSON.parse(fs.readFileSync(path.join(repoRoot,'strategic-deal-assurance/contracts/agent-interface.json'),'utf8'));
  assert.equal(contract.capabilities.find(c=>c.id==='api.custom.rest').status,'deployed; hackathon-administrator HTTP 200 smoke test passed; dedicated-identity validation pending');
  assert.equal(contract.capabilities.find(c=>c.id==='api.custom.rest').directEvidenceCrud,false);
  assert.equal(contract.opportunity.automaticSubmission,false);
  assert.ok(graph.edges.some(e=>e.from==='flow:Strategic_Discount_Approval' && e.relation==='appends' && e.to==='object:Strategic_Deal_Evaluation__c'));
});
test('publish candidates exclude local auth, raw data and secrets',()=>{
  for(const p of trackedCandidates()) {
    assert.doesNotMatch(p,/(^|\/)(\.sf|\.sfdx|artifacts|node_modules|browser-profiles|\.git)(\/|$)/);
    assert.ok(!/(^|\/)\.env($|\.)/.test(p) || p.endsWith('.env.example'));
    const body=fs.readFileSync(path.join(repoRoot,p),'utf8');
    // Report paths only, never echo a suspected credential or full source body.
    assert.ok(!/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(body),'Private-key pattern in '+p);
    assert.ok(!/gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}/.test(body),'GitHub token pattern in '+p);
    assert.ok(!/https?:\/\/[^\s"']+\/(?:secur\/frontdoor\.jsp\?sid=|_ui\/.*[?&](?:token|sid)=)/i.test(body),'Session-URL pattern in '+p);
    const ids=[...body.matchAll(/\b00[156D][A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?\b/g)].map(m=>m[0]);
    const knownMockRecords=new Set(['006'+'000000000001AAA','006'+'000000000002AAA']);
    const unitTest=p.endsWith('StrategicDealPolicyControllerTest.cls') || (p.includes('/__tests__/') && p.endsWith('.test.js'));
    assert.ok(ids.every(id=>unitTest && knownMockRecords.has(id)),'Unexpected Salesforce identifier in '+p);
  }
});
test('Markdown relative links resolve inside the repository',()=>{
  for(const p of trackedCandidates().filter(p=>p.endsWith('.md'))) {
    const body=fs.readFileSync(path.join(repoRoot,p),'utf8');
    for(const match of body.matchAll(/\[[^\]\n]*\]\(([^)\n]+)\)/g)) {
      const href=match[1].replace(/^<|>$/g,'').split('#')[0];
      if(!href || /^[a-z]+:/i.test(href)) continue;
      const target=path.resolve(repoRoot,path.dirname(p),decodeURIComponent(href));
      assert.ok(target.startsWith(repoRoot+path.sep),'Link escapes repository: '+p);
      assert.ok(fs.existsSync(target),'Broken relative link in '+p+': '+href);
    }
  }
});
