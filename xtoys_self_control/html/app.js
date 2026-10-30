const $ = id => document.getElementById(id);
let socket = null;
let toastTimer = null;

function toast(message, kind = '') {
    const el = $('toast');
    el.textContent = message;
    el.className = 'toast ' + kind;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.add('hidden'), 4000);
}

function setConnection(connected) {
    $('dot').classList.toggle('online', connected);
    $('connection').textContent = connected ? 'Connected to XToys' : 'Not connected';
    $('connect').disabled = connected;
}

function send(payload) {
    if (!socket || socket.readyState !== WebSocket.OPEN) {
        toast('XToys is not connected. Enter your private webhook ID.', 'error');
        return false;
    }
    socket.send(JSON.stringify(payload));
    return true;
}

function connect(id = $('webhook').value.trim()) {
    if (!id) return toast('Enter your private XToys webhook ID.', 'error');
    if (socket) socket.close();

    const current = new WebSocket('wss://webhook.xtoys.app/' + encodeURIComponent(id));
    socket = current;

    current.onopen = () => {
        if (socket !== current) return;
        setConnection(true);
        toast('XToys webhook connected.', 'success');
    };
    current.onerror = () => {
        if (socket === current) toast('Connection failed. Check the webhook ID and XToys setup.', 'error');
    };
    current.onclose = () => {
        if (socket !== current) return;
        socket = null;
        setConnection(false);
    };
}

function stop() {
    if (socket && socket.readyState === WebSocket.OPEN) {
        socket.send(JSON.stringify({ action: 'stop' }));
    }
}

function nui(name, data = {}) {
    return fetch('https://' + GetParentResourceName() + '/' + name, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

window.addEventListener('message', event => {
    const data = event.data || {};
    if (data.type === 'open') $('app').classList.remove('hidden');
    if (data.type === 'connectWebhook') {
        $('webhook').value = data.webhookId || '';
        connect(data.webhookId || '');
    }
    if (data.type === 'toast') toast(data.message || '');
    if (data.type === 'enabledState') {
        $('enabled').checked = data.enabled === true;
        $('modeStatus').textContent = data.enabled ? 'Self Control enabled' : 'Self Control paused';
        $('modeDot').classList.toggle('online', data.enabled === true);
    }
    if (data.type === 'xtoysCommand') {
        send({
            action: data.action,
            intensity: data.intensity,
            seconds: data.duration
        });
    }
    if (data.type === 'xtoysStop') stop();
});

$('close').onclick = () => {
    $('app').classList.add('hidden');
    nui('close');
};
$('connect').onclick = () => connect();
$('disconnect').onclick = () => {
    if (socket) socket.close();
    socket = null;
    setConnection(false);
    toast('XToys disconnected.');
};
$('stop').onclick = () => {
    stop();
    nui('emergencyStop');
    toast('Emergency stop sent.');
};
$('enabled').onchange = () => nui('setEnabled', { enabled: $('enabled').checked });
document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && !$('app').classList.contains('hidden')) $('close').click();
});
window.addEventListener('beforeunload', stop);
