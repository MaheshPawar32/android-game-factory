using System;
using System.Collections.Generic;

namespace Blockverse
{
    public enum CellType
    {
        Empty = 0,
        Normal = 1,
        Stone = 90,
        Ice = 91,
        CrackedIce = 92
    }

    public sealed class BoardModel
    {
        public int Width { get; }
        public int Height { get; }
        private readonly CellType[,] cells;

        public BoardModel(int width, int height)
        {
            Width = Math.Max(5, Math.Min(10, width));
            Height = Math.Max(5, Math.Min(10, height));
            cells = new CellType[Width, Height];
        }

        public CellType GetCell(int x, int y)
        {
            if (!IsInside(x, y)) throw new ArgumentOutOfRangeException();
            return cells[x, y];
        }

        public bool CanPlace(bool[,] shape, int originX, int originY)
        {
            for (int y = 0; y < shape.GetLength(0); y++)
            for (int x = 0; x < shape.GetLength(1); x++)
            {
                if (!shape[y, x]) continue;
                int bx = originX + x;
                int by = originY + y;
                if (!IsInside(bx, by) || cells[bx, by] != CellType.Empty) return false;
            }
            return true;
        }

        public bool TryPlace(bool[,] shape, int originX, int originY)
        {
            if (!CanPlace(shape, originX, originY)) return false;
            for (int y = 0; y < shape.GetLength(0); y++)
            for (int x = 0; x < shape.GetLength(1); x++)
                if (shape[y, x]) cells[originX + x, originY + y] = CellType.Normal;
            return true;
        }

        public int ClearCompletedLines()
        {
            var rows = new HashSet<int>();
            var columns = new HashSet<int>();
            for (int y = 0; y < Height; y++)
            {
                bool full = true;
                for (int x = 0; x < Width; x++) full &= cells[x, y] != CellType.Empty;
                if (full) rows.Add(y);
            }
            for (int x = 0; x < Width; x++)
            {
                bool full = true;
                for (int y = 0; y < Height; y++) full &= cells[x, y] != CellType.Empty;
                if (full) columns.Add(x);
            }

            var affected = new HashSet<(int x, int y)>();
            foreach (int y in rows)
                for (int x = 0; x < Width; x++) affected.Add((x, y));
            foreach (int x in columns)
                for (int y = 0; y < Height; y++) affected.Add((x, y));

            foreach (var p in affected)
            {
                if (cells[p.x, p.y] == CellType.Ice) cells[p.x, p.y] = CellType.CrackedIce;
                else cells[p.x, p.y] = CellType.Empty;
            }
            return rows.Count + columns.Count;
        }

        public int CountObstacles()
        {
            int count = 0;
            foreach (CellType cell in cells)
                if (cell == CellType.Stone || cell == CellType.Ice || cell == CellType.CrackedIce) count++;
            return count;
        }

        public void SetObstacle(int x, int y, CellType type)
        {
            if (!IsInside(x, y)) throw new ArgumentOutOfRangeException();
            if (type != CellType.Stone && type != CellType.Ice) throw new ArgumentException("Only obstacle types are allowed.");
            if (cells[x, y] != CellType.Empty) throw new InvalidOperationException("Cell is occupied.");
            cells[x, y] = type;
        }

        private bool IsInside(int x, int y) => x >= 0 && x < Width && y >= 0 && y < Height;
    }
}
