// Idem Procedural Ambient Audio Synthesizer (100% Offline Web Audio API)
(function() {
  let ctx = null;
  let activeSource = null;
  let gainNode = null;
  let currentType = null;
  let isPlaying = false;
  let currentVolume = 0.5;

  function initAudioContext() {
    if (!ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) {
        ctx = new AudioCtx();
      }
    }
    if (ctx && ctx.state === 'suspended') {
      ctx.resume();
    }
  }

  function createNoiseBuffer(duration, type) {
    if (!ctx) return null;
    const bufferSize = ctx.sampleRate * duration;
    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);

    if (type === 'white') {
      for (let i = 0; i < bufferSize; i++) {
        data[i] = Math.random() * 2 - 1;
      }
    } else if (type === 'brown') {
      let lastOut = 0.0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        lastOut = (lastOut + (0.02 * white)) / 1.02;
        data[i] = lastOut * 3.5; // Gain compensation
      }
    } else if (type === 'pink') {
      let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        data[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11;
        b6 = white * 0.115926;
      }
    }
    return buffer;
  }

  function playNoise(type, volume) {
    stop();
    initAudioContext();
    if (!ctx) return;

    gainNode = ctx.createGain();
    gainNode.gain.setValueAtTime(0.01, ctx.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(Math.max(0.01, volume), ctx.currentTime + 1.2);
    gainNode.connect(ctx.destination);

    if (type === 'binaural40') {
      // 40Hz Gamma Beat: 200Hz Left, 240Hz Right
      const merger = ctx.createChannelMerger(2);
      
      const oscL = ctx.createOscillator();
      oscL.type = 'sine';
      oscL.frequency.setValueAtTime(200, ctx.currentTime);
      
      const oscR = ctx.createOscillator();
      oscR.type = 'sine';
      oscR.frequency.setValueAtTime(240, ctx.currentTime);

      oscL.connect(merger, 0, 0); // Left channel
      oscR.connect(merger, 0, 1); // Right channel
      merger.connect(gainNode);

      oscL.start();
      oscR.start();

      activeSource = {
        stop: function() {
          try {
            oscL.stop();
            oscR.stop();
          } catch(e) {}
        }
      };
    } else if (type === 'rain') {
      // Procedural rain: Pink noise + Bandpass + random drops
      const buffer = createNoiseBuffer(4.0, 'pink');
      const noiseSource = ctx.createBufferSource();
      noiseSource.buffer = buffer;
      noiseSource.loop = true;

      const filter = ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1400, ctx.currentTime);

      noiseSource.connect(filter);
      filter.connect(gainNode);
      noiseSource.start();

      activeSource = noiseSource;
    } else {
      // Brown, Pink, or White noise
      const buffer = createNoiseBuffer(4.0, type);
      const noiseSource = ctx.createBufferSource();
      noiseSource.buffer = buffer;
      noiseSource.loop = true;

      noiseSource.connect(gainNode);
      noiseSource.start();

      activeSource = noiseSource;
    }

    currentType = type;
    isPlaying = true;
    currentVolume = volume;
  }

  function setVolume(volume) {
    currentVolume = volume;
    if (gainNode && ctx) {
      gainNode.gain.setValueAtTime(Math.max(0.001, volume), ctx.currentTime);
    }
  }

  function stop() {
    if (activeSource) {
      try {
        activeSource.stop();
      } catch (e) {}
      activeSource = null;
    }
    if (gainNode && ctx) {
      try {
        gainNode.disconnect();
      } catch(e) {}
      gainNode = null;
    }
    isPlaying = false;
    currentType = null;
  }

  window.IdemAudio = {
    play: playNoise,
    setVolume: setVolume,
    stop: stop,
    isPlaying: function() { return isPlaying; },
    getCurrentType: function() { return currentType; },
    getVolume: function() { return currentVolume; }
  };
})();
