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
        MaxDurationSeconds = 10,

        -- Shooting: short pulse on the first detected shot; refresh for sustained fire.
        ShotMinSeconds = 1,
        ShotMaxSeconds = 2,
        ContinuousFireIntensity = 65,
        ContinuousRefreshSeconds = 1,
        AutomaticFireThresholdMilliseconds = 350,

        DamageIntensity = 55,
        DamageDurationSeconds = 2,

        ExplosionIntensity = 70,
        ExplosionDurationSeconds = 2,
        ExplosionCooldownMilliseconds = 1200,

        CollisionIntensity = 55,
        CollisionDurationSeconds = 1,
        CollisionSpeedDrop = 8.0,
        MinimumCollisionSpeed = 5.0,
        CollisionCooldownMilliseconds = 1500,

        FallIntensity = 45,
        FallDurationSeconds = 1,

        MeleeIntensity = 45,
        MeleeDurationSeconds = 1,

        EventCooldownMilliseconds = 500,

        EnableDamage = true,
        EnableExplosions = true,
        EnableCollisions = true,
        EnableFalls = true,
        EnableMelee = true
    }
}
