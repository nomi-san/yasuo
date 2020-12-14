                        // Yasuo
var start = (championIds = [157]) => {
    
    // Simple request with fetch API
    const request = async (url, method = 'GET', body = undefined) => (
        await fetch(url, {
            method,
            body: JSON.stringify(body),
            headers: { 'Content-type': 'application/json; charset=UTF-8' }
        }).then(res => res.ok ? res.json() : {})
    )
    
    // Check if match found is shown
    const isMatchFound = async () => (
        (await request('/lol-matchmaking/v1/ready-check'))
            .state === 'InProgress' // Default state
    )
    
    // Accept match
    const acceptMatch = async () => (
        await request('/lol-matchmaking/v1/ready-check/accept', 'POST')
    )
    
    // Get your action ID
    const getActionId = async () => {
        const { localPlayerCellId, actions } = await request('/lol-champ-select/v1/session')
        if (!actions) return -1
        return actions[0] // Index 0 is our team
            .find(a => a.actorCellId === localPlayerCellId) // Just find current player
            .id // We found action ID
    }
    
    // Pick a champion
    const pick = async (id, championId) => (
        Object.keys(await request(
            `/lol-champ-select/v1/session/actions/${id}`,
            'PATCH', { championId }
        )).length === 0 // Succeed
    )
    
    // Lock the selection
    const lock = async (id) => (
        await request(`/lol-champ-select/v1/session/actions/${id}/complete`, 'POST')
    )
    
    // Start auto accept match found and pick-lock
    const inv = setInterval(async () => {
        // Check for match found
        if (await isMatchFound()) {
            // Accept match
            await acceptMatch()
        } else {
            const id = await getActionId()
            // Check for valid action ID
            if (id > -1) {
                // Pick each champ until done
                await championIds.some(async champId => await pick(id, champId))
                // Lock
                await lock(id)
                // Stop this callback
                clearInterval(inv)
            }
        }
    }, 250) // Default timeout is 250ms
}
