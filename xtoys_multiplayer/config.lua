Config = {
    OpenCommand = 'xtoys',
    StopCommand = 'xtoysstop',
    InviteTimeoutSeconds = 30,
    ControlRequestTimeoutSeconds = 20,
    MaxIntensity = 100,
    MaxDurationSeconds = 10,

    -- XToys Webhook trigger action names. Create matching actions in your XToys script.
    XToysActions = {
        setIntensity = 'setintensity',
        stop = 'stop'
    },

    -- ERP integration is intentionally disabled until the server's ERP resource is identified.
    ERP = {
        Enabled = false,
        ResourceName = '',
        -- Add documented, allow-listed ERP events only after confirming the ERP resource API.
    }
}
