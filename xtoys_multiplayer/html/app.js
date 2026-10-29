const $=id=>document.getElementById(id);
let socket=null, webhookId='', paired=false, approved=false, toastTimer, trustedPartners=[];
function nui(name,data={}){return fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}).catch(()=>{});}
function toast(t,k=''){const e=$('toast');e.textContent=t;e.className='toast '+k;clearTimeout(toastTimer);toastTimer=setTimeout(()=>e.classList.add('hidden'),4000);}
function connection(on){$('dot').classList.toggle('online',on);$('connection').textContent=on?'Connected to XToys':'Not connected';$('connect').disabled=on;}
function sendXToys(payload){if(!socket||socket.readyState!==WebSocket.OPEN){toast('Toy owner is not connected to XToys.','error');return false;}socket.send(JSON.stringify(payload));return true;}
function connect(){const id=$('webhook').value.trim();if(!id)return toast('Enter your private XToys webhook ID.','error');if(socket)socket.close();webhookId=id;const ws=new WebSocket('wss://webhook.xtoys.app/'+encodeURIComponent(id));socket=ws;ws.onopen=()=>{if(socket===ws){connection(true);toast('XToys webhook connected.','success');}};ws.onerror=()=>toast('XToys connection failed. Check the webhook ID and XToys setup.','error');ws.onclose=()=>{if(socket===ws){socket=null;connection(false);}};}
function playerRow(player,kind){const row=document.createElement('div');row.className='player-row';const info=document.createElement('div');info.className='player-info';const name=document.createElement('b');name.textContent=player.name||'Unknown player';const detail=document.createElement('small');detail.textContent=kind==='nearby'?`ID ${player.serverId} · ${player.distance}m away`:player.online?`Online · ID ${player.serverId}`:'Offline';info.append(name,detail);row.append(info);
 if(kind==='nearby'){const btn=document.createElement('button');btn.className='primary compact';btn.textContent=player.trusted?'Trusted':'Add';btn.disabled=!!player.trusted;btn.onclick=()=>nui('trustedInvite',{target:player.serverId});row.append(btn);}
 else {const actions=document.createElement('div');actions.className='row-actions';if(player.online){const control=document.createElement('button');control.className='primary compact';control.textContent='Control';control.onclick=()=>nui('startTrustedControl',{target:player.serverId});actions.append(control);}const remove=document.createElement('button');remove.className='danger compact';remove.textContent='Remove';remove.onclick=()=>{if(confirm('Remove this trusted partnership?'))nui('removeTrusted',{identifier:player.identifier});};actions.append(remove);row.append(actions);}
 return row;}
function renderNearby(players=[]){const root=$('nearbyList');root.replaceChildren();if(!players.length){const p=document.createElement('p');p.className='hint';p.textContent='No players found within 10 metres.';root.append(p);return;}players.forEach(p=>root.append(playerRow(p,'nearby')));}
function renderTrusted(players=[]){trustedPartners=players;const root=$('trustedList');root.replaceChildren();if(!players.length){const p=document.createElement('p');p.className='hint';p.textContent='No trusted partners yet.';root.append(p);return;}players.forEach(p=>root.append(playerRow(p,'trusted')));}
function render(s={}){paired=!!s.paired;$('pairStatus').textContent=paired?'Paired':'Not paired';$('partner').textContent=paired?`${s.partnerName||'Partner'} (ID ${s.partnerId})`:'Invite another player by server ID.';$('invite').disabled=paired;$('playerId').disabled=paired;$('request').disabled=!paired;$('inviteButtons').classList.toggle('hidden',!s.incomingInvite);$('approvalButtons').classList.toggle('hidden',!s.incomingControl);$('trustedInviteButtons').classList.toggle('hidden',!s.incomingTrustedInvite);renderTrusted(s.trustedPartners||[]);
 if(s.incomingInvite)toast(`${s.incomingInvite.name} invited you. Accept only if you agree.`);
 if(s.incomingTrustedInvite)toast(`${s.incomingTrustedInvite.name} wants to become a trusted partner. Confirm only if you agree.`);
 if(s.incomingControl)toast(`${s.incomingControl.name} requests control. Approve only if you consent.`);
 if(!paired){approved=false;$('controls').classList.add('hidden');}}
window.addEventListener('message',e=>{const d=e.data||{};if(d.type==='open'){$('app').classList.remove('hidden');nui('refresh');}
 if(d.type==='state')render(d.state);if(d.type==='nearbyPlayers')renderNearby(d.players);if(d.type==='toast')toast(d.message,d.kind);
 if(d.type==='incomingInvite')toast(`${d.data.name} invited you. Open /xtoys to respond.`);
 if(d.type==='incomingTrustedInvite')toast(`${d.data.name} wants to add you as a trusted partner. Open /xtoys to confirm.`);
 if(d.type==='incomingControl')toast(`${d.data.name} requests control. Open /xtoys to approve.`);
 if(d.type==='controlGranted'){approved=true;$('controls').classList.remove('hidden');toast(`Control approved by ${d.ownerName}.`,'success');}
 if(d.type==='xtoysCommand')sendXToys({action:d.action,intensity:d.intensity,seconds:d.duration});
 if(d.type==='xtoysStop'){sendXToys({action:d.action});approved=false;$('controls').classList.add('hidden');}});
$('close').onclick=()=>{$('app').classList.add('hidden');nui('close')};$('connect').onclick=connect;$('disconnect').onclick=()=>{if(socket)socket.close();socket=null;connection(false);toast('XToys disconnected.');};
$('invite').onclick=()=>nui('invite',{target:$('playerId').value});$('accept').onclick=()=>nui('acceptInvite');$('decline').onclick=()=>nui('declineInvite');
$('addTrusted').onclick=()=>{const id=$('trustedId').value.trim();if(id)nui('trustedInvite',{target:id});else toast('Enter a nearby player server ID.','error');};
$('refreshNearby').onclick=()=>{nui('refresh');};$('acceptTrusted').onclick=()=>nui('acceptTrustedInvite');$('declineTrusted').onclick=()=>nui('declineTrustedInvite');
$('request').onclick=()=>nui('requestControl');$('approve').onclick=()=>nui('approveControl',{approved:true});$('deny').onclick=()=>nui('approveControl',{approved:false});
$('send').onclick=()=>{if(approved)nui('control',{intensity:+$('level').value,duration:+$('duration').value});};$('level').oninput=()=>$('levelOut').textContent=$('level').value+'%';
$('stop').onclick=()=>{sendXToys({action:'stop'});nui('emergencyStop');approved=false;$('controls').classList.add('hidden');};
$('revoke').onclick=()=>{nui('revoke');approved=false;$('controls').classList.add('hidden');};
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!$('app').classList.contains('hidden'))$('close').click();});