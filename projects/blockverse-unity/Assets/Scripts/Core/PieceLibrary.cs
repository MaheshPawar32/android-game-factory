namespace Blockverse
{
    public static class PieceLibrary
    {
        public static readonly bool[][,] Shapes =
        {
            new bool[,] { { true } },
            new bool[,] { { true, true } },
            new bool[,] { { true, true, true } },
            new bool[,] { { true, true }, { true, true } },
            new bool[,] { { true, false }, { true, true } },
            new bool[,] { { false, true }, { true, true } },
            new bool[,] { { true, true, true }, { false, true, false } },
            new bool[,] { { true, false, false }, { true, true, true } },
            new bool[,] { { false, false, true }, { true, true, true } }
        };
    }
}
