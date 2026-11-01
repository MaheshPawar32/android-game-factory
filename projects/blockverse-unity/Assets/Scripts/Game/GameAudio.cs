using UnityEngine;

namespace Blockverse
{
    [RequireComponent(typeof(AudioSource))]
    public sealed class GameAudio : MonoBehaviour
    {
        private AudioSource source;
        private bool muted;
        private AudioClip placeClip, clearClip, bombClip, winClip, failClip;

        public bool Muted => muted;

        private void Awake()
        {
            source = GetComponent<AudioSource>();
            source.playOnAwake = false;
            source.loop = false;
            muted = PlayerPrefs.GetInt("blockverse_muted", 0) == 1;
            placeClip = Tone("Place", 520f, .075f);
            clearClip = Tone("Clear", 760f, .16f);
            bombClip = Tone("Bomb", 115f, .24f);
            winClip = Tone("Win", 880f, .32f);
            failClip = Tone("Fail", 210f, .24f);
        }

        public void ToggleMute()
        {
            muted = !muted;
            PlayerPrefs.SetInt("blockverse_muted", muted ? 1 : 0);
            PlayerPrefs.Save();
        }

        public void PlayPlace() => Play(placeClip);
        public void PlayClear() => Play(clearClip);
        public void PlayBomb() => Play(bombClip);
        public void PlayWin() => Play(winClip);
        public void PlayFail() => Play(failClip);

        private void Play(AudioClip clip)
        {
            if (!muted && source != null && clip != null) source.PlayOneShot(clip, .65f);
        }

        private AudioClip Tone(string clipName, float frequency, float duration)
        {
            const int sampleRate = 22050;
            int count = Mathf.CeilToInt(sampleRate * duration);
            var samples = new float[count];
            for (int i = 0; i < count; i++)
            {
                float t = i / (float)sampleRate;
                float fade = Mathf.Clamp01((count - i) / (sampleRate * .025f));
                samples[i] = Mathf.Sin(2f * Mathf.PI * frequency * t) * fade * .22f;
            }
            var clip = AudioClip.Create(clipName, count, 1, sampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }
    }
}