Config = {
    OpenCommand = 'xtoys',
    StopCommand = 'xtoysstop',
    ConnectCommand = 'xtoysconnect',
    DebugCommand = 'xtoysdebug',

    Debug = false,
    MaxIntensity = 100,

    XToysActions = {
        SetIntensity = 'setintensity',
        Stop = 'stop'
    },

    SelfControl = {
        PollMilliseconds = 50,

        -- A single shot gets a random pulse duration in this range.
        ShotMinSeconds = 1,
        ShotMaxSeconds = 3,

        -- Continuous fire is refreshed while firing and stopped immediately
        -- after firing ends.
        ContinuousFireIntensity = 100,
        ContinuousRefreshSeconds = 1,

        DamageIntensity = 75,
        DamageDurationSeconds = 2,

        ExplosionIntensity = 100,
        ExplosionDurationSeconds = 2,

        CollisionIntensity = 65,
        CollisionDurationSeconds = 1,

        FallIntensity = 55,
        FallDurationSeconds = 1,

        MeleeIntensity = 60,
        MeleeDurationSeconds = 1,

        EventCooldownMilliseconds = 250,

        EnableDamage = true,
        EnableExplosions = true,
        EnableCollisions = true,
        EnableFalls = true,
        EnableMelee = true
    }
}
