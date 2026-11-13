const fs = require('fs');
const { settlement } = require('./support/budget_rules_fixture.cjs');
const cases = [], names = [];
const root = '/databases/(default)/documents/users/alice';
const settings = { dailyLimit: 500, dailyLimitStartDate: '2026-04-01' };
function add(name, expectation, method, suffix, data, old, uid = 'alice', after = {}, existsAfter = false) {
  names.push(name);
  const request = { path: root + suffix, method, auth: uid ? {uid} : null };
  if (data) request.resource = { data };
  const test = { expectation, request, functionMocks: [
    { function: 'exists', args: [{anyValue: {}}], result: {value: true} },
    { function: 'get', args: [{anyValue: {}}], result: {value: {data: settings}} },
    { function: 'existsAfter', args: [{anyValue: {}}], result: {value: existsAfter} },
    { function: 'getAfter', args: [{anyValue: {}}], result: {value: {data: after}} },
  ] };
  if (old) test.resource = { data: old };
  cases.push(test);
}
add('owner reads settings', 'ALLOW', 'get', '');
add('other user cannot read settings', 'DENY', 'get', '', null, null, 'bob');
add('guest cannot read settings', 'DENY', 'get', '', null, null, null);
add('owner creates valid settings', 'ALLOW', 'create', '', settings);
add('owner updates daily target', 'ALLOW', 'update', '', {...settings, dailyLimit: 600}, settings);
add('negative target denied', 'DENY', 'update', '', {...settings, dailyLimit: -1}, settings);
add('start date change denied', 'DENY', 'update', '', {...settings, dailyLimitStartDate:'2026-03-01'}, settings);
add('extra profile field denied', 'DENY', 'update', '', {...settings, admin:true}, settings);
add('settings delete denied', 'DENY', 'delete', '', null, settings);
for (const [name, value] of [
 ['saved leftover', settlement('2026-04-01',30000,20000,'savedToWallet')],
 ['partial coverage', settlement('2026-04-02',75000,-20000,'coveredByWallet')],
 ['uncovered overspend', settlement('2026-04-03',60000,0,'carriedForward')],
 ['exact daily target', settlement('2026-04-04',50000,0,'none')],
 ['declined savings', settlement('2026-04-05',30000,0,'none')],
 ['fractional amounts', settlement('2026-04-06',30000,19310,'savedToWallet',690,20000)],
]) {
 const wallet={relatedDay:value.date, amountMinor:Math.abs(value.amountsMinor.walletChange), type:value.walletChange>0?'deposit':'withdraw'};
 add(name,'ALLOW','create','/daily_settlements/'+value.date,value,null,'alice',wallet,value.walletChange!==0);
 add(name+' idempotent retry','ALLOW','update','/daily_settlements/'+value.date,value,value);
 add(name+' cannot modify','DENY','update','/daily_settlements/'+value.date,{...value,spent:1},value);
}
const saved=settlement('2026-04-01',30000,20000,'savedToWallet');
const entry={amount:200,amountMinor:20000,type:'deposit',date:saved.date,relatedDay:saved.date};
add('matching wallet deposit','ALLOW','create','/wallet_entries/'+saved.date,entry,null,'alice',saved,true);
add('wrong wallet amount denied','DENY','create','/wallet_entries/'+saved.date,{...entry,amount:300,amountMinor:30000},null,'alice',saved,true);
add('unrelated wallet entry denied','DENY','create','/wallet_entries/'+saved.date,{...entry,relatedDay:'2026-04-02'},null,'alice',saved,true);
add('settlement without wallet denied','DENY','create','/daily_settlements/'+saved.date,saved,null,'alice',{},false);
add('wallet idempotent retry','ALLOW','update','/wallet_entries/'+saved.date,entry,entry);
add('wallet delete denied','DENY','delete','/wallet_entries/'+saved.date,null,entry);
add('other user cannot read wallet','DENY','get','/wallet_entries/'+saved.date,null,entry,'bob');
const time = '2026-11-12T10:00:00.000Z';
const topUpId = 'topup-100-0-1';
const topUp = {amount:100,amountMinor:10000,type:'deposit',source:'manualTopUp',
  date:time,relatedDay:'2026-11-12'};
add('manual wallet top-up allowed','ALLOW','create','/wallet_entries/'+topUpId,topUp);
add('manual top-up identical retry','ALLOW','update','/wallet_entries/'+topUpId,topUp,topUp);
add('manual top-up cannot be withdrawn or edited','DENY','update','/wallet_entries/'+topUpId,{...topUp,type:'withdraw'},topUp);
add('manual top-up must be a deposit','DENY','create','/wallet_entries/'+topUpId,{...topUp,type:'withdraw'});
add('manual top-up cannot overwrite settlement ID','DENY','create','/wallet_entries/2026-11-12',topUp);
add('manual top-up cannot forge goal allocation','DENY','create','/wallet_entries/'+topUpId,{...topUp,goalId:'laptop'});
add('manual amount mismatch denied','DENY','create','/wallet_entries/'+topUpId,{...topUp,amount:999});
add('other user cannot top up wallet','DENY','create','/wallet_entries/'+topUpId,topUp,null,'bob');
const goalId = 'laptop';
const goal = {title:'Laptop',target:5000,saved:0,createdAt:time};
add('owner can create empty savings goal','ALLOW','create','/goals/'+goalId,goal);
add('new goal cannot invent saved funds','DENY','create','/goals/'+goalId,{...goal,saved:500});
add('goal saved total cannot be edited directly','DENY','update','/goals/'+goalId,{...goal,saved:500},goal);
add('goal with history cannot be deleted','DENY','delete','/goals/'+goalId,null,goal);
const transferId = 'goal-101-0-1';
const transfer = {...topUp,type:'withdraw',source:'goalTransfer',goalId};
const contribution = {goalId,walletEntryId:transferId,amount:100,amountMinor:10000,date:time};
add('paired goal wallet withdrawal allowed','ALLOW','create','/wallet_entries/'+transferId,transfer,null,'alice',contribution,true);
add('paired goal contribution allowed','ALLOW','create','/goal_contributions/'+transferId,contribution,null,'alice',transfer,true);
add('paired transfer retry is idempotent','ALLOW','update','/wallet_entries/'+transferId,transfer,transfer);
add('contribution retry is idempotent','ALLOW','update','/goal_contributions/'+transferId,contribution,contribution);
add('standalone wallet withdrawal denied','DENY','create','/wallet_entries/'+transferId,transfer,null,'alice',{},true);
add('standalone goal credit denied','DENY','create','/goal_contributions/'+transferId,contribution,null,'alice',{},true);
add('transfer to missing goal denied','DENY','create','/wallet_entries/'+transferId,transfer,null,'alice',contribution,false);
add('wrong contribution amount denied','DENY','create','/wallet_entries/'+transferId,transfer,null,'alice',{...contribution,amountMinor:20000},true);
add('wrong withdrawal amount denied','DENY','create','/goal_contributions/'+transferId,contribution,null,'alice',{...transfer,amountMinor:20000},true);
add('cross-goal wallet link denied','DENY','create','/wallet_entries/'+transferId,transfer,null,'alice',{...contribution,goalId:'other'},true);
add('cross-goal contribution denied','DENY','create','/goal_contributions/'+transferId,contribution,null,'alice',{...transfer,goalId:'other'},true);
add('other user cannot read contributions','DENY','get','/goal_contributions/'+transferId,null,contribution,'bob');
add('contribution deletion denied','DENY','delete','/goal_contributions/'+transferId,null,contribution);
const account = {name: 'Commercial Bank', openingBalanceMinor: 100000};
add('owner reads bank account','ALLOW','get','/money_accounts/bank1',null,account);
add('owner creates bank account','ALLOW','create','/money_accounts/bank1',account);
add('owner updates bank account','ALLOW','update','/money_accounts/bank1',{...account,openingBalanceMinor:-100},account);
add('other user cannot read bank account','DENY','get','/money_accounts/bank1',null,account,'bob');
add('other user cannot change bank account','DENY','update','/money_accounts/bank1',account,account,'bob');
add('guest cannot create bank account','DENY','create','/money_accounts/bank1',account,null,null);
add('empty account name denied','DENY','create','/money_accounts/bank1',{...account,name:''});
add('long account name denied','DENY','create','/money_accounts/bank1',{...account,name:'a'.repeat(41)});
add('fractional minor balance denied','DENY','create','/money_accounts/bank1',{...account,openingBalanceMinor:0.5});
add('extra account field denied','DENY','create','/money_accounts/bank1',{...account,admin:true});
add('account deletion denied to preserve history','DENY','delete','/money_accounts/bank1',null,account);
const debtTime = '2026-11-12T00:00:00.000Z';
const debt = {name:'Friend',kind:'receivable',principalMinor:100000,repaidMinor:0,createdAt:debtTime,lastEntryId:'loan1'};
const opening = {debtId:'loan1',kind:'receivable',action:'opening',amountMinor:100000,accountId:'cash',movesCash:true,date:debtTime};
function addDebt(name, expected, method, suffix, data, old, after, uid = 'alice', existed = false) {
  add(name,expected,method,suffix,data,old,uid,after,true);
  const test = cases[cases.length - 1];
  test.request.time = '2026-11-13T12:00:00.000Z';
  test.functionMocks.find(mock => mock.function === 'exists').result.value = existed;
}
addDebt('owner creates lent debt with paired cash flow','ALLOW','create','/debt_accounts/loan1',debt,null,opening);
addDebt('owner records existing debt without cash movement','ALLOW','create','/debt_accounts/loan1',debt,null,{...opening,movesCash:false});
addDebt('borrowed money opening allowed','ALLOW','create','/debt_accounts/loan1',{...debt,kind:'payable'},null,{...opening,kind:'payable'});
addDebt('credit opening does not move cash','ALLOW','create','/debt_accounts/loan1',{...debt,kind:'creditCard'},null,{...opening,kind:'creditCard',movesCash:false});
addDebt('credit opening cannot move cash','DENY','create','/debt_accounts/loan1',{...debt,kind:'creditCard'},null,{...opening,kind:'creditCard'});
addDebt('unpaired debt opening denied','DENY','create','/debt_accounts/loan1',debt,null,{});
addDebt('debt principal mismatch denied','DENY','create','/debt_accounts/loan1',debt,null,{...opening,amountMinor:1});
addDebt('negative principal denied','DENY','create','/debt_accounts/loan1',{...debt,principalMinor:-1},null,opening);
addDebt('future debt opening denied','DENY','create','/debt_accounts/loan1',{...debt,createdAt:'2026-11-14T00:00:00.000Z'},null,opening);
addDebt('other user cannot read debts','DENY','get','/debt_accounts/loan1',null,debt,{},'bob');
addDebt('guest cannot create debts','DENY','create','/debt_accounts/loan1',debt,null,opening,null);
addDebt('debt deletion denied','DENY','delete','/debt_accounts/loan1',null,debt,{});
const repayment = {...opening,action:'repayment',amountMinor:40000};
const paidDebt = {...debt,repaidMinor:40000,lastEntryId:'payment1'};
addDebt('partial loan repayment allowed','ALLOW','update','/debt_accounts/loan1',paidDebt,debt,repayment);
addDebt('full loan repayment allowed','ALLOW','update','/debt_accounts/loan1',{...paidDebt,repaidMinor:100000},debt,{...repayment,amountMinor:100000});
addDebt('loan overpayment denied','DENY','update','/debt_accounts/loan1',{...paidDebt,repaidMinor:100001},debt,{...repayment,amountMinor:100001});
addDebt('loan kind cannot change','DENY','update','/debt_accounts/loan1',{...paidDebt,kind:'payable'},debt,repayment);
addDebt('repayment cannot be replayed','DENY','update','/debt_accounts/loan1',paidDebt,debt,repayment,'alice',true);
addDebt('repayment cannot skip cash movement','DENY','update','/debt_accounts/loan1',paidDebt,debt,{...repayment,movesCash:false});
const creditDebt = {...debt,kind:'creditCard'};
const charge = {...opening,kind:'creditCard',action:'charge',amountMinor:20000,accountId:'credit:loan1',movesCash:false};
addDebt('credit purchase increases liability','ALLOW','update','/debt_accounts/loan1',{...creditDebt,principalMinor:120000,lastEntryId:'charge1'},creditDebt,charge);
addDebt('purchase cannot increase personal loan','DENY','update','/debt_accounts/loan1',{...debt,principalMinor:120000,lastEntryId:'charge1'},debt,{...charge,kind:'receivable'});
const creditPurchase = {title:'Card purchase',category:'Credit card purchase',amount:200,type:'expense',date:debtTime,accountId:'credit:loan1'};
addDebt('paired card purchase recorded as expense','ALLOW','create','/transactions/charge1',creditPurchase,null,charge);
addDebt('standalone card expense denied','DENY','create','/transactions/charge1',creditPurchase,null,{});
addDebt('credit purchase amount mismatch denied','DENY','create','/transactions/charge1',{...creditPurchase,amount:300},null,charge);
addDebt('card expense cannot be income','DENY','create','/transactions/charge1',{...creditPurchase,type:'income'},null,charge);
addDebt('card expense cannot be deleted separately','DENY','delete','/transactions/charge1',null,creditPurchase,{});
addDebt('card expense cannot be edited separately','DENY','update','/transactions/charge1',{...creditPurchase,amount:300},creditPurchase,{});
addDebt('ordinary cash expense still allowed','ALLOW','create','/transactions/cash1',{...creditPurchase,accountId:'cash'},null,{});
addDebt('ordinary bank income still allowed','ALLOW','create','/transactions/bank1',{...creditPurchase,type:'income',accountId:'bank1'},null,{});
addDebt('negative debt entry denied','DENY','create','/debt_entries/payment1',{...repayment,amountMinor:-1},null,{});
addDebt('other user cannot read debt cash flows','DENY','get','/debt_entries/loan1',null,opening,{},'bob');
addDebt('debt cash flow deletion denied','DENY','delete','/debt_entries/loan1',null,opening,{});
addDebt('empty credit card can be added before its first purchase','ALLOW','create','/debt_accounts/loan1',{...creditDebt,principalMinor:0},null,{...opening,kind:'creditCard',amountMinor:0,movesCash:false});
addDebt('zero personal loan is rejected','DENY','create','/debt_accounts/loan1',{...debt,principalMinor:0},null,{...opening,amountMinor:0});
addDebt('zero repayment is rejected','DENY','update','/debt_accounts/loan1',{...paidDebt,repaidMinor:0},debt,{...repayment,amountMinor:0});
process.stdout.write(JSON.stringify({names, payload:{source:{files:[{name:'firestore.rules',content:fs.readFileSync('firestore.rules','utf8')}]},testSuite:{testCases:cases}}}));
