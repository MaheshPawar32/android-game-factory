using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

namespace Blockverse
{
    public sealed class GameController : MonoBehaviour
    {
        [SerializeField] private RectTransform boardRoot, trayRoot;
        [SerializeField] private Text scoreLabel, goalLabel, hintLabel;
        [SerializeField] private Button restartButton;

        private BoardModel board;
        private int score, level = 1, randomSeed, piecesUsed, bestScore, coins, linesCleared, movesUsed;
        private LevelConfig config;
        private readonly List<PieceDragView> trayPieces = new List<PieceDragView>();
        private bool levelFinished;
        private GameObject resultOverlay;

        private void Start()
        {
            bestScore = PlayerPrefs.GetInt("blockverse_best_score", 0);
            coins = PlayerPrefs.GetInt("blockverse_coins", 0);
            level = PlayerPrefs.GetInt("blockverse_level", 1);
            if (restartButton != null) restartButton.onClick.AddListener(StartLevel);
            StartLevel();
        }

        public void StartLevel()
        {
            levelFinished = false;
            if (resultOverlay != null) Destroy(resultOverlay);
            config = LevelGenerator.Generate(level);
            board = new BoardModel(config.BoardSize, config.BoardSize);
            score = linesCleared = movesUsed = piecesUsed = 0;
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
                tile.GetComponent<Image>().color = new Color(.13f, .17f, .24f, 1);
            }
            RefreshBoardVisuals();
        }

        private void PlaceLevelObstacles()
        {
            if (config.ObstacleCount <= 0) return;
            var random = new System.Random(config.Seed ^ 0x5F3759DF);
            int placed = 0, attempts = config.ObstacleCount * 12;
            while (placed < config.ObstacleCount && attempts-- > 0)
            {
                int x = random.Next(board.Width), y = random.Next(board.Height);
                if (board.GetCell(x, y) != CellType.Empty) continue;
                board.SetObstacle(x, y, random.Next(2) == 0 ? CellType.Stone : CellType.Ice);
                placed++;
            }
        }

        private void GenerateTray()
        {
            if (trayRoot == null || levelFinished) return;
            foreach (Transform child in trayRoot) Destroy(child.gameObject);
            trayPieces.Clear();
            piecesUsed = 0;
            var random = new System.Random(randomSeed++);
            for (int i = 0; i < 3; i++)
            {
                var go = new GameObject($"Piece_{i}", typeof(RectTransform), typeof(PieceDragView));
                go.transform.SetParent(trayRoot, false);
                var view = go.GetComponent<PieceDragView>();
                view.Initialize(this, PieceLibrary.CreateRandom(random), trayRoot);
                trayPieces.Add(view);
            }
            if (hintLabel != null) hintLabel.text = "DRAG A BLOCK ONTO THE BOARD";
            CheckGameOver();
        }

        public bool TryDrop(PieceDefinition piece, Vector2 screen, Camera eventCamera)
        {
            if (levelFinished || boardRoot == null || board == null) return false;
            if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(boardRoot, screen, eventCamera, out Vector2 local)) return false;
            var grid = boardRoot.GetComponent<GridLayoutGroup>();
            float pitchX = grid.cellSize.x + grid.spacing.x, pitchY = grid.cellSize.y + grid.spacing.y;
            int x = Mathf.FloorToInt((local.x - boardRoot.rect.xMin) / pitchX);
            int y = Mathf.FloorToInt((boardRoot.rect.yMax - local.y) / pitchY);
            x -= piece.Shape.GetLength(1) / 2;
            y -= piece.Shape.GetLength(0) / 2;
            if (!board.TryPlace(piece.Shape, x, y))
            {
                if (hintLabel != null) hintLabel.text = "NOT A VALID POSITION — TRY AGAIN";
                return false;
            }

            movesUsed++;
            int centerX = x + piece.Shape.GetLength(1) / 2;
            int centerY = y + piece.Shape.GetLength(0) / 2;
            int affected = 0;
            switch (piece.Special)
            {
                case SpecialPieceType.Bomb: affected = board.Blast(centerX, centerY); break;
                case SpecialPieceType.Rainbow: affected = board.ClearRow(centerY); break;
                case SpecialPieceType.Lightning: affected = board.ClearColumn(centerX); break;
            }

            int cleared = board.ClearCompletedLines();
            linesCleared += cleared;
            score += CountCells(piece.Shape) * 10 + cleared * config.BoardSize * 10 + affected * 5;
            if (score > bestScore)
            {
                bestScore = score;
                PlayerPrefs.SetInt("blockverse_best_score", bestScore);
            }
            if (cleared > 0) coins += cleared * 2;
            PlayerPrefs.SetInt("blockverse_coins", coins);
            PlayerPrefs.Save();
            RefreshBoardVisuals();
            RefreshLabels();

            if (IsObjectiveComplete()) CompleteLevel();
            else if (config.MoveLimit > 0 && movesUsed >= config.MoveLimit) FailLevel("MOVE LIMIT REACHED");
            else if (hintLabel != null)
                hintLabel.text = (cleared > 0 ? $"NICE! {cleared} LINE(S) CLEARED" : "GOOD MOVE!") +
                    (piece.Special == SpecialPieceType.None ? "" : $" — {piece.Special.ToString().ToUpperInvariant()}");
            return true;
        }

        private bool IsObjectiveComplete()
        {
            switch (config.Goal)
            {
                case LevelGoal.ClearLines: return linesCleared >= config.Target;
                case LevelGoal.ReachScore: return score >= config.Target * 100;
                case LevelGoal.LimitedMoves: return linesCleared >= config.Target;
                case LevelGoal.Boss: return board.CountObstacles() == 0;
                default: return false;
            }
        }

        private string ObjectiveText()
        {
            switch (config.Goal)
            {
                case LevelGoal.ClearLines: return $"LINES {linesCleared}/{config.Target}";
                case LevelGoal.ReachScore: return $"SCORE {score}/{config.Target * 100}";
                case LevelGoal.LimitedMoves: return $"LINES {linesCleared}/{config.Target}  •  MOVES {movesUsed}/{config.MoveLimit}";
                case LevelGoal.Boss: return $"BOSS OBSTACLES {board.CountObstacles()} LEFT";
                default: return config.Goal.ToString().ToUpperInvariant();
            }
        }

        private void CompleteLevel()
        {
            if (levelFinished) return;
            levelFinished = true;
            int reward = 20 + level * 2;
            coins += reward;
            int unlocked = Mathf.Max(PlayerPrefs.GetInt("blockverse_level", 1), level + 1);
            PlayerPrefs.SetInt("blockverse_level", unlocked);
            PlayerPrefs.SetInt("blockverse_coins", coins);
            PlayerPrefs.SetInt($"blockverse_level_{level}_stars", 3);
            PlayerPrefs.Save();
            ShowResult(true, "LEVEL COMPLETE!", $"You cleared level {level}.\n+{reward} BONUS COINS\nScore: {score:N0}");
        }

        private void FailLevel(string reason)
        {
            if (levelFinished) return;
            levelFinished = true;
            ShowResult(false, "TRY AGAIN", $"{reason}\nProgress: {ObjectiveText()}\nScore: {score:N0}");
        }

        private void ShowResult(bool won, string heading, string message)
        {
            if (resultOverlay != null) Destroy(resultOverlay);
            Canvas canvas = boardRoot != null ? boardRoot.GetComponentInParent<Canvas>() : null;
            if (canvas == null) return;

            resultOverlay = new GameObject("LevelResultOverlay", typeof(RectTransform), typeof(Image));
            resultOverlay.transform.SetParent(canvas.transform, false);
            var overlayRect = resultOverlay.GetComponent<RectTransform>();
            overlayRect.anchorMin = Vector2.zero;
            overlayRect.anchorMax = Vector2.one;
            overlayRect.offsetMin = Vector2.zero;
            overlayRect.offsetMax = Vector2.zero;
            resultOverlay.GetComponent<Image>().color = new Color(.025f, .04f, .08f, .88f);

            var card = new GameObject("ResultCard", typeof(RectTransform), typeof(Image));
            card.transform.SetParent(resultOverlay.transform, false);
            var cardRect = card.GetComponent<RectTransform>();
            cardRect.anchorMin = new Vector2(.1f, .34f);
            cardRect.anchorMax = new Vector2(.9f, .66f);
            cardRect.offsetMin = Vector2.zero;
            cardRect.offsetMax = Vector2.zero;
            card.GetComponent<Image>().color = new Color(.09f, .13f, .21f, 1);

            CreateOverlayText(card.transform, heading, 48, new Vector2(0, 145), new Vector2(760, 90), new Color(1, .82f, .35f));
            CreateOverlayText(card.transform, message, 28, new Vector2(0, 25), new Vector2(760, 150), Color.white);
            CreateOverlayButton(card.transform, won ? "NEXT LEVEL" : "RETRY", new Vector2(0, -115), won ? (UnityEngine.Events.UnityAction)GoToNextLevel : StartLevel);
        }

        private void CreateOverlayText(Transform parent, string value, int size, Vector2 position, Vector2 dimensions, Color color)
        {
            var go = new GameObject("ResultText", typeof(RectTransform), typeof(Text));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.sizeDelta = dimensions;
            rect.anchoredPosition = position;
            var text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            text.fontSize = size;
            text.fontStyle = FontStyle.Bold;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = color;
            text.text = value;
        }

        private void CreateOverlayButton(Transform parent, string label, Vector2 position, UnityEngine.Events.UnityAction action)
        {
            var go = new GameObject("ResultButton", typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.sizeDelta = new Vector2(440, 90);
            rect.anchoredPosition = position;
            go.GetComponent<Image>().color = new Color(.2f, .53f, .95f);
            var button = go.GetComponent<Button>();
            button.onClick.AddListener(action);
            CreateOverlayText(go.transform, label, 30, Vector2.zero, new Vector2(420, 80), Color.white);
        }

        private void GoToNextLevel()
        {
            level++;
            PlayerPrefs.SetInt("blockverse_level", level);
            PlayerPrefs.Save();
            StartLevel();
        }

        private int CountCells(bool[,] shape)
        {
            int count = 0;
            foreach (bool filled in shape) if (filled) count++;
            return count;
        }

        public void ConsumePiece(PieceDragView piece)
        {
            if (piece == null) return;
            piece.gameObject.SetActive(false);
            if (levelFinished) return;
            piecesUsed++;
            if (piecesUsed >= 3) GenerateTray();
            else CheckGameOver();
        }

        private void CheckGameOver()
        {
            if (levelFinished || trayPieces.Count == 0) return;
            foreach (var piece in trayPieces)
                if (piece != null && piece.gameObject.activeSelf && HasAnyPlacement(piece.Definition.Shape)) return;
            foreach (var piece in trayPieces) if (piece != null) piece.enabled = false;
            FailLevel("NO VALID MOVES");
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
            if (boardRoot == null || board == null) return;
            int index = 0;
            foreach (Transform child in boardRoot)
            {
                int x = index % board.Width, y = index / board.Width;
                var image = child.GetComponent<Image>();
                switch (board.GetCell(x, y))
                {
                    case CellType.Normal: image.color = new Color(.24f, .63f, 1); break;
                    case CellType.Stone: image.color = new Color(.38f, .4f, .45f); break;
                    case CellType.Ice: image.color = new Color(.35f, .85f, 1); break;
                    case CellType.CrackedIce: image.color = new Color(.2f, .58f, .7f); break;
                    default: image.color = new Color(.13f, .17f, .24f); break;
                }
                index++;
            }
        }

        private void RefreshLabels()
        {
            if (scoreLabel != null) scoreLabel.text = $"SCORE  {score:N0}";
            if (goalLabel != null) goalLabel.text = $"LEVEL {level}  •  {ObjectiveText()}  •  BEST {bestScore:N0}  •  COINS {coins}";
        }
    }
}