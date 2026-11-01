using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

namespace Blockverse
{
    public sealed class GameController : MonoBehaviour
    {
        [SerializeField] private RectTransform boardRoot;
        [SerializeField] private RectTransform trayRoot;
        [SerializeField] private Text scoreLabel;
        [SerializeField] private Text goalLabel;
        [SerializeField] private Text hintLabel;
        [SerializeField] private Button restartButton;

        private BoardModel board;
        private int score;
        private int level = 1;
        private LevelConfig config;
        private readonly List<PieceDragView> trayPieces = new List<PieceDragView>();
        private int piecesUsed;
        private int randomSeed;

        private void Start()
        {
            if (restartButton != null) restartButton.onClick.AddListener(StartLevel);
            StartLevel();
        }

        public void StartLevel()
        {
            config = LevelGenerator.Generate(level);
            board = new BoardModel(config.BoardSize, config.BoardSize);
            score = 0;
            piecesUsed = 0;
            randomSeed = config.Seed;
            PlaceLevelObstacles();
            RefreshLabels();
            BuildBoard();
            GenerateTray();
        }

        private void BuildBoard()
        {
            if (boardRoot == null) return;
            foreach (Transform child in boardRoot) Destroy(child.gameObject);
            var grid = boardRoot.GetComponent<GridLayoutGroup>();
            if (grid == null) grid = boardRoot.gameObject.AddComponent<GridLayoutGroup>();
            grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            grid.constraintCount = config.BoardSize;
            grid.spacing = new Vector2(5, 5);
            float cell = Mathf.Floor((boardRoot.rect.width - 5f * (config.BoardSize - 1)) / config.BoardSize);
            grid.cellSize = new Vector2(cell, cell);
            for (int y = 0; y < config.BoardSize; y++)
            for (int x = 0; x < config.BoardSize; x++)
            {
                var tile = new GameObject($"Cell_{x}_{y}", typeof(RectTransform), typeof(Image));
                tile.transform.SetParent(boardRoot, false);
                tile.GetComponent<Image>().color = new Color(0.13f, 0.17f, 0.24f, 1f);
            }
            RefreshBoardVisuals();
        }

        private void PlaceLevelObstacles()
        {
            if (config.ObstacleCount <= 0) return;
            var random = new System.Random(config.Seed ^ 0x5F3759DF);
            int placed = 0;
            int attempts = config.ObstacleCount * 12;
            while (placed < config.ObstacleCount && attempts-- > 0)
            {
                int x = random.Next(board.Width);
                int y = random.Next(board.Height);
                if (board.GetCell(x, y) != CellType.Empty) continue;
                var type = random.Next(2) == 0 ? CellType.Stone : CellType.Ice;
                board.SetObstacle(x, y, type);
                placed++;
            }
        }

        private void GenerateTray()
        {
            if (trayRoot == null) return;
            foreach (Transform child in trayRoot) Destroy(child.gameObject);
            trayPieces.Clear();
            piecesUsed = 0;
            var random = new System.Random(randomSeed++);
            for (int i = 0; i < 3; i++)
            {
                int shapeIndex = random.Next(PieceLibrary.Shapes.Length);
                var pieceObject = new GameObject($"Piece_{i}", typeof(RectTransform), typeof(PieceDragView));
                pieceObject.transform.SetParent(trayRoot, false);
                var view = pieceObject.GetComponent<PieceDragView>();
                view.Initialize(this, PieceLibrary.Shapes[shapeIndex], trayRoot);
                trayPieces.Add(view);
            }
            if (hintLabel != null) hintLabel.text = "DRAG A BLOCK ONTO THE BOARD";
        }

        public bool TryDrop(bool[,] shape, Vector2 screenPosition, Camera eventCamera)
        {
            if (boardRoot == null || board == null) return false;
            if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(boardRoot, screenPosition, eventCamera, out Vector2 local))
                return false;

            var grid = boardRoot.GetComponent<GridLayoutGroup>();
            float pitchX = grid.cellSize.x + grid.spacing.x;
            float pitchY = grid.cellSize.y + grid.spacing.y;
            int x = Mathf.FloorToInt((local.x - boardRoot.rect.xMin) / pitchX);
            int y = Mathf.FloorToInt((boardRoot.rect.yMax - local.y) / pitchY);
            x -= shape.GetLength(1) / 2;
            y -= shape.GetLength(0) / 2;

            if (!board.TryPlace(shape, x, y))
            {
                if (hintLabel != null) hintLabel.text = "NOT A VALID POSITION — TRY AGAIN";
                return false;
            }

            int cleared = board.ClearCompletedLines();
            score += shape.Length + cleared * config.BoardSize * 10;
            RefreshBoardVisuals();
            RefreshLabels();
            if (hintLabel != null) hintLabel.text = cleared > 0 ? $"NICE! {cleared} LINE(S) CLEARED" : "GOOD MOVE!";
            return true;
        }

        public void ConsumePiece(PieceDragView piece)
        {
            if (piece == null) return;
            piece.gameObject.SetActive(false);
            piecesUsed++;
            if (piecesUsed >= 3) GenerateTray();
            else CheckGameOver();
        }

        private void CheckGameOver()
        {
            foreach (var piece in trayPieces)
            {
                if (piece == null || !piece.gameObject.activeSelf) continue;
                if (HasAnyPlacement(piece.Shape)) return;
            }
            if (hintLabel != null) hintLabel.text = "NO MORE MOVES — RESTART TO TRY AGAIN";
            foreach (var piece in trayPieces)
                if (piece != null) piece.enabled = false;
        }

        private bool HasAnyPlacement(bool[,] shape)
        {
            for (int y = 0; y < board.Height; y++)
            for (int x = 0; x < board.Width; x++)
                if (board.CanPlace(shape, x, y)) return true;
            return false;
        }

        private void RefreshBoardVisuals()
        {
            int index = 0;
            foreach (Transform child in boardRoot)
            {
                int x = index % board.Width;
                int y = index / board.Width;
                var image = child.GetComponent<Image>();
                switch (board.GetCell(x, y))
                {
                    case CellType.Normal: image.color = new Color(0.24f, 0.63f, 1f); break;
                    case CellType.Stone: image.color = new Color(0.38f, 0.4f, 0.45f); break;
                    case CellType.Ice: image.color = new Color(0.35f, 0.85f, 1f); break;
                    case CellType.CrackedIce: image.color = new Color(0.2f, 0.58f, 0.7f); break;
                    default: image.color = new Color(0.13f, 0.17f, 0.24f); break;
                }
                index++;
            }
        }

        private void RefreshLabels()
        {
            if (scoreLabel != null) scoreLabel.text = $"SCORE  {score:N0}";
            if (goalLabel != null) goalLabel.text = $"LEVEL {level}  •  {config?.Goal.ToString().ToUpperInvariant()}";
        }
    }
}
