/* ============================================
   LEBRONIFY WEB APP - Full Music Player Engine
   SVG icons throughout - no emojis
   ============================================ */

(function() {
'use strict';

// -------------------------------------------
// SVG Icon Library (matching SF Symbols)
// -------------------------------------------
const ICONS = {
    play: '<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>',
    pause: '<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>',
    prev: '<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M6 6h2v12H6zm3.5 6l8.5 6V6z"/></svg>',
    next: '<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"/></svg>',
    shuffle: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M10.59 9.17L5.41 4 4 5.41l5.17 5.17 1.42-1.41zM14.5 4l2.04 2.04L4 18.59 5.41 20 17.96 7.46 20 9.5V4h-5.5zm.33 9.41l-1.41 1.41 3.13 3.13L14.5 20H20v-5.5l-2.04 2.04-3.13-3.13z"/></svg>',
    repeat: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M7 7h10v3l4-4-4-4v3H5v6h2V7zm10 10H7v-3l-4 4 4 4v-3h12v-6h-2v4z"/></svg>',
    repeatOne: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M7 7h10v3l4-4-4-4v3H5v6h2V7zm10 10H7v-3l-4 4 4 4v-3h12v-6h-2v4zm-4-2V9h-1l-2 1v1h1.5v4H13z"/></svg>',
    starEmpty: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>',
    starFilled: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>',
    chevronRight: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg>',
    musicNote: '<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55C7.79 13 6 14.79 6 17s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>',
    ellipsis: '<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="19" cy="12" r="2"/></svg>',
    sparkles: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M7.5 5.6L10 7 8.6 4.5 10 2 7.5 3.4 5 2l1.4 2.5L5 7zm12 9.8L17 14l1.4 2.5L17 19l2.5-1.4L22 19l-1.4-2.5L22 14zM22 2l-2.5 1.4L17 2l1.4 2.5L17 7l2.5-1.4L22 7l-1.4-2.5zm-7.63 5.29a.996.996 0 00-1.41 0L1.29 18.96a.996.996 0 000 1.41l2.34 2.34c.39.39 1.02.39 1.41 0L16.7 11.05a.996.996 0 000-1.41l-2.33-2.35z"/></svg>',
    trash: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>',
};

function icon(name, size) {
    let svg = ICONS[name] || '';
    if (size) {
        svg = svg.replace(/width="\d+"/, `width="${size}"`).replace(/height="\d+"/, `height="${size}"`);
    }
    return svg;
}

// -------------------------------------------
// Song Database
// -------------------------------------------
const SONGS = [
    { id: 1, title: "Ain't It Bron", artist: "hen.bouselog", image: "ain't_it_bron.png", audio: "Ain't It Bron - hen.bouselog.mp3" },
    { id: 2, title: "All LeBron Things", artist: "jeremytache", image: "all_lebron_things.png", audio: "All LeBron Things - jeremytache.mp3" },
    { id: 3, title: "Bring Me Back To Bron", artist: "LeBron Fan", image: "bring_me_back_to_bron.png", audio: "Bring Me Back To Bron.mp3" },
    { id: 4, title: "Bron Royalty", artist: "ilyaugust", image: "bron_royalty.png", audio: "Bron Royalty - ilyaugust.mp3" },
    { id: 5, title: "Bronpeii", artist: "ilyaugust", image: "bronpeii.png", audio: "Bronpeii - ilyaugust.mp3" },
    { id: 6, title: "Brons Not Brongedies", artist: "ilyaugust", image: "brons_not_brongedies.png", audio: "Brons Not Brongedies - ilyaugust.mp3" },
    { id: 7, title: "Brontastic", artist: "ilyaugust", image: "brontastic.png", audio: "Brontastic - ilyaugust.mp3" },
    { id: 8, title: "Catch a LeNade For You", artist: "ilyaugust", image: "catch_a_lenade_for_you.png", audio: "Catch a LeNade For You - ilyaugust.mp3" },
    { id: 9, title: "Dear LeBron", artist: "sdotreidy", image: "dear_lebron.png", audio: "Dear LeBron - sdotreidy.mp3" },
    { id: 10, title: "Dunk With a Smile", artist: "LeBron Fan", image: "dunk_with_a_smile.png", audio: "Dunk With a Smile.mp3" },
    { id: 11, title: "He Is LeBron James", artist: "My Way", image: "he_is_lebron_james.png", audio: "He Is Lebron James - My Way.mp3" },
    { id: 12, title: "He Is The King", artist: "LeBron Fan", image: "he_is_the_king.png", audio: "He is The King.mp3" },
    { id: 13, title: "I'm Like That's Bron", artist: "ilyaugust", image: "i'm_like_that's_bron.png", audio: "I'm Like That's Bron - ilyaugust.mp3" },
    { id: 14, title: "I Believe in LeBron", artist: "imakeparodyzz", image: "i_believe_in_lebron.png", audio: "I Believe in LeBron - imakeparodyzz.mp3" },
    { id: 15, title: "I Glazed LeBron (And I Liked It)", artist: "timringling", image: "i_glazed_lebron_(and_i_liked_it).png", audio: "I Glazed LeBron (And I Liked It) - timringling.mp3" },
    { id: 16, title: "In The Bron", artist: "ilyaugust", image: "in_the_bron.png", audio: "In The Bron - ilyaugust.mp3" },
    { id: 17, title: "La Bron Bron Land", artist: "House of Highlights", image: "la_bron_bron_land.png", audio: "La Bron Bron Land - House of Highlights.mp3" },
    { id: 18, title: "Le Bronba", artist: "enrique_l_garibay", image: "le_bronba.png", audio: "Le Bronba - enrique_l_garibay.mp3" },
    { id: 19, title: "LeAfrica", artist: "standleyjohnsonmusic", image: "leafrica.png", audio: "LeAfrica - standleyjohnsonmusic.mp3" },
    { id: 20, title: "LeAll of Me", artist: "musicbykidb", image: "leall_of_me.png", audio: "LeAll of Me - musicbykidb.mp3" },
    { id: 21, title: "LeBron, LeBron, LeBron", artist: "LeBron Fan", image: "lebron,_lebron,_lebron.png", audio: "LeBron, LeBron, LeBron.mp3" },
    { id: 22, title: "LeBron Has Taken a Toll", artist: "ilyaugust", image: "lebron_has_taken_a_toll.png", audio: "LeBron Has Taken a Toll - ilyaugust.mp3" },
    { id: 23, title: "LeBron That I Used to Know", artist: "LeBron Fan", image: "lebron_that_i_used_to_know.png", audio: "LeBron That I Used to Know.mp3" },
    { id: 24, title: "LeBronifornia Girls", artist: "izzydrip", image: "lebronifornia_girls.png", audio: "LeBronifornia Girls - izzydrip.mp3" },
    { id: 25, title: "LeBrons Wide Open", artist: "timringling", image: "lebrons_wide_open.png", audio: "LeBrons Wide Open - timringling.mp3" },
    { id: 26, title: "LeCurious James", artist: "leiheart.radio.station", image: "lecurious_james.png", audio: "LeCurious James - leiheart.radio.station.mp3" },
    { id: 27, title: "LeEarned It", artist: "kai.so", image: "leearned_it.png", audio: "LeEarned It - kai.so.mp3" },
    { id: 28, title: "LeGolden Hour", artist: "ilyaugust", image: "legolden_hour.png", audio: "LeGolden Hour - ilyaugust.mp3" },
    { id: 29, title: "LeHips Don't Lie", artist: "ant.jr06", image: "lehips_don't_lie.png", audio: "LeHips Don't Lie - ant.jr06.mp3" },
    { id: 30, title: "LeLove Yourself", artist: "musicbykidb", image: "lelove_yourself.png", audio: "LeLove Yourself - musicbykidb.mp3" },
    { id: 31, title: "LeStiches", artist: "ilyaugust", image: "lestiches.png", audio: "LeStiches - ilyaugust.mp3" },
    { id: 32, title: "Let LeBron Know", artist: "LeBron Fan", image: "let_lebron_know.png", audio: "Let LeBron Know.mp3" },
    { id: 33, title: "Life is a LeHighway", artist: "jeppreyjung", image: "life_is_a_lehighway.png", audio: "Life is a LeHighway - jeppreyjung.mp3" },
    { id: 34, title: "Man On The Lakers", artist: "Talented Blake", image: "man_on_the_lakers.png", audio: "Man On The Lakers - Talented Blake.mp3" },
    { id: 35, title: "Marry Bron", artist: "ilyaugust", image: "marry_bron.png", audio: "Marry Bron - ilyaugust.mp3" },
    { id: 36, title: "No Bron", artist: "ilyaugust", image: "no_bron.png", audio: "No Bron - ilyaugust.mp3" },
    { id: 37, title: "Not Like Bron", artist: "vonpierreofficial", image: "not_like_bron.png", audio: "Not Like Bron - vonpierreofficial.mp3" },
    { id: 38, title: "Oh Mr LeBron", artist: "LeBron Fan", image: "oh_mr_lebron.png", audio: "Oh Mr LeBron.mp3" },
    { id: 39, title: "Romantic Bronicide", artist: "ilyaugust", image: "romantic_bronicide.png", audio: "Romantic Bronicide - ilyaugust.mp3" },
    { id: 40, title: "Shut Up and Dance With Bron", artist: "ilyaugust", image: "shut_up_and_dance_with_bron.png", audio: "Shut Up and Dance With Bron - ilyaugust.mp3" },
    { id: 41, title: "Still Glazing You", artist: "musicbykidb", image: "still_glazing_you.png", audio: "Still Glazing You - musicbykidb.mp3" },
    { id: 42, title: "Sweet LeScape", artist: "ilyaugust", image: "sweet_lescape.png", audio: "Sweet LeScape - ilyaugust.mp3" },
    { id: 43, title: "TACO TUESDAYYYYY", artist: "LeBron James", image: "taco_tuesday.jpg", audio: "Taco Tuesday.mp3" },
    { id: 44, title: "That's Bron", artist: "JJ Darrow", image: "that's_bron.png", audio: "That's Bron - JJ Darrow.mp3" },
    { id: 45, title: "That's What Makes Bron Beautiful", artist: "ilyaugust", image: "that's_what_makes_bron_beautiful.png", audio: "That's What Makes Bron Beautiful - ilyaugust.mp3" },
    { id: 46, title: "Thinkin Bout LeBron", artist: "ilyaugust", image: "thinkin_bout_lebron.png", audio: "Thinkin Bout LeBron - ilyaugust.mp3" },
    { id: 47, title: "This is The Bron", artist: "fanoftatum0", image: "this_is_the_bron.png", audio: "This is The Bron - fanoftatum0.mp3" },
    { id: 48, title: "Towards The Bron", artist: "ilyaugust", image: "towards_the_bron.png", audio: "Towards The Bron - ilyaugust.mp3" },
    { id: 49, title: "You Are My Sunshine", artist: "LeBron Fan", image: "you_are_my_sunshine.png", audio: "You Are My Sunshine.mp3" },
];

const AD_DATA = [
    { title: "THE BROW KNOWS", img: "images/ui/ad_pose1.jpg", msg: "Need more hang time? Try AD's secret workout routine!", dismiss: "Trade AD to Dallas" },
    { title: "AD APPROVED", img: "images/ui/ad_pose2.jpg", msg: "Anthony Davis says: 'These parodies hit harder than my blocks!'", dismiss: "Send AD to the Bench" },
    { title: "BROW DOWN", img: "images/ui/anthony_davis_default.jpg", msg: "The Brow demands you listen to at least 3 more songs!", dismiss: "AD Fouled Out - Skip" },
    { title: "AD BREAK", img: "images/ui/ad_pose1.jpg", msg: "This AD break is brought to you by Anthony Davis's eyebrow groomer.", dismiss: "Put AD on Injured Reserve" },
    { title: "TRADE OFFER", img: "images/ui/ad_pose2.jpg", msg: "You receive: more parodies. AD receives: your undivided attention.", dismiss: "Decline Trade" },
    { title: "THE UNIBROW SPEAKS", img: "images/ui/anthony_davis_default.jpg", msg: "AD's eyebrow has its own gravitational pull. And opinions.", dismiss: "Wax the Brow" },
    { title: "STREET CLOTHES ALERT", img: "images/ui/ad_pose1.jpg", msg: "AD is sitting courtside in a designer suit again. Classic.", dismiss: "Get AD a Jersey" },
    { title: "GLASS MAN GLAZING", img: "images/ui/ad_pose2.jpg", msg: "Anthony Davis is OUT tonight with a sore playlist finger.", dismiss: "Day-to-Day" },
];

const TACO_ADS = [
    { title: "TACO TUESDAYYYYY", img: "images/ui/lebron_default.png", msg: "It's Taco Tuesday! LeBron demands you eat tacos while listening!", dismiss: "Pass the Hot Sauce" },
    { title: "TACO TIME", img: "images/ui/lebron_default.png", msg: "LeBron's kitchen is open. Tacos are mandatory on Tuesdays.", dismiss: "Order More Tacos" },
];

// -------------------------------------------
// State
// -------------------------------------------
const audio = new Audio();
let state = {
    queue: [],
    queueIndex: -1,
    originalOrder: [],
    shuffle: false,
    repeat: 'off',
    playing: false,
    currentView: 'home',
    previousView: 'home',
    songData: {},
    playlists: [],
    songsPlayed: 0,
};

// -------------------------------------------
// Persistence
// -------------------------------------------
function loadState() {
    try {
        const saved = JSON.parse(localStorage.getItem('lebronify_state') || '{}');
        if (saved.songData) state.songData = saved.songData;
        if (saved.playlists) state.playlists = saved.playlists;
    } catch(e) {}
}

function saveState() {
    localStorage.setItem('lebronify_state', JSON.stringify({
        songData: state.songData,
        playlists: state.playlists,
    }));
}

function getSongData(id) {
    if (!state.songData[id]) state.songData[id] = { playCount: 0, isFavorite: false, lastPlayed: null };
    return state.songData[id];
}

// -------------------------------------------
// Helpers
// -------------------------------------------
function $(sel) { return document.querySelector(sel); }
function $$(sel) { return document.querySelectorAll(sel); }
function imgPath(img) { return `images/albums/${img}`; }
function audioPath(file) { return `songs/${file}`; }
function formatTime(s) {
    if (isNaN(s) || !isFinite(s)) return '0:00';
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${m}:${sec.toString().padStart(2, '0')}`;
}
function shuffleArray(arr) {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
    return a;
}
function getSongOfDay() {
    // 60% chance on Tuesdays to feature Taco Tuesday song
    if (isTacoTuesday() && Math.random() < 0.6) {
        return SONGS.find(s => s.id === 43) || SONGS[0];
    }
    const day = Math.floor(Date.now() / 86400000);
    return SONGS[day % SONGS.length];
}
function getTopSongs() {
    return SONGS.filter(s => getSongData(s.id).playCount > 0)
        .sort((a, b) => getSongData(b.id).playCount - getSongData(a.id).playCount);
}
function getRecentSongs() {
    return SONGS.filter(s => getSongData(s.id).lastPlayed)
        .sort((a, b) => getSongData(b.id).lastPlayed - getSongData(a.id).lastPlayed)
        .slice(0, 20);
}
function getFavorites() { return SONGS.filter(s => getSongData(s.id).isFavorite); }
function isTacoTuesday() { return new Date().getDay() === 2; }

// -------------------------------------------
// Dynamic Color Extraction (like iOS dynamic gradient)
// -------------------------------------------
const colorCanvas = document.createElement('canvas');
const colorCtx = colorCanvas.getContext('2d', { willReadFrequently: true });
colorCanvas.width = 50;
colorCanvas.height = 50;
let currentGradientColor = 'rgba(255,215,0,0.25)';

function extractDominantColor(imgSrc, callback) {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
        colorCtx.drawImage(img, 0, 0, 50, 50);
        try {
            const data = colorCtx.getImageData(0, 0, 50, 50).data;
            let r = 0, g = 0, b = 0, count = 0;
            // Sample every 4th pixel from center region for more accurate color
            for (let y = 10; y < 40; y += 2) {
                for (let x = 10; x < 40; x += 2) {
                    const i = (y * 50 + x) * 4;
                    // Skip very dark and very bright pixels
                    const brightness = data[i] + data[i+1] + data[i+2];
                    if (brightness > 60 && brightness < 700) {
                        r += data[i]; g += data[i+1]; b += data[i+2]; count++;
                    }
                }
            }
            if (count > 0) {
                r = Math.round(r / count);
                g = Math.round(g / count);
                b = Math.round(b / count);
                callback(`rgba(${r},${g},${b},0.25)`);
            } else {
                callback('rgba(255,215,0,0.25)');
            }
        } catch(e) {
            callback('rgba(255,215,0,0.25)');
        }
    };
    img.onerror = () => callback('rgba(255,215,0,0.25)');
    img.src = imgSrc;
}

function updatePlayerGradient(color) {
    currentGradientColor = color;
    const scroll = $('.player-view-scroll');
    if (scroll) {
        scroll.style.background = `linear-gradient(180deg, ${color} 0%, var(--bg) 40%)`;
    }
}

// -------------------------------------------
// Chalk Toss Animation
// -------------------------------------------
let chalkContainer = null;
let chalkTimeout = null;

function triggerChalkToss() {
    // Remove previous chalk toss
    if (chalkContainer) { chalkContainer.remove(); chalkContainer = null; }
    if (chalkTimeout) clearTimeout(chalkTimeout);

    chalkContainer = document.createElement('div');
    chalkContainer.className = 'chalk-toss-overlay';

    // Create 20 chalk particles
    for (let i = 0; i < 20; i++) {
        const dot = document.createElement('div');
        dot.className = 'chalk-dot';
        const size = 2 + Math.random() * 5;
        const left = 15 + Math.random() * 70;
        const delay = Math.random() * 0.8;
        const drift = -30 + Math.random() * 60;
        dot.style.cssText = `
            width: ${size}px; height: ${size}px;
            left: ${left}%; bottom: 30%;
            animation-delay: ${delay}s;
            --drift: ${drift}px;
        `;
        chalkContainer.appendChild(dot);
    }

    document.body.appendChild(chalkContainer);

    // Remove after animation completes
    chalkTimeout = setTimeout(() => {
        if (chalkContainer) { chalkContainer.remove(); chalkContainer = null; }
    }, 3000);
}

// -------------------------------------------
// Audio Playback
// -------------------------------------------
let _isSkipping = false; // Guard against double-fire like iOS

function playSong(song, fromQueue) {
    if (!fromQueue) {
        state.queue = [song];
        state.queueIndex = 0;
    }
    audio.src = audioPath(song.audio);
    audio.play().catch(() => {});
    state.playing = true;
    _isSkipping = false;

    if (audio._trackTimeout) clearTimeout(audio._trackTimeout);
    const trackPlay = setTimeout(() => {
        const d = getSongData(song.id);
        d.playCount++;
        d.lastPlayed = Date.now();
        saveState();
        state.songsPlayed++;
        maybeShowAd();
        renderAll();
    }, 10000);
    audio._trackTimeout = trackPlay;

    // Extract dominant color for dynamic gradient
    extractDominantColor(imgPath(song.image), (color) => {
        updatePlayerGradient(color);
    });

    // Trigger chalk toss animation
    triggerChalkToss();

    updateUI();
    updateMediaSession(song);
}

function playQueue(songs, startIndex) {
    state.originalOrder = [...songs];
    state.queue = state.shuffle ? shuffleArray(songs) : [...songs];
    if (state.shuffle && startIndex >= 0) {
        const song = songs[startIndex];
        const idx = state.queue.findIndex(s => s.id === song.id);
        if (idx > 0) { state.queue.splice(idx, 1); state.queue.unshift(song); }
        state.queueIndex = 0;
    } else {
        state.queueIndex = state.shuffle ? 0 : startIndex;
    }
    playSong(state.queue[state.queueIndex], true);
}

function togglePlay() {
    if (state.queue.length === 0) return;
    if (audio.paused) { audio.play().catch(() => {}); state.playing = true; }
    else { audio.pause(); state.playing = false; }
    updateUI();
}

function nextSong() {
    if (state.queue.length === 0) return;
    if (_isSkipping) return; // Guard against double-fire
    _isSkipping = true;
    if (state.repeat === 'one') { audio.currentTime = 0; audio.play(); _isSkipping = false; return; }
    state.queueIndex++;
    if (state.queueIndex >= state.queue.length) {
        if (state.repeat === 'all') state.queueIndex = 0;
        else { state.playing = false; _isSkipping = false; updateUI(); return; }
    }
    playSong(state.queue[state.queueIndex], true);
}

function prevSong() {
    if (state.queue.length === 0) return;
    if (audio.currentTime > 3) { audio.currentTime = 0; return; }
    state.queueIndex--;
    if (state.queueIndex < 0) state.queueIndex = state.repeat === 'all' ? state.queue.length - 1 : 0;
    playSong(state.queue[state.queueIndex], true);
}

function toggleShuffle() {
    state.shuffle = !state.shuffle;
    if (state.queue.length > 0) {
        const current = state.queue[state.queueIndex];
        if (state.shuffle) {
            state.queue = shuffleArray(state.queue);
            const idx = state.queue.findIndex(s => s.id === current.id);
            if (idx > 0) { state.queue.splice(idx, 1); state.queue.unshift(current); }
            state.queueIndex = 0;
        } else {
            state.queue = [...state.originalOrder];
            state.queueIndex = state.queue.findIndex(s => s.id === current.id);
            if (state.queueIndex < 0) state.queueIndex = 0;
        }
    }
    updateUI();
}

function toggleRepeat() {
    const modes = ['off', 'all', 'one'];
    state.repeat = modes[(modes.indexOf(state.repeat) + 1) % 3];
    updateUI();
}

function toggleFavorite(songId) {
    const d = getSongData(songId);
    d.isFavorite = !d.isFavorite;
    saveState();
    renderAll();
}

function playRandomMix() {
    // Generate a diverse queue: one song per artist, up to 10 songs
    const artistMap = {};
    const shuffled = shuffleArray([...SONGS]);
    const mix = [];
    for (const song of shuffled) {
        if (!artistMap[song.artist] && mix.length < 10) {
            mix.push(song);
            artistMap[song.artist] = true;
        }
    }
    if (mix.length === 0) return;
    state.originalOrder = [...mix];
    state.queue = [...mix];
    state.queueIndex = 0;
    state.shuffle = false;
    playSong(state.queue[0], true);
}

function showToast(msg) {
    const existing = document.querySelector('.toast');
    if (existing) existing.remove();
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.textContent = msg;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 2000);
}

function addToQueue(song) {
    state.queue.push(song);
    if (state.queue.length === 1) {
        state.queueIndex = 0;
        playSong(song, true);
    }
    renderQueue();
    showToast(`Added "${song.title}" to queue`);
}

function playNext(song) {
    state.queue.splice(state.queueIndex + 1, 0, song);
    renderQueue();
    showToast(`"${song.title}" up next`);
}

function clearQueue() {
    const current = state.queue[state.queueIndex];
    if (current) {
        state.queue = [current];
        state.queueIndex = 0;
    } else {
        state.queue = [];
        state.queueIndex = -1;
    }
    renderQueue();
}

audio.addEventListener('ended', nextSong);
audio.addEventListener('timeupdate', updateProgress);

// -------------------------------------------
// AD Breaks
// -------------------------------------------
function maybeShowAd() {
    if (state.songsPlayed > 0 && state.songsPlayed % 4 === 0) {
        let adPool = AD_DATA;
        // 40% chance on Tuesdays to show taco ad instead
        if (isTacoTuesday() && Math.random() < 0.4) {
            adPool = TACO_ADS;
        }
        const ad = adPool[Math.floor(Math.random() * adPool.length)];
        $('#ad-header').textContent = ad.title;
        $('#ad-img').src = ad.img;
        $('#ad-msg').textContent = ad.msg;
        $('#ad-dismiss').textContent = ad.dismiss;
        $('#ad-overlay').style.display = 'flex';
        // Auto dismiss after 8 seconds
        if (state._adTimeout) clearTimeout(state._adTimeout);
        state._adTimeout = setTimeout(() => {
            $('#ad-overlay').style.display = 'none';
        }, 8000);
    }
}

// -------------------------------------------
// Navigation
// -------------------------------------------
function showView(name) {
    state.previousView = state.currentView;
    state.currentView = name;
    $$('.view').forEach(v => v.classList.remove('active'));
    const view = $(`#view-${name}`);
    if (view) view.classList.add('active');
    $$('.nav-item').forEach(n => n.classList.toggle('active', n.dataset.view === name));
    $$('.mobile-tab').forEach(n => n.classList.toggle('active', n.dataset.view === name));
    if (name === 'vault') renderVault();
    if (name === 'search') $('#search-input').focus();
    if (name === 'player') renderPlayerFull();
}

// -------------------------------------------
// Rendering
// -------------------------------------------
function renderSongRow(song, index, options = {}) {
    const d = getSongData(song.id);
    const current = state.queue[state.queueIndex];
    const isPlaying = current && current.id === song.id;
    const topSongs = getTopSongs().slice(0, 3);
    const mvpRank = topSongs.findIndex(s => s.id === song.id) + 1;
    return `
        <div class="song-row ${isPlaying ? 'playing' : ''}" data-song-id="${song.id}" data-index="${index}">
            ${options.showNum ? `<span class="song-row-num">${index + 1}</span>` : ''}
            <div style="position:relative">
                <img src="${imgPath(song.image)}" alt="" class="song-row-art" loading="lazy">
                ${mvpRank > 0 ? `<div class="song-row-mvp">${mvpRank}</div>` : ''}
            </div>
            <div class="song-row-info">
                <div class="song-row-title">${song.title}</div>
                <div class="song-row-artist">${song.artist}</div>
            </div>
            ${d.playCount > 0 ? `<span class="song-row-plays">${d.playCount} plays</span>` : ''}
            <button class="song-row-fav ${d.isFavorite ? 'active' : ''}" data-fav-id="${song.id}">${d.isFavorite ? icon('starFilled', 16) : icon('starEmpty', 16)}</button>
            <button class="song-row-menu" data-menu-id="${song.id}">${icon('ellipsis', 14)}</button>
        </div>
    `;
}

function renderScrollCard(song, rank) {
    return `
        <div class="scroll-card" data-song-id="${song.id}">
            <div class="scroll-card-art">
                <img src="${imgPath(song.image)}" alt="${song.title}" loading="lazy">
                ${rank ? `<div class="mvp-badge">${rank}</div>` : ''}
            </div>
            <div class="scroll-card-name">${song.title}</div>
            <div class="scroll-card-artist">${song.artist}</div>
        </div>
    `;
}

function renderHome() {
    // Song of the Day
    const potd = getSongOfDay();
    $('#potd-card').innerHTML = `
        <img src="${imgPath(potd.image)}" alt="${potd.title}" class="potd-art">
        <div class="potd-info">
            <div class="potd-title">${potd.title}</div>
            <div class="potd-artist">${potd.artist}</div>
        </div>
        <button class="potd-play" data-song-id="${potd.id}">${icon('play', 18)}</button>
    `;

    // Recent
    const recent = getRecentSongs();
    const recentSection = $('#recent-section');
    if (recent.length > 0) {
        recentSection.style.display = '';
        $('#recent-row').innerHTML = recent.map(s => renderScrollCard(s)).join('');
    } else { recentSection.style.display = 'none'; }

    // MVP
    const top = getTopSongs().slice(0, 10);
    const mvpSection = $('#mvp-section');
    if (top.length > 0) {
        mvpSection.style.display = '';
        $('#mvp-row').innerHTML = top.map((s, i) => renderScrollCard(s, i < 3 ? i + 1 : 0)).join('');
    } else { mvpSection.style.display = 'none'; }

    // Full Roster
    $('#full-roster').innerHTML = SONGS.map((s, i) => renderSongRow(s, i, { showNum: true })).join('');

    // Taco Tuesday
    if (isTacoTuesday()) $('#taco-banner').style.display = '';
}

function renderVault() {
    const systemPl = [
        { id: 'recent', name: 'Recently Played', art: 'images/ui/lebron_recent.png', count: getRecentSongs().length },
        { id: 'top', name: 'MVP Selections', art: 'images/ui/lebron_top.png', count: getTopSongs().length },
        { id: 'favorites', name: 'All-Stars', art: 'images/ui/lebron_favorites.png', count: getFavorites().length },
    ];
    $('#system-playlists').innerHTML = systemPl.map(p => `
        <div class="playlist-row" data-playlist-id="${p.id}">
            <img src="${p.art}" alt="${p.name}" class="playlist-art">
            <div class="playlist-info">
                <div class="playlist-name">${p.name}</div>
                <div class="playlist-count">${p.count} songs</div>
            </div>
            <span class="playlist-chevron">${icon('chevronRight')}</span>
        </div>
    `).join('');

    $('#user-playlists').innerHTML = state.playlists.map(p => `
        <div class="playlist-row" data-playlist-id="user-${p.id}">
            <div class="playlist-art playlist-art-placeholder">${icon('musicNote')}</div>
            <div class="playlist-info">
                <div class="playlist-name">${p.name}</div>
                <div class="playlist-count">${p.songIds.length} songs</div>
            </div>
            <span class="playlist-chevron">${icon('chevronRight')}</span>
        </div>
    `).join('');

    const favs = getFavorites();
    if (favs.length > 0) {
        $('#allstars-list').innerHTML = favs.map((s, i) => renderSongRow(s, i)).join('');
        $('#empty-allstars').style.display = 'none';
        $('#allstars-list').style.display = '';
    } else {
        $('#allstars-list').style.display = 'none';
        $('#empty-allstars').style.display = '';
    }

    renderSidebarPlaylists();
}

function renderSidebarPlaylists() {
    const el = $('#sidebar-playlists');
    const items = [
        { id: 'recent', name: 'Recently Played' },
        { id: 'top', name: 'MVP Selections' },
        { id: 'favorites', name: 'All-Stars' },
        ...state.playlists.map(p => ({ id: `user-${p.id}`, name: p.name })),
    ];
    el.innerHTML = items.map(p => `<button class="sidebar-pl-item" data-playlist-id="${p.id}">${p.name}</button>`).join('');
}

function openPlaylistDetail(playlistId) {
    let songs = [];
    let name = '';
    let art = '';

    if (playlistId === 'recent') { songs = getRecentSongs(); name = 'Recently Played'; art = 'images/ui/lebron_recent.png'; }
    else if (playlistId === 'top') { songs = getTopSongs(); name = 'MVP Selections'; art = 'images/ui/lebron_top.png'; }
    else if (playlistId === 'favorites') { songs = getFavorites(); name = 'All-Stars'; art = 'images/ui/lebron_favorites.png'; }
    else if (playlistId.startsWith('user-')) {
        const id = parseInt(playlistId.replace('user-', ''));
        const pl = state.playlists.find(p => p.id === id);
        if (pl) { name = pl.name; songs = pl.songIds.map(sid => SONGS.find(s => s.id === sid)).filter(Boolean); art = ''; }
    }

    $('#playlist-header').innerHTML = `
        ${art ? `<img src="${art}" alt="" class="playlist-header-art">` : ''}
        <div class="playlist-header-info">
            <div class="playlist-header-name">${name}</div>
            <div class="playlist-header-count">${songs.length} songs</div>
        </div>
    `;
    $('#playlist-songs').innerHTML = songs.map((s, i) => renderSongRow(s, i, { showNum: true })).join('');
    $('#view-playlist-detail')._songs = songs;
    showView('playlist-detail');
}

function renderPlayerFull() {
    const song = state.queue[state.queueIndex];
    const emptyEl = $('#player-empty');
    const contentEl = $('#player-content');

    if (!song) {
        if (emptyEl) emptyEl.style.display = '';
        if (contentEl) contentEl.style.display = 'none';
        // Reset gradient for empty state
        const scroll = $('.player-view-scroll');
        if (scroll) scroll.style.background = `linear-gradient(180deg, rgba(255,215,0,0.12) 0%, var(--bg) 40%)`;
        return;
    }

    if (emptyEl) emptyEl.style.display = 'none';
    if (contentEl) contentEl.style.display = '';

    // Apply current dynamic gradient
    updatePlayerGradient(currentGradientColor);

    $('#player-art').src = imgPath(song.image);
    $('#player-title').textContent = song.title;
    $('#player-artist').textContent = song.artist;

    const d = getSongData(song.id);
    const favBtn = $('#btn-favorite');
    favBtn.classList.toggle('active', d.isFavorite);
    favBtn.querySelector('.action-icon').innerHTML = d.isFavorite ? icon('starFilled', 20) : icon('starEmpty', 20);

    $('#btn-shuffle').classList.toggle('active', state.shuffle);
    $('#btn-shuffle').innerHTML = icon('shuffle');

    $('#btn-repeat').classList.toggle('active', state.repeat !== 'off');
    $('#btn-repeat').innerHTML = state.repeat === 'one' ? icon('repeatOne') : icon('repeat');

    $('#btn-play').innerHTML = state.playing ? icon('pause', 26) : icon('play', 26);
    $('#btn-play').classList.toggle('is-playing', state.playing);
    $('#btn-prev').innerHTML = icon('prev', 24);
    $('#btn-next').innerHTML = icon('next', 24);

    // Bench
    const bench = state.queue.slice(state.queueIndex + 1, state.queueIndex + 4);
    if (bench.length > 0) {
        $('#bench-section').style.display = '';
        $('#bench-list').innerHTML = bench.map(s => `
            <div class="bench-item" data-song-id="${s.id}">
                <img src="${imgPath(s.image)}" alt="" class="bench-art">
                <div class="bench-info">
                    <div class="bench-name">${s.title}</div>
                    <div class="bench-artist">${s.artist}</div>
                </div>
            </div>
        `).join('');
    } else { $('#bench-section').style.display = 'none'; }
}

function updateProgress() {
    const pct = audio.duration ? (audio.currentTime / audio.duration) * 100 : 0;
    $('#player-progress-fill').style.width = pct + '%';
    $('#player-progress-thumb').style.left = pct + '%';
    $('#npb-progress-fill').style.width = pct + '%';
    $('#player-time-current').textContent = formatTime(audio.currentTime);
    const remaining = audio.duration ? audio.duration - audio.currentTime : 0;
    $('#player-time-total').textContent = remaining > 0 ? '-' + formatTime(remaining) : '0:00';
}

function updateUI() {
    const song = state.queue[state.queueIndex];
    const bar = $('#now-playing-bar');

    if (song) {
        bar.style.display = '';
        $('#npb-art').src = imgPath(song.image);
        $('#npb-title').textContent = song.title;
        $('#npb-artist').textContent = song.artist;
        const d = getSongData(song.id);
        const favEl = $('#npb-fav');
        favEl.classList.toggle('active', d.isFavorite);
        favEl.innerHTML = d.isFavorite ? icon('starFilled', 16) : icon('starEmpty', 16);
    }

    // Now playing bar controls
    $('#npb-play').innerHTML = state.playing ? icon('pause', 14) : icon('play', 14);
    $('#npb-prev').innerHTML = icon('prev', 16);
    $('#npb-next').innerHTML = icon('next', 16);

    // Update playing state on song rows
    $$('.song-row').forEach(row => {
        row.classList.toggle('playing', song && parseInt(row.dataset.songId) === song.id);
    });

    if (state.currentView === 'player') renderPlayerFull();
    if (song) updateMediaSession(song);
    // Update queue if panel is open
    if ($('#queue-panel').classList.contains('open')) renderQueue();
}

function updateMediaSession(song) {
    if ('mediaSession' in navigator) {
        navigator.mediaSession.metadata = new MediaMetadata({
            title: song.title,
            artist: song.artist,
            album: 'LeBronify',
            artwork: [{ src: imgPath(song.image), sizes: '256x256', type: 'image/png' }],
        });
        navigator.mediaSession.setActionHandler('play', () => togglePlay());
        navigator.mediaSession.setActionHandler('pause', () => togglePlay());
        navigator.mediaSession.setActionHandler('previoustrack', prevSong);
        navigator.mediaSession.setActionHandler('nexttrack', nextSong);
    }
}

function renderQueue() {
    const current = state.queue[state.queueIndex];
    const courtEl = $('#queue-court');

    // On The Court (now playing)
    if (current) {
        courtEl.innerHTML = `
            <div class="queue-court-label">ON THE COURT</div>
            <div class="queue-court-content">
                <img src="${imgPath(current.image)}" alt="" class="queue-court-art">
                <div class="queue-court-info">
                    <div class="queue-court-title">${current.title}</div>
                    <div class="queue-court-artist">${current.artist}</div>
                </div>
                <div class="queue-court-controls">
                    <button class="queue-court-btn" id="queue-prev-btn">${icon('prev', 18)}</button>
                    <button class="queue-court-play" id="queue-play-btn">${state.playing ? icon('pause', 16) : icon('play', 16)}</button>
                    <button class="queue-court-btn" id="queue-next-btn">${icon('next', 18)}</button>
                </div>
            </div>
        `;
    } else {
        courtEl.innerHTML = '';
    }

    // On The Bench (upcoming songs)
    const bench = state.queue.slice(state.queueIndex + 1);
    $('#queue-bench-count').textContent = bench.length;

    if (bench.length > 0) {
        $('#queue-list').innerHTML = bench.map((s, i) => `
            <div class="queue-item" data-queue-index="${state.queueIndex + 1 + i}">
                <span class="queue-item-num">${i + 1}</span>
                <img src="${imgPath(s.image)}" alt="" class="queue-art">
                <div class="queue-info">
                    <div class="queue-name">${s.title}</div>
                    <div class="queue-artist">${s.artist}</div>
                </div>
                <button class="queue-item-play">${icon('play', 14)}</button>
            </div>
        `).join('');
    } else {
        $('#queue-list').innerHTML = `
            <div class="queue-empty">
                <div class="queue-empty-icon">${icon('musicNote', 48)}</div>
                <div class="queue-empty-title">The King's queue is empty</div>
                <div class="queue-empty-text">Add songs to keep the vibes going</div>
            </div>
        `;
    }

    // Update bottom controls state
    const shuffleBtn = $('#queue-shuffle');
    const repeatBtn = $('#queue-repeat');
    if (shuffleBtn) shuffleBtn.classList.toggle('active', state.shuffle);
    if (repeatBtn) repeatBtn.classList.toggle('active', state.repeat !== 'off');
}

function renderAll() {
    renderHome();
    if (state.currentView === 'vault') renderVault();
    updateUI();
}

// -------------------------------------------
// Event Handlers
// -------------------------------------------
document.addEventListener('DOMContentLoaded', () => {
    loadState();
    renderAll();
    renderSidebarPlaylists();

    // Set initial icons for player controls
    $('#btn-shuffle').innerHTML = icon('shuffle');
    $('#btn-prev').innerHTML = icon('prev', 24);
    $('#btn-play').innerHTML = icon('play', 22);
    $('#btn-next').innerHTML = icon('next', 24);
    $('#btn-repeat').innerHTML = icon('repeat');
    $('#btn-favorite .action-icon').innerHTML = icon('starEmpty', 20);

    // Initialize player empty state
    renderPlayerFull();

    // Volume
    const vol = $('#volume-slider');
    audio.volume = vol.value / 100;
    vol.addEventListener('input', () => { audio.volume = vol.value / 100; });

    // Navigation
    $$('.nav-item, .mobile-tab').forEach(btn => {
        btn.addEventListener('click', () => showView(btn.dataset.view));
    });

    // Shuffle all
    $('#shuffle-all-btn').addEventListener('click', () => {
        playQueue([...SONGS], Math.floor(Math.random() * SONGS.length));
        state.shuffle = true;
        toggleShuffle();
    });

    // Taco Tuesday
    if ($('#taco-play-btn')) {
        $('#taco-play-btn').addEventListener('click', () => {
            const taco = SONGS.find(s => s.id === 43);
            if (taco) playSong(taco);
        });
    }

    // Song clicks (delegated)
    document.addEventListener('click', (e) => {
        const row = e.target.closest('.song-row');
        if (row && !e.target.closest('.song-row-fav') && !e.target.closest('.song-row-menu')) {
            const songId = parseInt(row.dataset.songId);
            const song = SONGS.find(s => s.id === songId);
            if (song) {
                const list = row.closest('.song-list');
                if (list) {
                    const rows = list.querySelectorAll('.song-row');
                    const songs = Array.from(rows).map(r => SONGS.find(s => s.id === parseInt(r.dataset.songId))).filter(Boolean);
                    const idx = songs.findIndex(s => s.id === songId);
                    playQueue(songs, idx);
                } else { playSong(song); }
            }
        }

        const favBtn = e.target.closest('.song-row-fav');
        if (favBtn) {
            e.stopPropagation();
            toggleFavorite(parseInt(favBtn.dataset.favId));
        }

        const card = e.target.closest('.scroll-card');
        if (card) {
            const songId = parseInt(card.dataset.songId);
            const song = SONGS.find(s => s.id === songId);
            if (song) playSong(song);
        }

        const potdPlay = e.target.closest('.potd-play');
        if (potdPlay) {
            const song = SONGS.find(s => s.id === parseInt(potdPlay.dataset.songId));
            if (song) playSong(song);
        }

        const plRow = e.target.closest('.playlist-row');
        if (plRow) openPlaylistDetail(plRow.dataset.playlistId);

        const sidebarPl = e.target.closest('.sidebar-pl-item');
        if (sidebarPl) openPlaylistDetail(sidebarPl.dataset.playlistId);

        const benchItem = e.target.closest('.bench-item');
        if (benchItem) {
            const songId = parseInt(benchItem.dataset.songId);
            const idx = state.queue.findIndex(s => s.id === songId);
            if (idx >= 0) { state.queueIndex = idx; playSong(state.queue[idx], true); }
        }

        const queueItem = e.target.closest('.queue-item');
        if (queueItem && !e.target.closest('.queue-item-play')) {
            state.queueIndex = parseInt(queueItem.dataset.queueIndex);
            playSong(state.queue[state.queueIndex], true);
            renderQueue();
        }
    });

    // Player controls
    $('#btn-play').addEventListener('click', togglePlay);
    $('#btn-next').addEventListener('click', nextSong);
    $('#btn-prev').addEventListener('click', prevSong);
    $('#btn-shuffle').addEventListener('click', toggleShuffle);
    $('#btn-repeat').addEventListener('click', toggleRepeat);
    $('#btn-favorite').addEventListener('click', () => {
        const song = state.queue[state.queueIndex];
        if (song) toggleFavorite(song.id);
    });

    // Now Playing Bar controls
    $('#npb-play').addEventListener('click', togglePlay);
    $('#npb-next').addEventListener('click', nextSong);
    $('#npb-prev').addEventListener('click', prevSong);
    $('#npb-fav').addEventListener('click', () => {
        const song = state.queue[state.queueIndex];
        if (song) toggleFavorite(song.id);
    });
    $('#npb-open-player').addEventListener('click', () => showView('player'));

    // Progress bar seeking + drag (like iOS drag gesture with min distance 0)
    const progressBar = $('#player-progress-bar');
    let isDragging = false;

    function seekFromEvent(e, bar) {
        const rect = bar.getBoundingClientRect();
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const pct = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
        if (audio.duration) audio.currentTime = pct * audio.duration;
        // Show thumb while dragging
        $('#player-progress-thumb').style.opacity = '1';
    }

    progressBar.addEventListener('mousedown', (e) => {
        isDragging = true;
        seekFromEvent(e, progressBar);
    });
    progressBar.addEventListener('touchstart', (e) => {
        isDragging = true;
        seekFromEvent(e, progressBar);
    }, { passive: true });

    document.addEventListener('mousemove', (e) => {
        if (isDragging) seekFromEvent(e, progressBar);
    });
    document.addEventListener('touchmove', (e) => {
        if (isDragging) seekFromEvent(e, progressBar);
    }, { passive: true });

    document.addEventListener('mouseup', () => {
        if (isDragging) { isDragging = false; $('#player-progress-thumb').style.opacity = ''; }
    });
    document.addEventListener('touchend', () => {
        if (isDragging) { isDragging = false; $('#player-progress-thumb').style.opacity = ''; }
    });

    // Mix button
    $('#btn-mix').addEventListener('click', playRandomMix);

    // Queue panel
    $('#btn-queue').addEventListener('click', () => {
        renderQueue();
        $('#queue-panel').classList.toggle('open');
    });
    $('#queue-close').addEventListener('click', () => {
        $('#queue-panel').classList.remove('open');
    });

    // Queue bottom controls
    $('#queue-clear').addEventListener('click', () => { clearQueue(); renderQueue(); });
    $('#queue-shuffle').addEventListener('click', () => { toggleShuffle(); renderQueue(); });
    $('#queue-repeat').addEventListener('click', () => { toggleRepeat(); renderQueue(); });
    $('#queue-mix').addEventListener('click', () => {
        playRandomMix();
        renderQueue();
    });

    // Queue court controls (delegated since they re-render)
    document.addEventListener('click', (e) => {
        if (e.target.closest('#queue-play-btn')) togglePlay();
        if (e.target.closest('#queue-prev-btn')) { prevSong(); renderQueue(); }
        if (e.target.closest('#queue-next-btn')) { nextSong(); renderQueue(); }
        if (e.target.closest('.queue-item-play')) {
            const item = e.target.closest('.queue-item');
            if (item) {
                state.queueIndex = parseInt(item.dataset.queueIndex);
                playSong(state.queue[state.queueIndex], true);
                renderQueue();
            }
        }
    });

    // Player empty state play button
    $('#player-empty-play').addEventListener('click', () => {
        playQueue([...SONGS], Math.floor(Math.random() * SONGS.length));
    });

    // Back buttons
    $('#player-back-btn').addEventListener('click', () => showView(state.previousView || 'home'));
    $('#playlist-back-btn').addEventListener('click', () => showView(state.previousView || 'vault'));

    // Playlist play all / shuffle
    $('#playlist-play-all').addEventListener('click', () => {
        const songs = $('#view-playlist-detail')._songs;
        if (songs && songs.length) playQueue(songs, 0);
    });
    $('#playlist-shuffle').addEventListener('click', () => {
        const songs = $('#view-playlist-detail')._songs;
        if (songs && songs.length) {
            state.shuffle = true;
            playQueue(songs, 0);
        }
    });

    // Vault tabs
    $$('.vault-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            $$('.vault-tab').forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            $$('.vault-panel').forEach(p => p.classList.remove('active'));
            $(`#vault-${tab.dataset.vaultTab}`).classList.add('active');
        });
    });

    // Search
    $('#search-input').addEventListener('input', (e) => {
        const q = e.target.value.toLowerCase().trim();
        if (q.length === 0) { $('#search-results').innerHTML = ''; return; }
        const results = SONGS.filter(s =>
            s.title.toLowerCase().includes(q) || s.artist.toLowerCase().includes(q)
        );
        $('#search-results').innerHTML = results.map((s, i) => renderSongRow(s, i)).join('');
    });

    // Create playlist
    function openCreatePlaylist() {
        $('#modal-create').style.display = 'flex';
        $('#playlist-name-input').value = '';
        $('#playlist-name-input').focus();
    }
    $('#create-playlist-btn').addEventListener('click', openCreatePlaylist);
    $('#vault-create-btn').addEventListener('click', openCreatePlaylist);
    $('#modal-cancel').addEventListener('click', () => { $('#modal-create').style.display = 'none'; });
    $('#modal-confirm').addEventListener('click', () => {
        const name = $('#playlist-name-input').value.trim();
        if (!name) return;
        const id = Date.now();
        state.playlists.push({ id, name, songIds: [] });
        saveState();
        $('#modal-create').style.display = 'none';
        renderVault();
        renderSidebarPlaylists();
    });

    // Add to playlist
    $('#btn-add-playlist').addEventListener('click', () => {
        const song = state.queue[state.queueIndex];
        if (!song) return;
        const modal = $('#modal-add-to-playlist');
        $('#modal-playlist-list').innerHTML = state.playlists.map(p =>
            `<div class="modal-pl-item" data-add-pl-id="${p.id}">${p.name}</div>`
        ).join('') || '<p style="color:var(--t3);padding:12px;">No playbooks yet. Create one first!</p>';
        modal.style.display = 'flex';
    });
    $('#modal-add-cancel').addEventListener('click', () => { $('#modal-add-to-playlist').style.display = 'none'; });
    document.addEventListener('click', (e) => {
        const item = e.target.closest('.modal-pl-item');
        if (item) {
            const plId = parseInt(item.dataset.addPlId);
            const pl = state.playlists.find(p => p.id === plId);
            // Support both player action and context menu adds
            const song = state._contextSong || state.queue[state.queueIndex];
            if (pl && song && !pl.songIds.includes(song.id)) {
                pl.songIds.push(song.id);
                saveState();
            }
            state._contextSong = null;
            $('#modal-add-to-playlist').style.display = 'none';
            renderVault();
            renderSidebarPlaylists();
        }
    });

    // AD dismiss
    $('#ad-dismiss').addEventListener('click', () => {
        $('#ad-overlay').style.display = 'none';
        if (state._adTimeout) clearTimeout(state._adTimeout);
    });

    // Context menu for songs
    let contextMenuEl = null;
    function showContextMenu(songId, x, y) {
        closeContextMenu();
        const song = SONGS.find(s => s.id === songId);
        if (!song) return;
        const d = getSongData(songId);
        const menu = document.createElement('div');
        menu.className = 'context-menu';
        menu.innerHTML = `
            <div class="context-menu-item" data-action="play" data-id="${songId}">${icon('play', 14)} Play Now</div>
            <div class="context-menu-item" data-action="playnext" data-id="${songId}">${icon('next', 14)} Up Next</div>
            <div class="context-menu-item" data-action="addqueue" data-id="${songId}">${icon('musicNote', 14)} Add to Queue</div>
            <div class="context-menu-item" data-action="addplaylist" data-id="${songId}">${icon('starEmpty', 14)} Add to Playbook</div>
            <div class="context-menu-item" data-action="fav" data-id="${songId}">${d.isFavorite ? icon('starFilled', 14) + ' Remove from All-Stars' : icon('starEmpty', 14) + ' Add to All-Stars'}</div>
        `;
        // Position
        menu.style.left = Math.min(x, window.innerWidth - 200) + 'px';
        menu.style.top = Math.min(y, window.innerHeight - 220) + 'px';
        document.body.appendChild(menu);
        contextMenuEl = menu;

        menu.addEventListener('click', (e) => {
            const item = e.target.closest('.context-menu-item');
            if (!item) return;
            const action = item.dataset.action;
            const id = parseInt(item.dataset.id);
            const s = SONGS.find(s => s.id === id);
            if (action === 'play' && s) playSong(s);
            if (action === 'playnext' && s) playNext(s);
            if (action === 'addqueue' && s) addToQueue(s);
            if (action === 'fav') toggleFavorite(id);
            if (action === 'addplaylist' && s) {
                state._contextSong = s;
                const modal = $('#modal-add-to-playlist');
                $('#modal-playlist-list').innerHTML = state.playlists.map(p =>
                    `<div class="modal-pl-item" data-add-pl-id="${p.id}">${p.name}</div>`
                ).join('') || '<p style="color:var(--t3);padding:12px;">No playbooks yet. Create one first!</p>';
                modal.style.display = 'flex';
            }
            closeContextMenu();
        });
    }
    function closeContextMenu() {
        if (contextMenuEl) { contextMenuEl.remove(); contextMenuEl = null; }
    }
    document.addEventListener('click', (e) => {
        if (!e.target.closest('.context-menu')) closeContextMenu();
    });
    document.addEventListener('click', (e) => {
        const menuBtn = e.target.closest('.song-row-menu');
        if (menuBtn) {
            e.stopPropagation();
            const rect = menuBtn.getBoundingClientRect();
            showContextMenu(parseInt(menuBtn.dataset.menuId), rect.right, rect.bottom);
        }
    });

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        if (e.target.tagName === 'INPUT') return;
        if (e.code === 'Space') { e.preventDefault(); togglePlay(); }
        if (e.code === 'ArrowRight') nextSong();
        if (e.code === 'ArrowLeft') prevSong();
    });
});

})();
