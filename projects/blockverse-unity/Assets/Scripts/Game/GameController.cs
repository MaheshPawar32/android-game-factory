using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Collections.Generic;

namespace Blockverse
{
    public sealed class GameController : MonoBehaviour
    {
        [SerializeField] private RectTransform boardRoot, trayRoot;
        [SerializeField] private Text scoreLabel, goalLabel, hintLabel;
        [SerializeField] private Button restartButton;
        private BoardModel board;
        private int score, level = 1, randomSeed, piecesUsed, bestScore, coins, linesCleared, movesUsed, comboStreak;
        private LevelConfig config;
        private readonly List<PieceDragView> trayPieces = new List<PieceDragView>();
        private bool levelFinished;
        private bool reviveUsed;
        private GameObject pauseOverlay;
        private GameObject resultOverlay, menuOverlay;
        private bool vibrationEnabled;
        private GameAudio gameAudio;
        private Button audioButton;
        private readonly List<Coroutine> runningEffects = new List<Coroutine>();

        private void Start()
        {
            gameAudio = gameObject.AddComponent<GameAudio>();
            bestScore = PlayerPrefs.GetInt("blockverse_best_score", 0);
            coins = PlayerPrefs.GetInt("blockverse_coins", 0);
            level = PlayerPrefs.GetInt("blockverse_level", 1);
            if (restartButton != null) restartButton.onClick.AddListener(StartLevel);
            vibrationEnabled = PlayerPrefs.GetInt("blockverse_vibration", 1) == 1;
            CreateAudioToggle();
            StartLevel();
            ShowMainMenu();
        }

        private void CreateAudioToggle()
        {
            Canvas canvas = boardRoot != null ? boardRoot.GetComponentInParent<Canvas>() : null;
            if (canvas == null) return;
            var go = new GameObject("SoundToggle", typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(canvas.transform, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(1, 1);
            rect.anchorMax = new Vector2(1, 1);
            rect.pivot = new Vector2(1, 1);
            rect.anchoredPosition = new Vector2(-28, -28);
            rect.sizeDelta = new Vector2(150, 64);
            go.GetComponent<Image>().color = new Color(.13f, .2f, .32f, 1);
            audioButton = go.GetComponent<Button>();
            audioButton.onClick.AddListener(() => { gameAudio.ToggleMute(); RefreshAudioButton(); });
            var labelObject = new GameObject("Label", typeof(RectTransform), typeof(Text));
            labelObject.transform.SetParent(go.transform, false);
            var labelRect = labelObject.GetComponent<RectTransform>();
            labelRect.anchorMin = Vector2.zero; labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = Vector2.zero; labelRect.offsetMax = Vector2.zero;
            var label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            label.fontSize = 24; label.alignment = TextAnchor.MiddleCenter; label.color = Color.white;
            RefreshAudioButton();
        }

        private void RefreshAudioButton()
        {
            if (audioButton == null) return;
            var label = audioButton.GetComponentInChildren<Text>();
            if (label != null) label.text = gameAudio.Muted ? "SOUND OFF" : "SOUND ON";
        }

        public void StartLevel()
        {
            Time.timeScale = 1f;
            reviveUsed = false;
            levelFinished = false;
            if (resultOverlay != null) Destroy(resultOverlay);
            if (menuOverlay != null) Destroy(menuOverlay);
            config = LevelGenerator.Generate(level);
            board = new BoardModel(config.BoardSize, config.BoardSize);
            score = linesCleared = movesUsed = piecesUsed = comboStreak = 0;
            randomSeed = config.Seed;
            PlaceLevelObstacles();
            RefreshLabels();
            BuildBoard();
            GenerateTray();
            CreateMenuButton();
            CreatePauseButton();
        }

        private void CreateMenuButton()
        {
            Canvas canvas = boardRoot != null ? boardRoot.GetComponentInParent<Canvas>() : null;
            if (canvas == null || canvas.transform.Find("GameMenuButton") != null) return;
            var go = new GameObject("GameMenuButton", typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(canvas.transform, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0, 1); rect.anchorMax = new Vector2(0, 1);
            rect.pivot = new Vector2(0, 1); rect.anchoredPosition = new Vector2(28, -28);
            rect.sizeDelta = new Vector2(125, 64);
            go.GetComponent<Image>().color = new Color(.13f, .2f, .32f, 1);
            go.GetComponent<Button>().onClick.AddListener(ShowMainMenu);
            CreateOverlayText(go.transform, "MENU", 23, Vector2.zero, new Vector2(120, 60), Color.white);
        }


        private void CreatePauseButton()
        {
            Canvas canvas = GetCanvas();
            if (canvas == null || canvas.transform.Find("GamePauseButton") != null) return;
            var go = new GameObject("GamePauseButton", typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(canvas.transform, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(1, 1); rect.anchorMax = new Vector2(1, 1);
            rect.pivot = new Vector2(1, 1); rect.anchoredPosition = new Vector2(-190, -28);
            rect.sizeDelta = new Vector2(125, 64);
            go.GetComponent<Image>().color = new Color(.13f, .2f, .32f, 1);
            go.GetComponent<Button>().onClick.AddListener(PauseGame);
            CreateOverlayText(go.transform, "PAUSE", 22, Vector2.zero, new Vector2(120, 60), Color.white);
        }

        private void PauseGame()
        {
            if (levelFinished || pauseOverlay != null || menuOverlay != null) return;
            Canvas canvas = GetCanvas();
            if (canvas == null) return;
            Time.timeScale = 0f;
            pauseOverlay = CreateMenuOverlay(canvas, "PAUSED", "TAKE A BREATHER");
            CreateOverlayButton(pauseOverlay.transform, "RESUME", new Vector2(0, 65), ResumeGame);
            CreateOverlayButton(pauseOverlay.transform, "RESTART LEVEL", new Vector2(0, -45), () => { Time.timeScale = 1f; StartLevel(); });
            CreateOverlayButton(pauseOverlay.transform, "MAIN MENU", new Vector2(0, -155), () => { Time.timeScale = 1f; if (pauseOverlay != null) Destroy(pauseOverlay); pauseOverlay = null; ShowMainMenu(); });
        }

        private void ResumeGame()
        {
            if (pauseOverlay != null) Destroy(pauseOverlay);
            pauseOverlay = null;
            Time.timeScale = 1f;
        }

        private void ReviveLevel()
        {
            if (reviveUsed || !levelFinished || coins < 50) return;
            reviveUsed = true;
            coins -= 50;
            PlayerPrefs.SetInt("blockverse_coins", coins);
            PlayerPrefs.Save();
            if (resultOverlay != null) Destroy(resultOverlay);
            resultOverlay = null;
            levelFinished = false;
            if (config.MoveLimit > 0 && movesUsed >= config.MoveLimit) config.MoveLimit += 3;
            board.ClearRandomOccupied(5, randomSeed++);
            foreach (var piece in trayPieces) if (piece != null) Destroy(piece.gameObject);
            trayPieces.Clear();
            GenerateTray();
            RefreshBoardVisuals();
            RefreshLabels();
            if (hintLabel != null) hintLabel.text = "REVIVED! 5 CELLS CLEARED — KEEP GOING";
        }

        private Canvas GetCanvas() => boardRoot != null ? boardRoot.GetComponentInParent<Canvas>() : null;

        private void ShowMainMenu()
        {
            Time.timeScale = 1f;
            if (pauseOverlay != null) { Destroy(pauseOverlay); pauseOverlay = null; }
            Canvas canvas = GetCanvas(); if (canvas == null) return;
            if (menuOverlay != null) Destroy(menuOverlay);
            menuOverlay = CreateMenuOverlay(canvas, "BLOCKVERSE", "BLOCK PUZZLE ADVENTURE");
            CreateOverlayButton(menuOverlay.transform, "PLAY", new Vector2(0, 135), () => { Destroy(menuOverlay); menuOverlay = null; });
            CreateOverlayButton(menuOverlay.transform, "LEVEL SELECT", new Vector2(0, 55), ShowLevelSelect);
            CreateOverlayButton(menuOverlay.transform, "MISSIONS", new Vector2(0, -25), ShowMissions);
            CreateOverlayButton(menuOverlay.transform, "ACHIEVEMENTS", new Vector2(0, -105), ShowAchievements);
            CreateOverlayButton(menuOverlay.transform, "DAILY REWARD", new Vector2(0, -185), ClaimDailyReward);
            CreateOverlayButton(menuOverlay.transform, "SHOP", new Vector2(0, -265), ShowShop);
            CreateOverlayButton(menuOverlay.transform, "SETTINGS", new Vector2(0, -345), ShowSettings);
        }

        private GameObject CreateMenuOverlay(Canvas canvas, string title, string subtitle)
        {
            var overlay = new GameObject("MenuOverlay", typeof(RectTransform), typeof(Image));
            overlay.transform.SetParent(canvas.transform, false);
            var full = overlay.GetComponent<RectTransform>(); full.anchorMin = Vector2.zero; full.anchorMax = Vector2.one; full.offsetMin = Vector2.zero; full.offsetMax = Vector2.zero;
            overlay.GetComponent<Image>().color = new Color(.025f, .04f, .08f, .96f);
            CreateOverlayText(overlay.transform, title, 64, new Vector2(0, 285), new Vector2(850, 110), new Color(1f, .78f, .25f));
            CreateOverlayText(overlay.transform, subtitle, 24, new Vector2(0, 220), new Vector2(850, 55), Color.white);
            return overlay;
        }

        private void ShowLevelSelect()
        {
            Canvas canvas = GetCanvas(); if (canvas == null) return;
            if (menuOverlay != null) Destroy(menuOverlay);
            menuOverlay = CreateMenuOverlay(canvas, "LEVELS", "CHOOSE YOUR CHALLENGE");
            int unlocked = Mathf.Max(1, PlayerPrefs.GetInt("blockverse_level", 1));
            for (int i = 1; i <= 20; i++)
            {
                int selected = i; int col = (i - 1) % 4; int row = (i - 1) / 4;
                var go = new GameObject("Level_" + i, typeof(RectTransform), typeof(Image), typeof(Button));
                go.transform.SetParent(menuOverlay.transform, false);
                var rect = go.GetComponent<RectTransform>(); rect.sizeDelta = new Vector2(145, 105);
                rect.anchoredPosition = new Vector2(-255 + col * 170, 95 - row * 125);
                bool open = i <= unlocked;
                go.GetComponent<Image>().color = open ? new Color(.15f, .48f, .82f) : new Color(.18f, .21f, .27f);
                var button = go.GetComponent<Button>(); button.interactable = open;
                button.onClick.AddListener(() => { level = selected; PlayerPrefs.SetInt("blockverse_level", Mathf.Max(unlocked, selected)); PlayerPrefs.Save(); StartLevel(); });
                CreateOverlayText(go.transform, open ? i.ToString() : "LOCKED", 23, Vector2.zero, new Vector2(140, 100), Color.white);
            }
            CreateOverlayButton(menuOverlay.transform, "BACK", new Vector2(0, -300), ShowMainMenu);
        }

        private void EnsureMissionDay()
        {
            string today = System.DateTime.Now.ToString("yyyy-MM-dd");
            if (PlayerPrefs.GetString("blockverse_mission_date", "") == today) return;
            PlayerPrefs.SetString("blockverse_mission_date", today);
            PlayerPrefs.SetInt("blockverse_mission_blocks", 0);
            PlayerPrefs.SetInt("blockverse_mission_lines", 0);
            PlayerPrefs.SetInt("blockverse_mission_coins", 0);
            PlayerPrefs.SetInt("blockverse_mission_claimed", 0);
            PlayerPrefs.Save();
        }

        private void TrackMissionProgress(int blocks, int clearedLines, int earnedCoins)
        {
            EnsureMissionDay();
            PlayerPrefs.SetInt("blockverse_mission_blocks", PlayerPrefs.GetInt("blockverse_mission_blocks", 0) + blocks);
            PlayerPrefs.SetInt("blockverse_mission_lines", PlayerPrefs.GetInt("blockverse_mission_lines", 0) + clearedLines);
            PlayerPrefs.SetInt("blockverse_mission_coins", PlayerPrefs.GetInt("blockverse_mission_coins", 0) + earnedCoins);
            PlayerPrefs.SetInt("blockverse_total_blocks", PlayerPrefs.GetInt("blockverse_total_blocks", 0) + blocks);
            PlayerPrefs.SetInt("blockverse_total_lines", PlayerPrefs.GetInt("blockverse_total_lines", 0) + clearedLines);
            PlayerPrefs.Save();
            CheckAchievements();
        }

        private void CheckAchievements()
        {
            UnlockAchievement("first_block", PlayerPrefs.GetInt("blockverse_total_blocks", 0) >= 1, 20);
            UnlockAchievement("line_master", PlayerPrefs.GetInt("blockverse_total_lines", 0) >= 100, 100);
            UnlockAchievement("block_collector", PlayerPrefs.GetInt("blockverse_total_blocks", 0) >= 500, 100);
            UnlockAchievement("level_runner", PlayerPrefs.GetInt("blockverse_levels_won", 0) >= 10, 150);
            UnlockAchievement("high_scorer", bestScore >= 5000, 100);
        }

        private void UnlockAchievement(string id, bool condition, int reward)
        {
            string key = "blockverse_achievement_" + id;
            if (!condition || PlayerPrefs.GetInt(key, 0) == 1) return;
            PlayerPrefs.SetInt(key, 1);
            coins += reward;
            PlayerPrefs.SetInt("blockverse_coins", coins);
            PlayerPrefs.Save();
        }

        private void ShowMissions()
        {
            Canvas canvas = GetCanvas(); if (canvas == null) return;
            EnsureMissionDay();
            if (menuOverlay != null) Destroy(menuOverlay);
            menuOverlay = CreateMenuOverlay(canvas, "DAILY MISSIONS", $"COMPLETE TASKS TO EARN COINS  •  BALANCE {coins}");
            int blocks = PlayerPrefs.GetInt("blockverse_mission_blocks", 0);
            int lines = PlayerPrefs.GetInt("blockverse_mission_lines", 0);
            int earned = PlayerPrefs.GetInt("blockverse_mission_coins", 0);
            CreateOverlayText(menuOverlay.transform, $"PLACE BLOCKS  {Mathf.Min(blocks, 20)}/20\nCLEAR LINES  {Mathf.Min(lines, 5)}/5\nEARN COINS  {Mathf.Min(earned, 50)}/50", 30, new Vector2(0, 35), new Vector2(760, 250), Color.white);
            bool complete = blocks >= 20 && lines >= 5 && earned >= 50;
            bool claimed = PlayerPrefs.GetInt("blockverse_mission_claimed", 0) == 1;
            string rewardText = claimed ? "REWARD CLAIMED" : complete ? "CLAIM 100 COINS" : "KEEP PLAYING";
            CreateOverlayButton(menuOverlay.transform, rewardText, new Vector2(0, -150), () =>
            {
                if (!complete || claimed) { ShowMissions(); return; }
                PlayerPrefs.SetInt("blockverse_mission_claimed", 1);
                coins += 100; PlayerPrefs.SetInt("blockverse_coins", coins); PlayerPrefs.Save();
                RefreshLabels(); ShowMessage("MISSION REWARD!", "+100 COINS");
            });
            CreateOverlayButton(menuOverlay.transform, "BACK", new Vector2(0, -265), ShowMainMenu);
        }

        private void ShowAchievements()
        {
            Canvas canvas = GetCanvas(); if (canvas == null) return;
            if (menuOverlay != null) Destroy(menuOverlay);
            menuOverlay = CreateMenuOverlay(canvas, "ACHIEVEMENTS", "LIFETIME MILESTONES");
            string[] names = { "FIRST BLOCK", "LINE MASTER — 100 LINES", "BLOCK COLLECTOR — 500 BLOCKS", "LEVEL RUNNER — 10 WINS", "HIGH SCORER — 5,000 POINTS" };
            string[] ids = { "first_block", "line_master", "block_collector", "level_runner", "high_scorer" };
            string[] rewards = { "+20", "+100", "+100", "+150", "+100" };
            for (int i = 0; i < names.Length; i++)
            {
                bool unlocked = PlayerPrefs.GetInt("blockverse_achievement_" + ids[i], 0) == 1;
                CreateOverlayText(menuOverlay.transform, (unlocked ? "✓  " : "🔒  ") + names[i] + "   " + (unlocked ? "UNLOCKED" : rewards[i] + " COINS"), 21,
                    new Vector2(0, 130 - i * 65), new Vector2(850, 58), unlocked ? new Color(.45f, .9f, .65f) : Color.white);
            }
            CreateOverlayButton(menuOverlay.transform, "BACK", new Vector2(0, -260), ShowMainMenu);
        }

        private void ClaimDailyReward()
        {
            string today = System.DateTime.Now.ToString("yyyy-MM-dd");
            string last = PlayerPrefs.GetString("blockverse_daily_date", "");
            if (last == today) { ShowMessage("REWARD CLAIMED", "Come back tomorrow for your next reward."); return; }
            int streak = last == System.DateTime.Now.AddDays(-1).ToString("yyyy-MM-dd") ? PlayerPrefs.GetInt("blockverse_daily_streak", 0) + 1 : 1;
            streak = ((streak - 1) % 7) + 1;
            int reward = 25 + streak * 10; coins += reward;
            PlayerPrefs.SetString("blockverse_daily_date", today); PlayerPrefs.SetInt("blockverse_daily_streak", streak);
            PlayerPrefs.SetInt("blockverse_coins", coins); PlayerPrefs.Save(); RefreshLabels();
            ShowMessage("DAILY REWARD!", $"DAY {streak} STREAK\n+{reward} COINS");
        }

        private static readonly string[] ThemeNames = { "OCEAN", "EMBER", "FOREST", "VIOLET" };
        private static readonly int[] ThemeCosts = { 0, 150, 250, 350 };
        private static readonly Color[] ThemeColors =
        {
            new Color(.28f, .68f, 1f),
            new Color(1f, .43f, .22f),
            new Color(.3f, .82f, .52f),
            new Color(.72f, .48f, 1f)
        };

        private bool OwnsTheme(int index) => index == 0 || PlayerPrefs.GetInt("blockverse_theme_owned_" + index, 0) == 1;

        private void ShowShop()
        {
            Canvas canvas = GetCanvas(); if (canvas == null) return;
            if (menuOverlay != null) Destroy(menuOverlay);
            menuOverlay = CreateMenuOverlay(canvas, "BLOCK SHOP", $"COINS: {coins}  •  CHOOSE YOUR BLOCK STYLE");
            int equipped = PlayerPrefs.GetInt("blockverse_theme", 0);
            for (int i = 0; i < ThemeNames.Length; i++)
            {
                int index = i, col = i % 2, row = i / 2;
                bool owned = OwnsTheme(i);
                bool selected = equipped == i;
                string action = selected ? "EQUIPPED" : owned ? "EQUIP" : ThemeCosts[i] + " COINS";
                var go = new GameObject("Theme_" + i, typeof(RectTransform), typeof(Image), typeof(Button));
                go.transform.SetParent(menuOverlay.transform, false);
                var rect = go.GetComponent<RectTransform>(); rect.sizeDelta = new Vector2(310, 190);
                rect.anchoredPosition = new Vector2(col == 0 ? -170 : 170, 80 - row * 220);
                go.GetComponent<Image>().color = new Color(.1f, .16f, .25f, 1);
                var button = go.GetComponent<Button>(); button.interactable = !selected;
                button.onClick.AddListener(() => PurchaseOrEquipTheme(index));
                CreateOverlayText(go.transform, ThemeNames[index] + "\n" + action, 25, Vector2.zero, new Vector2(300, 180), ThemeColors[index]);
            }
            CreateOverlayButton(menuOverlay.transform, "BACK", new Vector2(0, -250), ShowMainMenu);
        }

        private void PurchaseOrEquipTheme(int index)
        {
            if (index < 0 || index >= ThemeNames.Length) return;
            if (!OwnsTheme(index))
            {
                if (coins < ThemeCosts[index]) { ShowMessage("NOT ENOUGH COINS", "Clear more lines and claim daily rewards."); return; }
                coins -= ThemeCosts[index];
                PlayerPrefs.SetInt("blockverse_theme_owned_" + index, 1);
                PlayerPrefs.SetInt("blockverse_coins", coins);
            }
            PlayerPrefs.SetInt("blockverse_theme", index);
            PlayerPrefs.Save();
            RefreshLabels();
            RefreshBoardVisuals();
            foreach (var piece in trayPieces)
                if (piece != null && piece.gameObject.activeSelf) piece.RefreshTheme();
            ShowShop();
        }

        private void ShowSettings()
        {
            Canvas canvas = GetCanvas(); if (canvas == null) return;
            if (menuOverlay != null) Destroy(menuOverlay);
            menuOverlay = CreateMenuOverlay(canvas, "SETTINGS", "MAKE THE GAME YOURS");
            CreateOverlayButton(menuOverlay.transform, gameAudio.Muted ? "SOUND: OFF" : "SOUND: ON", new Vector2(0, 80), () => { gameAudio.ToggleMute(); RefreshAudioButton(); ShowSettings(); });
            CreateOverlayButton(menuOverlay.transform, vibrationEnabled ? "VIBRATION: ON" : "VIBRATION: OFF", new Vector2(0, -35), () => { vibrationEnabled = !vibrationEnabled; PlayerPrefs.SetInt("blockverse_vibration", vibrationEnabled ? 1 : 0); PlayerPrefs.Save(); ShowSettings(); });
            CreateOverlayButton(menuOverlay.transform, "BACK", new Vector2(0, -160), ShowMainMenu);
        }

        private void ShowMessage(string heading, string message)
        {
            Canvas canvas = GetCanvas(); if (canvas == null) return;
            if (menuOverlay != null) Destroy(menuOverlay);
            menuOverlay = CreateMenuOverlay(canvas, heading, message);
            CreateOverlayButton(menuOverlay.transform, "CONTINUE", new Vector2(0, -100), ShowMainMenu);
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
            if (vibrationEnabled) Handheld.Vibrate();
            int centerX = x + piece.Shape.GetLength(1) / 2;
            int centerY = y + piece.Shape.GetLength(0) / 2;
            int affected = 0;
            switch (piece.Special)
            {
                case SpecialPieceType.Bomb: affected = board.Blast(centerX, centerY); gameAudio.PlayBomb(); SpawnBurst(centerX, centerY, new Color(1f, .35f, .18f)); break;
                case SpecialPieceType.Rainbow: affected = board.ClearRow(centerY); SpawnBurst(centerX, centerY, new Color(.75f, .4f, 1f)); break;
                case SpecialPieceType.Lightning: affected = board.ClearColumn(centerX); SpawnBurst(centerX, centerY, new Color(1f, .85f, .25f)); break;
            }

            int cleared = board.ClearCompletedLines();
            linesCleared += cleared;
            comboStreak = cleared > 0 ? comboStreak + 1 : 0;
            int comboBonus = cleared > 0 ? (comboStreak - 1) * 50 : 0;
            score += CountCells(piece.Shape) * 10 + cleared * config.BoardSize * 10 + affected * 5 + comboBonus;
            if (score > bestScore) { bestScore = score; PlayerPrefs.SetInt("blockverse_best_score", bestScore); }
            int earnedCoins = cleared > 0 ? cleared * 2 + Mathf.Max(0, comboStreak - 1) : 0;
            coins += earnedCoins;
            PlayerPrefs.SetInt("blockverse_coins", coins);
            PlayerPrefs.Save();
            TrackMissionProgress(CountCells(piece.Shape), cleared, earnedCoins);
            RefreshBoardVisuals();
            AnimateBoard();
            gameAudio.PlayPlace();
            if (cleared > 0) gameAudio.PlayClear();
            RefreshLabels();

            if (IsObjectiveComplete()) CompleteLevel();
            else if (config.MoveLimit > 0 && movesUsed >= config.MoveLimit) FailLevel("MOVE LIMIT REACHED");
            else if (hintLabel != null)
                hintLabel.text = (cleared > 0 ? $"NICE! {cleared} LINE(S) CLEARED" + (comboStreak > 1 ? $" • {comboStreak}× COMBO +{comboBonus}" : "") : "GOOD MOVE!") +
                    (piece.Special == SpecialPieceType.None ? "" : $" — {piece.Special.ToString().ToUpperInvariant()}");
            return true;
        }

        private void AnimateBoard()
        {
            if (boardRoot == null) return;
            foreach (Transform tile in boardRoot)
                if (tile.name.StartsWith("Cell_"))
                    StartCoroutine(PulseTile(tile));
        }

        private IEnumerator PulseTile(Transform tile)
        {
            if (tile == null) yield break;
            Vector3 start = tile.localScale;
            float elapsed = 0f, duration = .12f;
            while (elapsed < duration && tile != null)
            {
                elapsed += Time.unscaledDeltaTime;
                float pulse = 1f + Mathf.Sin(Mathf.Clamp01(elapsed / duration) * Mathf.PI) * .09f;
                tile.localScale = start * pulse;
                yield return null;
            }
            if (tile != null) tile.localScale = start;
        }

        private void SpawnBurst(int centerX, int centerY, Color color)
        {
            if (boardRoot == null) return;
            var grid = boardRoot.GetComponent<GridLayoutGroup>();
            float pitchX = grid.cellSize.x + grid.spacing.x, pitchY = grid.cellSize.y + grid.spacing.y;
            Vector2 position = new Vector2(boardRoot.rect.xMin + (centerX + .5f) * pitchX,
                boardRoot.rect.yMax - (centerY + .5f) * pitchY);
            for (int i = 0; i < 8; i++)
            {
                var particle = new GameObject("BlockBurst", typeof(RectTransform), typeof(Image), typeof(CanvasGroup));
                // Keep effects outside the GridLayoutGroup. Board refresh expects
                // exactly one child per cell; particles inside boardRoot corrupt that mapping.
                Transform effectsParent = boardRoot.parent != null ? boardRoot.parent : boardRoot;
                particle.transform.SetParent(effectsParent, false);
                var rect = particle.GetComponent<RectTransform>();
                rect.sizeDelta = new Vector2(14, 14);
                if (effectsParent == boardRoot)
                    rect.anchoredPosition = position;
                else
                    rect.position = boardRoot.TransformPoint(position);
                particle.GetComponent<Image>().color = color;
                StartCoroutine(AnimateParticle(rect, particle.GetComponent<CanvasGroup>(), i * Mathf.PI / 4f));
            }
        }

        private IEnumerator AnimateParticle(RectTransform rect, CanvasGroup group, float angle)
        {
            Vector2 start = rect.anchoredPosition;
            float elapsed = 0f, duration = .38f;
            while (elapsed < duration && rect != null)
            {
                elapsed += Time.unscaledDeltaTime;
                float t = Mathf.Clamp01(elapsed / duration);
                rect.anchoredPosition = start + new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * (85f * t);
                rect.localScale = Vector3.one * (1f - .65f * t);
                group.alpha = 1f - t;
                yield return null;
            }
            if (rect != null) Destroy(rect.gameObject);
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
                case LevelGoal.LimitedMoves: return $"LINES {linesCleared}/{config.Target} • MOVES {movesUsed}/{config.MoveLimit}";
                case LevelGoal.Boss: return $"BOSS OBSTACLES {board.CountObstacles()} LEFT";
                default: return config.Goal.ToString().ToUpperInvariant();
            }
        }

        private void CompleteLevel()
        {
            if (levelFinished) return;
            levelFinished = true;
            gameAudio.PlayWin();
            int reward = 20 + level * 2;
            coins += reward;
            int unlocked = Mathf.Max(PlayerPrefs.GetInt("blockverse_level", 1), level + 1);
            PlayerPrefs.SetInt("blockverse_level", unlocked);
            PlayerPrefs.SetInt("blockverse_coins", coins);
            PlayerPrefs.SetInt($"blockverse_level_{level}_stars", 3);
            PlayerPrefs.SetInt("blockverse_levels_won", PlayerPrefs.GetInt("blockverse_levels_won", 0) + 1);
            PlayerPrefs.Save();
            CheckAchievements();
            ShowResult(true, "LEVEL COMPLETE!", $"You cleared level {level}.\n+{reward} BONUS COINS\nScore: {score:N0}");
        }

        private void FailLevel(string reason)
        {
            if (levelFinished) return;
            levelFinished = true;
            gameAudio.PlayFail();
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
            overlayRect.anchorMin = Vector2.zero; overlayRect.anchorMax = Vector2.one;
            overlayRect.offsetMin = Vector2.zero; overlayRect.offsetMax = Vector2.zero;
            resultOverlay.GetComponent<Image>().color = new Color(.025f, .04f, .08f, .88f);
            var card = new GameObject("ResultCard", typeof(RectTransform), typeof(Image));
            card.transform.SetParent(resultOverlay.transform, false);
            var cardRect = card.GetComponent<RectTransform>();
            cardRect.anchorMin = new Vector2(.1f, .34f); cardRect.anchorMax = new Vector2(.9f, .66f);
            cardRect.offsetMin = Vector2.zero; cardRect.offsetMax = Vector2.zero;
            card.GetComponent<Image>().color = new Color(.09f, .13f, .21f, 1);
            CreateOverlayText(card.transform, heading, 48, new Vector2(0, 145), new Vector2(760, 90), new Color(1, .82f, .35f));
            CreateOverlayText(card.transform, message, 28, new Vector2(0, 25), new Vector2(760, 150), Color.white);
            CreateOverlayButton(card.transform, won ? "NEXT LEVEL" : "RETRY", new Vector2(0, -115), won ? (UnityEngine.Events.UnityAction)GoToNextLevel : StartLevel);
            if (!won && !reviveUsed && coins >= 50)
                CreateOverlayButton(card.transform, "REVIVE • 50 COINS", new Vector2(0, -215), ReviveLevel);
        }

        private void CreateOverlayText(Transform parent, string value, int size, Vector2 position, Vector2 dimensions, Color color)
        {
            var go = new GameObject("ResultText", typeof(RectTransform), typeof(Text));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>(); rect.sizeDelta = dimensions; rect.anchoredPosition = position;
            var text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("Arial.ttf"); text.fontSize = size;
            text.fontStyle = FontStyle.Bold; text.alignment = TextAnchor.MiddleCenter; text.color = color; text.text = value;
        }

        private void CreateOverlayButton(Transform parent, string label, Vector2 position, UnityEngine.Events.UnityAction action)
        {
            var go = new GameObject("ResultButton", typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>(); rect.sizeDelta = new Vector2(440, 90); rect.anchoredPosition = position;
            go.GetComponent<Image>().color = new Color(.2f, .53f, .95f);
            go.GetComponent<Button>().onClick.AddListener(action);
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
                // Only actual grid cells belong to the board model. UI effects or
                // decorative children must never shift the model-to-view indexing.
                if (!child.name.StartsWith("Cell_")) continue;
                if (index >= board.Width * board.Height) break;
                int x = index % board.Width, y = index / board.Width;
                var image = child.GetComponent<Image>();
                if (image == null) { index++; continue; }
                switch (board.GetCell(x, y))
                {
                    case CellType.Normal: image.color = ThemeColors[Mathf.Clamp(PlayerPrefs.GetInt("blockverse_theme", 0), 0, ThemeColors.Length - 1)]; break;
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
            if (goalLabel != null) goalLabel.text = $"LEVEL {level} • {ObjectiveText()} • BEST {bestScore:N0} • COINS {coins} • COMBO {comboStreak}×";
        }
    }
}