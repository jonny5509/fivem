const $=id=>document.getElementById(id);
let socket=null, webhookId='', paired=false, approved=false, toastTimer;
function nui(name,data={}){return fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}).catch(()=>{});}
function toast(t,k=''){const e=$('toast');e.textContent=t;e.className='toast '+k;clearTimeout(toastTimer);toastTimer=setTimeout(()=>e.classList.add('hidden'),4000);}
function connection(on){$('dot').classList.toggle('online',on);$('connection').textContent=on?'Connected to XToys':'Not connected';$('connect').disabled=on;}
function sendXToys(payload){if(!socket||socket.readyState!==WebSocket.OPEN){toast('Toy owner is not connected to XToys.','error');return false;}socket.send(JSON.stringify(payload));return true;}
function connect(){const id=$('webhook').value.trim();if(!id)return toast('Enter your private XToys webhook ID.','error');if(socket)socket.close();webhookId=id;
 const ws=new WebSocket('wss://webhook.xtoys.app/'+encodeURIComponent(id));socket=ws;
 ws.onopen=()=>{if(socket===ws){connection(true);toast('XToys webhook connected.','success');}};
 ws.onerror=()=>toast('XToys connection failed. Check the webhook ID and XToys setup.','error');
 ws.onclose=()=>{if(socket===ws){socket=null;connection(false);}};
}
function render(s={}){paired=!!s.paired;$('pairStatus').textContent=paired?'Paired':'Not paired';$('partner').textContent=paired?`${s.partnerName||'Partner'} (ID ${s.partnerId})`:'Invite another player by server ID.';$('invite').disabled=paired;$('playerId').disabled=paired;$('request').disabled=!paired;
 $('inviteButtons').classList.toggle('hidden',!s.incomingInvite);$('approvalButtons').classList.toggle('hidden',!s.incomingControl);
 if(s.incomingInvite)toast(`${s.incomingInvite.name} invited you. Accept only if you agree.`);
 if(s.incomingControl)toast(`${s.incomingControl.name} requests control. Approve only if you consent.`);
 if(!paired){approved=false;$('controls').classList.add('hidden');}
}
window.addEventListener('message',e=>{const d=e.data||{};
 if(d.type==='open'){$('app').classList.remove('hidden');nui('refresh');}
 if(d.type==='state')render(d.state);
 if(d.type==='toast')toast(d.message,d.kind);
 if(d.type==='incomingInvite')toast(`${d.data.name} invited you. Open /xtoys to respond.`);
 if(d.type==='incomingControl')toast(`${d.data.name} requests control. Open /xtoys to approve.`);
 if(d.type==='controlGranted'){approved=true;$('controls').classList.remove('hidden');toast(`Control approved by ${d.ownerName}.`,'success');}
 if(d.type==='xtoysCommand'){sendXToys({action:d.action,intensity:d.intensity,seconds:d.duration});}
 if(d.type==='xtoysStop'){sendXToys({action:d.action});approved=false;$('controls').classList.add('hidden');}
});
$('close').onclick=()=>{$('app').classList.add('hidden');nui('close')};
$('connect').onclick=connect;$('disconnect').onclick=()=>{if(socket)socket.close();socket=null;connection(false);toast('XToys disconnected.');};
$('invite').onclick=()=>nui('invite',{target:$('playerId').value});$('accept').onclick=()=>nui('acceptInvite');$('decline').onclick=()=>nui('declineInvite');
$('request').onclick=()=>nui('requestControl');$('approve').onclick=()=>nui('approveControl',{approved:true});$('deny').onclick=()=>nui('approveControl',{approved:false});
$('send').onclick=()=>{if(approved)nui('control',{intensity:+$('level').value,duration:+$('duration').value});};
$('level').oninput=()=>$('levelOut').textContent=$('level').value+'%';
$('stop').onclick=()=>{sendXToys({action:'stop'});nui('emergencyStop');approved=false;$('controls').classList.add('hidden');};
$('revoke').onclick=()=>{nui('revoke');approved=false;$('controls').classList.add('hidden');};
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!$('app').classList.contains('hidden'))$('close').click();});