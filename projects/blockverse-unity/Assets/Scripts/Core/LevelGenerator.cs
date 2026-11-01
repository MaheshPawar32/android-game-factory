using System;

namespace Blockverse
{
    public enum LevelGoal { ClearLines, ReachScore, LimitedMoves, Boss }

    public sealed class LevelConfig
    {
        public int Level { get; set; }
        public int Seed { get; init; }
        public int BoardSize { get; init; }
        public int Target { get; init; }
        public int MoveLimit { get; init; }
        public int ObstacleCount { get; init; }
        public LevelGoal Goal { get; init; }
    }

    public static class LevelGenerator
    {
        public static LevelConfig Generate(int level)
        {
            level = Math.Max(1, level);
            bool boss = level % 25 == 0;
            bool scoreTrial = !boss && level % 7 == 0;
            bool limitedMoves = !boss && level % 5 == 0;
            return new LevelConfig
            {
                Level = level,
                Seed = level * 7919,
                BoardSize = Math.Min(10, 8 + level / 40),
                Target = boss ? 12 + level / 20 : 5 + level / 8,
                MoveLimit = boss ? 18 : limitedMoves || scoreTrial ? 24 : 0,
                ObstacleCount = level < 4 ? 0 : Math.Min(12, 1 + level / 18),
                Goal = boss ? LevelGoal.Boss : scoreTrial ? LevelGoal.ReachScore : limitedMoves ? LevelGoal.LimitedMoves : LevelGoal.ClearLines
            };
        }
    }
}
