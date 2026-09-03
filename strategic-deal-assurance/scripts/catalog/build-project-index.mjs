import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
export const repoRoot = path.resolve(projectRoot, '..');
const prefix = 'strategic-deal-assurance/';
const outputs = ['knowledge/application-graph.json', 'knowledge/project-index.json'].map(p => prefix + p);
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const read = p => fs.readFileSync(path.join(repoRoot, p), 'utf8').replace(/\r\n/g, '\n');
const decode = s => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&');
const blocks = (s, tag) => [...s.matchAll(new RegExp(`<${tag}(?:\\s[^>]*)?>([\\s\\S]*?)</${tag}>`, 'g'))].map(m => m[1]);
const tag = (s, name) => { const values = blocks(s, name); return values.length ? decode(values[0].trim()) : null; };
const bool = (s, name) => tag(s, name) === 'true';
const base = prefix + 'force-app/main/default/';

export function trackedCandidates() {
  return [...new Set(execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard', '-z'], {cwd:repoRoot, encoding:'utf8'}).split('\0').filter(Boolean))]
    .filter(p => fs.existsSync(path.join(repoRoot, p))).sort();
}
function category(p) {
  if (p.includes('/knowledge/')) return 'generated-discovery';
  if (p.includes('/contracts/')) return 'agent-contract';
  if (p.includes('/force-app/')) return p.includes('Test.cls') || p.includes('/__tests__/') ? 'test' : 'salesforce-source';
  if (p.includes('/evidence/')) return 'historical-evidence';
  if (p.includes('/data/')) return 'synthetic-fixture';
  if (p.includes('/manifest/')) return 'deployment-scope';
  if (p.includes('/scripts/')) return 'operator-tool';
  if (p.endsWith('.md')) return 'documentation';
  return 'configuration';
}

export function buildArtifacts() {
  const files = trackedCandidates().filter(p => !outputs.includes(p));
  const inventory = files.map(p => ({path:p, category:category(p), sha256NormalizedLf:hash(read(p))}));
  const sourceSnapshot = hash(JSON.stringify(inventory));
  const nodes = new Map(); const edges = new Map();
  function node(id, kind, label, attrs={}) {
    if (!nodes.has(id)) nodes.set(id, {id, kind, label, ...attrs});
    else Object.assign(nodes.get(id), attrs);
    return id;
  }
  function edge(from, relation, to, source, details={}) {
    const value={from, relation, to, source, ...details};
    const id='edge:'+hash(JSON.stringify(value)).slice(0,24);
    edges.set(id,{id,...value});
  }
  function object(name, source='standard-platform; verify via runtime describe') {
    if(nodes.has('object:'+name)) return 'object:'+name;
    return node('object:'+name, 'object', name, {source});
  }
  function field(fullName, attrs={}) {
    const dot=fullName.indexOf('.');
    if(dot<1) throw new Error('Field must include object: '+fullName);
    const owner=object(fullName.slice(0,dot));
    const id=node('field:'+fullName,'field',fullName,attrs);
    edge(owner,'has_field',id,attrs.source || 'source-reference');
    return id;
  }
  function sourced(id,kind,label,p,attrs={}) {
    node(id,kind,label,{source:p,...attrs}); edge(id,'defined_in','file:'+p,p); return id;
  }
  for(const item of inventory) node('file:'+item.path,'file',item.path,item);
  for(const name of ['Account','Contact','Lead','Opportunity','Case','Task','Campaign','CampaignMember','OpportunityContactRole','User','ProcessInstance','ProcessInstanceWorkitem','ProcessInstanceStep']) object(name);
  const contractPath=prefix+'contracts/agent-interface.json';
  const contract=JSON.parse(read(contractPath));
  for(const name of ['operator','vp']) node('persona:'+name,'persona',name==='vp'?'Separate Synthetic Regional VP':'Current demo operator',{source:contractPath,realUserIdIncluded:false});
  const reqPath=prefix+'requirements/BR-STRATEGIC-DISCOUNT-baseline.md';
  const req=sourced('requirement:BR-STRATEGIC-DISCOUNT','requirement','Strict USD strategic-discount rule',reqPath,{currency:'USD',amountComparison:'>',amount:50000000,discountComparison:'>',discount:15});

  // Parser is deliberately scoped to this DX metadata shape; it is not a general XML/Apex analyzer.
  for(const p of files.filter(p=>p.startsWith(base+'objects/'))) {
    const s=read(p); const parts=p.slice((base+'objects/').length).split('/'); const obj=parts[0];
    if(p.endsWith('.object-meta.xml')) {
      sourced('object:'+obj,'object',obj,p,{label:tag(s,'label'),sharingModel:tag(s,'sharingModel'),externalSharingModel:tag(s,'externalSharingModel')});
    } else if(p.endsWith('.field-meta.xml')) {
      const full=obj+'.'+tag(s,'fullName');
      const id=field(full,{source:p,type:tag(s,'type'),label:tag(s,'label'),required:bool(s,'required'),length:tag(s,'length'),precision:tag(s,'precision'),scale:tag(s,'scale'),picklistValues:blocks(s,'value').map(v=>tag(v,'fullName')).filter(Boolean)});
      edge(id,'defined_in','file:'+p,p);
      const target=tag(s,'referenceTo'); if(target) edge(id,'references',object(target),p,{relationshipName:tag(s,'relationshipName'),deleteConstraint:tag(s,'deleteConstraint')});
    }
  }
  for(const p of files.filter(p=>p.startsWith(base+'classes/') && p.endsWith('.cls'))) {
    const s=read(p), name=path.posix.basename(p,'.cls'), test=/@isTest\b/i.test(s);
    sourced('apex:'+name,test?'apex-test':'apex-class',name,p,{withSharing:/\bwith sharing class\b/.test(s),restResource:/@RestResource\b/.test(s),auraEnabled:/@AuraEnabled\b/.test(s),invocable:/@InvocableMethod\b/.test(s)});
  }
  const policy='apex:StrategicDiscountPolicy'; const flow='flow:Strategic_Discount_Approval';
  const policyPath=base+'classes/StrategicDiscountPolicy.cls';
  const flowPath=base+'flows/Strategic_Discount_Approval.flow-meta.xml';
  const metadataPath=base+'customMetadata/Strategic_Discount_Rule.Default.md-meta.xml';
  const config=sourced('config:Strategic_Discount_Rule.Default','custom-metadata-record','baseline-15 policy configuration',metadataPath,{values:Object.fromEntries(blocks(read(metadataPath),'values').map(v=>[tag(v,'field'),tag(v,'value')]))});
  edge(config,'instance_of',object('Strategic_Discount_Rule__mdt'),metadataPath);
  edge(req,'implemented_by',policy,policyPath); edge(policy,'reads',config,policyPath);
  const flowText=read(flowPath);
  sourced(flow,'flow','Strategic Discount Approval',flowPath,{status:tag(flowText,'status'),filterFormula:tag(flowText,'filterFormula'),trigger:'Opportunity RecordAfterSave CreateAndUpdate',atomicFault:true});
  edge(object('Opportunity'),'triggers',flow,flowPath); edge(flow,'calls',policy,flowPath);
  for(const f of contract.opportunity.policyRelevantFields) edge(field('Opportunity.'+f),'relevant_change_triggers',flow,flowPath);
  for(const f of contract.opportunity.forbiddenDirectOutcomeWrites) edge(flow,'writes',field('Opportunity.'+f),flowPath);
  edge(flow,'appends',object('Strategic_Deal_Evaluation__c'),flowPath);
  edge('apex:StrategicDealPolicyController','authorizes_parent',object('Opportunity'),base+'classes/StrategicDealPolicyController.cls');
  edge('apex:StrategicDealPolicyController','reads_private_summary',object('Strategic_Deal_Evaluation__c'),base+'classes/StrategicDealPolicyController.cls',{limit:5,afterUserModeParentCheck:true,noExternalHttpEndpoint:true});
  const approvalPath=base+'approvalProcesses/Opportunity.Strategic_Opportunity_Regional_VP.approvalProcess-meta.xml';
  const ap='approval:Strategic_Opportunity_Regional_VP'; const apText=read(approvalPath);
  sourced(ap,'approval-process','Strategic Opportunity Regional VP',approvalPath,{active:bool(apText,'active'),entryFormula:tag(apText,'formula'),recordEditability:tag(apText,'recordEditability'),allowRecall:bool(apText,'allowRecall')});
  edge(ap,'routes_via',field('Opportunity.Regional_VP_Approver__c'),approvalPath);
  edge('apex:StrategicDealApprovalController','rechecks',policy,base+'classes/StrategicDealApprovalController.cls');
  edge('apex:StrategicDealApprovalController','invokes',ap,base+'classes/StrategicDealApprovalController.cls');
  edge(ap,'creates',object('ProcessInstance'),approvalPath);
  for(const [child,lookup,parent] of [['ProcessInstance','TargetObjectId','Opportunity'],['ProcessInstanceWorkitem','ProcessInstanceId','ProcessInstance'],['ProcessInstanceWorkitem','ActorId','User'],['ProcessInstanceStep','ProcessInstanceId','ProcessInstance']]) edge(field(child+'.'+lookup),'references',object(parent),'curated-native-approval-model');
  const wfPath=base+'workflows/Opportunity.workflow-meta.xml';
  for(const update of blocks(read(wfPath),'fieldUpdates')) {
    const n=tag(update,'fullName'), id=sourced('field-update:'+n,'workflow-field-update',n,wfPath,{value:tag(update,'literalValue')});
    edge(ap,'uses_final_or_recall_action',id,approvalPath);
    edge(id,'writes',field('Opportunity.'+tag(update,'field')),wfPath);
  }
  for(const p of files.filter(p=>p.startsWith(base+'permissionsets/') && p.endsWith('.xml'))) {
    const s=read(p), name=path.posix.basename(p,'.permissionset-meta.xml');
    const id=sourced('permission-set:'+name,'permission-set',name,p,{grantsAreAdditive:true,notEffectiveUserAccess:true,userPermissions:blocks(s,'userPermissions').filter(b=>bool(b,'enabled')).map(b=>tag(b,'name'))});
    for(const b of blocks(s,'objectPermissions')) edge(id,'object_grant',object(tag(b,'object')),p,Object.fromEntries(['allowCreate','allowRead','allowEdit','allowDelete','viewAllRecords','modifyAllRecords'].map(k=>[k,bool(b,k)])));
    for(const b of blocks(s,'fieldPermissions')) edge(id,'field_grant',field(tag(b,'field')),p,{readable:bool(b,'readable'),editable:bool(b,'editable')});
    for(const b of blocks(s,'classAccesses')) edge(id,'class_access','apex:'+tag(b,'apexClass'),p,{enabled:bool(b,'enabled')});
  }
  for(const p of files.filter(p=>p.startsWith(base+'lwc/') && p.endsWith('.js') && !p.includes('/__tests__/'))) {
    const name=p.slice((base+'lwc/').length).split('/')[0], id=sourced('lwc:'+name,'lightning-component',name,p);
    for(const match of read(p).matchAll(/@salesforce\/apex\/([\w]+)\.([\w]+)/g)) edge(id,'calls_internal_apex','apex:'+match[1],p,{method:match[2],externalHttpEndpoint:false});
    const html=p.replace(/\.js$/,'.html');
    if(files.includes(html)) for(const child of read(html).matchAll(/<c-([a-z][a-z-]+)[\s>]/g)) {
      const component=child[1].replace(/-([a-z])/g,(_,c)=>c.toUpperCase());
      edge(id,'contains','lwc:'+component,html);
    }
  }
  for(const p of files.filter(p=>p.startsWith(base+'flexipages/') && p.endsWith('.xml'))) {
    const name=path.posix.basename(p,'.flexipage-meta.xml'), id=sourced('page:'+name,'lightning-page',name,p);
    for(const component of blocks(read(p),'componentName').map(decode)) if(component.startsWith('c:')) edge(id,'contains','lwc:'+component.slice(2),p);
  }
  const appPath=base+'applications/Strategic_Deal_Assurance.app-meta.xml';
  const app=sourced('app:Strategic_Deal_Assurance','lightning-app','Strategic Deal Assurance',appPath,{tabs:blocks(read(appPath),'tabs').map(decode)});
  edge(app,'opportunity_record_page','page:Strategic_Deal_Record_Page',appPath);
  edge(app,'workbench_page','page:Strategic_Deal_Workbench',base+'tabs/Strategic_Deal_Workbench.tab-meta.xml');
  for(const [test,targets] of Object.entries({StrategicDiscountPolicyTest:[policy],StrategicDiscountFlowTest:[flow,policy],StrategicDealPolicyControllerTest:['apex:StrategicDealPolicyController'],StrategicDealApprovalControllerTest:['apex:StrategicDealApprovalController',ap]})) for(const target of targets) edge('apex:'+test,'tests',target,base+'classes/'+test+'.cls');
  for(const p of files.filter(p=>p.includes('/lwc/') && p.endsWith('.test.js'))) {
    const component=p.slice((base+'lwc/').length).split('/')[0];
    edge(sourced('jest:'+component,'component-test',component+' Jest tests',p,{mocksPlatform:true}),'tests','lwc:'+component,p);
  }
  for(const capability of contract.capabilities) {
    const {id,...attrs}=capability;
    sourced('capability:'+id,'capability',id,contractPath,attrs);
  }
  const fixturePath=prefix+'data/multi-module-plan.json', plan=JSON.parse(read(fixturePath));
  const dataset=sourced('dataset:'+plan.dataset,'synthetic-dataset',plan.dataset,fixturePath,{counts:plan.expectedCounts,expectedBusinessRows:plan.expectedBusinessRows,resetMode:'create-only'});
  for(const [type,rows] of Object.entries(plan.objects)) for(const [i,row] of rows.entries()) {
    const id=sourced('fixture:'+row.key,'synthetic-fixture',row.fields.Name || row.fields.LastName || row.fields.Subject || row.key,fixturePath,{logicalKey:row.key,object:type,jsonPointer:'/objects/'+type+'/'+i,realRecordIdIncluded:false});
    edge(dataset,'contains',id,fixturePath); edge(id,'instance_of',object(type),fixturePath);
    for(const [f,value] of Object.entries(row.fields)) {
      field(type+'.'+f,{source:fixturePath,runtimeDescribeRequired:true});
      if(typeof value==='string' && value.startsWith('@')) {
        const key=value.slice(1), target=['operator','vp'].includes(key)?'persona:'+key:'fixture:'+key;
        edge(id,'references',target,fixturePath,{field:type+'.'+f});
        const targetType=['operator','vp'].includes(key)?'User':Object.entries(plan.objects).find(([,rs])=>rs.some(r=>r.key===key))?.[0];
        if(targetType) edge('field:'+type+'.'+f,'references','object:'+targetType,fixturePath,{observedFixtureReference:true});
      }
    }
  }
  const baselinePath=prefix+'data/baseline-15-plan.json', baseline=JSON.parse(read(baselinePath));
  const baselineId=sourced('dataset:'+baseline.dataset,'synthetic-dataset',baseline.dataset,baselinePath,{opportunities:7,businessRows:8,resetMode:'guarded restore; pending approvals blocked'});
  edge(baselineId,'tests',req,baselinePath);
  const casesPath=prefix+'data/multi-module-use-cases.json';
  for(const c of JSON.parse(read(casesPath)).cases) {
    const id=sourced('use-case:'+c.id,'manual-use-case',c.title,casesPath,{objective:c.objective,actor:c.actor,steps:c.steps.length,manualSuiteExecution:'not run as a complete suite'});
    edge(id,'uses_dataset',dataset,casesPath);
    for(const module of c.modules) edge(id,'covers',module==='ApprovalProcess'?ap:object(module),casesPath);
  }
  for(const [runner,target] of [['scripts/demo/reset-baseline.ps1',baselineId],['scripts/demo/seed-multi-module.ps1',dataset]]) edge('file:'+prefix+runner,'manages',target,prefix+runner);
  for(const e of edges.values()) if(!nodes.has(e.from) || !nodes.has(e.to)) throw new Error('Unresolved graph edge: '+e.from+' -> '+e.to);
  const graph={schemaVersion:'1.0.0',application:'Strategic Deal Assurance',apiVersion:contract.apiVersion,sourceSnapshot,provenance:'Static DX metadata, curated lifecycle relationships and logical synthetic fixture references. Not a live org dump or complete Apex call graph.',authorization:'Descriptive only; graph edges grant no execution authority.',nodes:[...nodes.values()].sort((a,b)=>a.id.localeCompare(b.id)),edges:[...edges.values()].sort((a,b)=>a.id.localeCompare(b.id))};
  const index={schemaVersion:'1.0.0',application:'Strategic Deal Assurance',pathBase:'repository-root',sourceSnapshot,hashAlgorithm:'SHA-256 of UTF-8 text normalized to LF',generator:prefix+'scripts/catalog/build-project-index.mjs',generatedOutputs:outputs,readOrder:[prefix+'contracts/agent-interface.json',prefix+'docs/agent-integration-guide.md',prefix+'docs/project-index.md',outputs[0],prefix+'data/multi-module-use-cases.json'],authoritativePaths:[prefix+'force-app/main/default',prefix+'requirements'],historicalEvidenceNotice:'Milestone reports describe their recorded snapshot, not current runtime state. Older permission descriptions can be stale.',files:inventory};
  return new Map([[outputs[0],JSON.stringify(graph,null,2)+'\n'],[outputs[1],JSON.stringify(index,null,2)+'\n']]);
}

export function writeOrCheck(check=false) {
  const artifacts=buildArtifacts(); const stale=[];
  for(const [p,body] of artifacts) {
    if(check) {if(!fs.existsSync(path.join(repoRoot,p)) || read(p)!==body) stale.push(p);}
    else {fs.mkdirSync(path.dirname(path.join(repoRoot,p)),{recursive:true}); fs.writeFileSync(path.join(repoRoot,p),body);}
  }
  if(stale.length) throw new Error('Catalog is stale: '+stale.join(', ')+'. Run npm run catalog:build.');
  const graph=JSON.parse(artifacts.values().next().value);
  return {outcome:'Passed',mode:check?'check':'build',nodes:graph.nodes.length,edges:graph.edges.length,sourceSnapshot:graph.sourceSnapshot};
}
if(process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  try {console.log(JSON.stringify(writeOrCheck(process.argv.includes('--check')),null,2));}
  catch(error) {console.error(error.message); process.exitCode=1;}
}
