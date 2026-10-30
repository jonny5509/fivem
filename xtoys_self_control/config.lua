Config = {
    OpenCommand = 'xtoys',
    StopCommand = 'xtoysstop',
    ConnectCommand = 'xtoysconnect',
    DebugCommand = 'xtoysdebug',

    Debug = false,
    MaxIntensity = 100,

    Bollards = {
        Enabled = true,
        IntensityStep = 10,
        IdleStopMilliseconds = 30000,
        ScanIntervalMilliseconds = 200,
        NearbyDistanceMeters = 8,
        TipAngleDegrees = 30,
        Models = {
            'prop_bollard_01a', 'prop_bollard_01b', 'prop_bollard_01c',
            'prop_bollard_02a', 'prop_bollard_02b', 'prop_bollard_02c',
            'prop_bollard_03a', 'prop_bollard_04', 'prop_bollard_05',
            'prop_roadcone01a', 'prop_roadcone02a', 'prop_barier_conc_01a',
            'prop_mp_arrow_barrier_01'
        }
    },

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
