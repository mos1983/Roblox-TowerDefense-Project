return {
    getReward = function(wave: number): number
        local base = 500 + (wave - 1) * 200
        if wave % 10 == 0 then
            base += 500
        end
        return base
    end,

    waves = {
        [1] = {
            { enemyName = "nRat", count = 5, interval = 1.5 },
        },
        [2] = {
            { enemyName = "nRat", count = 7, interval = 1.5 },
        },
        [3] = {
            { enemyName = "nRat", count = 6, interval = 1.5 },
            { enemyName = "TestingEnemy3", count = 1, interval = 10 },
        },
        [4] = {
            { enemyName = "TestingEnemy", count = 1, interval = 1}
        }
    },
    
    waveDuration = 60,   -- เวลาต่อ Wave (วินาที)
    shortCountdown = 5,  -- นับถอยหลังเมื่อมอนหมดก่อนเวลา
}