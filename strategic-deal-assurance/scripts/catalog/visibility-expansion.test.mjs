import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const plan=JSON.parse(fs.readFileSync(path.join(root,'data/visibility-expansion-plan.json'),'utf8'));
const baseline=JSON.parse(fs.readFileSync(path.join(root,'data/multi-module-plan.json'),'utf8'));
test('186 new records have unique keys and do not overwrite baseline keys',()=>{
 const all=Object.values(plan.objects).flat(), keys=new Set(all.map(r=>r.key));
 assert.equal(all.length,186);assert.equal(keys.size,186);
 const oldKeys=new Set(Object.values(baseline.objects).flat().map(r=>r.key));
 for(const r of all)assert.equal(oldKeys.has(r.key),false);
 for(const [object,rows]of Object.entries(plan.objects))assert.equal(rows.length,plan.expectedCounts[object]);
 for(const r of all)for(const v of Object.values(r.fields))if(typeof v==='string'&&v.startsWith('@'))assert.ok(v==='@operator'||keys.has(v.slice(1)));
});
test('all expansion cases/tasks and campaign members have valid planned relationships',()=>{
 const rows=new Map(Object.values(plan.objects).flat().map(r=>[r.key,r]));
 for(const c of plan.objects.Case)assert.equal(rows.get(c.fields.ContactId.slice(1)).fields.AccountId,c.fields.AccountId);
 for(const t of plan.objects.Task)assert.equal(rows.get(t.fields.WhatId.slice(1)).fields.ContactId,t.fields.WhoId);
 for(const c of plan.objects.Campaign)assert.equal(plan.objects.CampaignMember.filter(m=>m.fields.CampaignId==='@'+c.key).length,10);
 assert.equal(plan.objects.Task.filter(t=>t.fields.Status==='Completed').length,20);
 assert.equal(plan.objects.Case.filter(c=>c.fields.Status==='Closed').length,10);
 assert.equal(plan.objects.Campaign.filter(c=>!c.fields.IsActive).length,2);
});
test('saved reports filter synthetic names and list views have no date restrictions',()=>{
 for(const object of ['Case','Task','Campaign']){
   const dir=path.join(root,'force-app/main/default/objects',object,'listViews');
   const xml=fs.readFileSync(path.join(dir,fs.readdirSync(dir).find(f=>f.startsWith('SDA_Demo'))),'utf8');
   assert.match(xml,/<filterScope>Everything<\/filterScope>/);assert.match(xml,/<value>SYN-MM-<\/value>/);
   assert.doesNotMatch(xml,/TODAY|LAST_N_DAYS|THIS_WEEK/);
 }
 const reports=path.join(root,'force-app/main/default/reports/SDA_Demo_Reports');
 assert.equal(fs.readdirSync(reports).length,5);
 for(const f of fs.readdirSync(reports))assert.match(fs.readFileSync(path.join(reports,f),'utf8'),/<value>SYN-MM-<\/value>/);
});
