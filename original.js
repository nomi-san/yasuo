var start = (championIds = [157]) => {
    
    // Simple request with fetch API
    const request = async (url, method = 'GET', body = undefined) => {
        const data = await fetch(url, {
            method: method,
            body: JSON.stringify(body),
            headers: { 'Content-type': 'application/json; charset=UTF-8' }
        }).then(res => res.text()).then(txt =>
            JSON.parse(txt || '{}')
        )
        return data
    }
    
    // Check if match found is shown
    var isInProgress = async () => (
        (await request('/lol-matchmaking/v1/ready-check'))
            .state === 'InProgress'
    )
    
    // Accept match
    var acceptMatch = async () => (
        await request('/lol-matchmaking/v1/ready-check/accept', 'POST')
    )
    
    // Get your action ID
    var getActionId = async () => {
        const { localPlayerCellId, actions } = await request('/lol-champ-select/v1/session')
        if (!actions) return -1
        return actions[0] // Index 0 is our team
            .find(a => a.actorCellId === localPlayerCellId) // Just find current player
            .id // We found action ID
    }
    
    // Pick a champion
    var pick = async (id, championId) => (
        Object.keys(await request(
            `/lol-champ-select/v1/session/actions/${id}`,
            'PATCH', { championId }
        )).length === 0 // Succeed
    )
    
    // Lock the selection
    var lock = async (id) => (
        await request(`/lol-champ-select/v1/session/actions/${id}/complete`, 'POST')
    )
    
    // Start auto accept match found and pick-lock
    var id, inv = setInterval(async () => {
        // Check if is in accepting match found
        if (await isInProgress()) {
            // Accept match
            await acceptMatch()
        } else if ((id = await getActionId()) > -1) {
            // Pick each champs
            for (var i = 0; i < championIds.length; ++i) {
                if (await pick(id, championIds[i])) {
                    break // Break on picked done
                }
            }
            // Lock
            await lock(id)
            // Stop this callback
            clearInterval(inv)
        }
    }, 250) // Default timeout is 250ms
}
