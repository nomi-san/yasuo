var start = (championIds = [157]) => {
    // Simple request
    var request = async (method, url, body = undefined) => {
        const data = await fetch(url, {
            method: method,
            body: body,
            headers: {'Content-type': 'application/json; charset=UTF-8'}
        }).then(res => res.text())
          .then(txt => JSON.parse(txt.length ? txt : '{}'));
        return data;
    };
    // Check if match found is shown
    var isInProgress = async () => (await request(
        'GET', '/lol-matchmaking/v1/ready-check')).state === 'InProgress';
    // Accept match
    var acceptMatch = async () => await request(
        'POST', '/lol-matchmaking/v1/ready-check/accept');
    // Get your action ID
    var getActionId = async () => {
        var {localPlayerCellId, actions} =
            await request('GET', '/lol-champ-select/v1/session');
        if (!actions) return -1;
        return actions[0].filter(v =>
            v.actorCellId === localPlayerCellId)[0].id;
    };
    // Pick a champion
    var pick = async (id, championId) => Object.keys(await request(
        'PATCH', `/lol-champ-select/v1/session/actions/${id}`,
        JSON.stringify({championId}))).length === 0;
    // Lock selection
    var lock = async (id) => await request(
        'POST', `/lol-champ-select/v1/session/actions/${id}/complete`);
    // Start auto accept match found and pick-lock
    var id, inv = setInterval(async () => {
        if (await isInProgress()) {
            await acceptMatch();
        } else if ((id = await getActionId()) > -1) {
            for (var i=0; i<championIds.length; i++)
                if (await pick(id, championIds[i])) break;
            await lock(id);
            clearInterval(inv);
        }
    }, 250);
};
