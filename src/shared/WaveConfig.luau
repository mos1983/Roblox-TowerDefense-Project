return {
    getReward = function(wave: number): number
        local base = 40 + (wave - 1) * 20
        if wave % 10 == 0 then
            base += 80
        end
        return base
    end,

    waves = {
        [1] = {
            { enemyName = "nRat", count = 3, interval = 2 },
        },
        [2] = {
            { enemyName = "nRat", count = 5, interval = 2 },
        },
        [3] = {
            { enemyName = "nRat", count = 5, interval = 1.5 },
            { enemyName = "JetRat", count = 1, interval = 10 },
        },
        [4] = {
            { enemyName = "nRat", count = 8, interval = 1},
            { enemyName = "JetRat", count = 3, interval = 4 },
        },
        [5] = {
            { enemyName = "nRat", count = 1, interval = 20},
            { enemyName = "TestingEnemy", count = 1, interval = 20}
        }
    },
    
    waveDuration = 60,   -- เวลาต่อ Wave (วินาที)
    shortCountdown = 5,  -- นับถอยหลังเมื่อมอนหมดก่อนเวลา
}