using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace Blockverse
{
    public sealed class PieceDragView : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        public bool[,] Shape { get; private set; }

        private GameController controller;
        private RectTransform trayParent;
        private Transform originalParent;
        private Vector2 originalPosition;
        private Canvas canvas;
        private CanvasGroup canvasGroup;

        public void Initialize(GameController owner, bool[,] shape, RectTransform tray)
        {
            controller = owner;
            Shape = shape;
            trayParent = tray;
            canvas = GetComponentInParent<Canvas>();
            canvasGroup = gameObject.AddComponent<CanvasGroup>();
            BuildVisual();
        }

        private void BuildVisual()
        {
            int rows = Shape.GetLength(0);
            int columns = Shape.GetLength(1);
            var rect = (RectTransform)transform;
            rect.sizeDelta = new Vector2(150, 130);
            float size = Mathf.Min(30f, 88f / Mathf.Max(rows, columns));
            float width = columns * size + (columns - 1) * 4f;
            float height = rows * size + (rows - 1) * 4f;

            for (int y = 0; y < rows; y++)
            for (int x = 0; x < columns; x++)
            {
                if (!Shape[y, x]) continue;
                var cell = new GameObject("PieceCell", typeof(RectTransform), typeof(Image));
                cell.transform.SetParent(transform, false);
                var cellRect = cell.GetComponent<RectTransform>();
                cellRect.sizeDelta = new Vector2(size, size);
                cellRect.anchoredPosition = new Vector2(-width / 2f + size / 2f + x * (size + 4f),
                    height / 2f - size / 2f - y * (size + 4f));
                var image = cell.GetComponent<Image>();
                image.color = new Color(0.28f, 0.68f, 1f);
                image.raycastTarget = false;
            }
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            if (!enabled || canvas == null) return;
            originalParent = transform.parent;
            originalPosition = ((RectTransform)transform).anchoredPosition;
            transform.SetParent(canvas.transform, true);
            canvasGroup.blocksRaycasts = false;
            canvasGroup.alpha = 0.88f;
            transform.position = eventData.position;
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (enabled) transform.position = eventData.position;
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            if (originalParent == null) return;
            bool placed = controller.TryDrop(Shape, eventData.position, eventData.pressEventCamera);
            transform.SetParent(originalParent, false);
            ((RectTransform)transform).anchoredPosition = originalPosition;
            canvasGroup.blocksRaycasts = true;
            canvasGroup.alpha = 1f;
            if (placed) controller.ConsumePiece(this);
        }
    }
}
