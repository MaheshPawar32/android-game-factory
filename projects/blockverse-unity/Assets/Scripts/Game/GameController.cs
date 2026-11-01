using UnityEngine;
using UnityEngine.UI;
using TMPro;

namespace Blockverse
{
    public sealed class GameController : MonoBehaviour
    {
        [SerializeField] private RectTransform boardRoot;
        [SerializeField] private TMP_Text scoreLabel;
        [SerializeField] private TMP_Text goalLabel;
        [SerializeField] private Button restartButton;

        private BoardModel board;
        private int score;
        private int level = 1;
        private LevelConfig config;

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
            RefreshLabels();
            BuildBoard();
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
            grid.cellSize = new Vector2(62, 62);

            for (int i = 0; i < config.BoardSize * config.BoardSize; i++)
            {
                var tile = new GameObject("Cell", typeof(RectTransform), typeof(Image));
                tile.transform.SetParent(boardRoot, false);
                tile.GetComponent<Image>().color = new Color(0.13f, 0.17f, 0.24f, 1f);
            }
        }

        public void AddScore(int amount)
        {
            score += Mathf.Max(0, amount);
            RefreshLabels();
        }

        private void RefreshLabels()
        {
            if (scoreLabel != null) scoreLabel.text = $"SCORE  {score:N0}";
            if (goalLabel != null) goalLabel.text = $"LEVEL {level}  •  {config?.Goal.ToString().ToUpperInvariant()}";
        }
    }
}
