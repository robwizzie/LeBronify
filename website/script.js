/* ============================================
   LEBRONIFY WEBSITE - SCRIPTS
   ============================================ */

document.addEventListener('DOMContentLoaded', () => {

    // -------------------------------------------
    // Song data (ALL songs from the app)
    // -------------------------------------------
    const songs = [
        { title: "Ain't It Bron", artist: "hen.bouselog", image: "ain't_it_bron.png" },
        { title: "All LeBron Things", artist: "jeremytache", image: "all_lebron_things.png" },
        { title: "Bring Me Back To Bron", artist: "LeBron Fan", image: "bring_me_back_to_bron.png" },
        { title: "Bron Royalty", artist: "ilyaugust", image: "bron_royalty.png" },
        { title: "Bronpeii", artist: "ilyaugust", image: "bronpeii.png" },
        { title: "Brons Not Brongedies", artist: "ilyaugust", image: "brons_not_brongedies.png" },
        { title: "Brontastic", artist: "ilyaugust", image: "brontastic.png" },
        { title: "Catch a LeNade For You", artist: "ilyaugust", image: "catch_a_lenade_for_you.png" },
        { title: "Dear LeBron", artist: "sdotreidy", image: "dear_lebron.png" },
        { title: "Dunk With a Smile", artist: "LeBron Fan", image: "dunk_with_a_smile.png" },
        { title: "He Is LeBron James", artist: "My Way", image: "he_is_lebron_james.png" },
        { title: "He Is The King", artist: "LeBron Fan", image: "he_is_the_king.png" },
        { title: "I'm Like That's Bron", artist: "ilyaugust", image: "i'm_like_that's_bron.png" },
        { title: "I Believe in LeBron", artist: "imakeparodyzz", image: "i_believe_in_lebron.png" },
        { title: "I Glazed LeBron (And I Liked It)", artist: "timringling", image: "i_glazed_lebron_(and_i_liked_it).png" },
        { title: "In The Bron", artist: "ilyaugust", image: "in_the_bron.png" },
        { title: "La Bron Bron Land", artist: "House of Highlights", image: "la_bron_bron_land.png" },
        { title: "Le Bronba", artist: "enrique_l_garibay", image: "le_bronba.png" },
        { title: "LeAfrica", artist: "standleyjohnsonmusic", image: "leafrica.png" },
        { title: "LeAll of Me", artist: "musicbykidb", image: "leall_of_me.png" },
        { title: "LeBron, LeBron, LeBron", artist: "LeBron Fan", image: "lebron,_lebron,_lebron.png" },
        { title: "LeBron Has Taken a Toll", artist: "ilyaugust", image: "lebron_has_taken_a_toll.png" },
        { title: "LeBron That I Used to Know", artist: "LeBron Fan", image: "lebron_that_i_used_to_know.png" },
        { title: "LeBronifornia Girls", artist: "izzydrip", image: "lebronifornia_girls.png" },
        { title: "LeBrons Wide Open", artist: "timringling", image: "lebrons_wide_open.png" },
        { title: "LeCurious James", artist: "leiheart.radio.station", image: "lecurious_james.png" },
        { title: "LeEarned It", artist: "kai.so", image: "leearned_it.png" },
        { title: "LeGolden Hour", artist: "ilyaugust", image: "legolden_hour.png" },
        { title: "LeHips Don't Lie", artist: "ant.jr06", image: "lehips_don't_lie.png" },
        { title: "LeLove Yourself", artist: "musicbykidb", image: "lelove_yourself.png" },
        { title: "LeStiches", artist: "ilyaugust", image: "lestiches.png" },
        { title: "Let LeBron Know", artist: "LeBron Fan", image: "let_lebron_know.png" },
        { title: "Life is a LeHighway", artist: "jeppreyjung", image: "life_is_a_lehighway.png" },
        { title: "Man On The Lakers", artist: "Talented Blake", image: "man_on_the_lakers.png" },
        { title: "Marry Bron", artist: "ilyaugust", image: "marry_bron.png" },
        { title: "No Bron", artist: "ilyaugust", image: "no_bron.png" },
        { title: "Not Like Bron", artist: "vonpierreofficial", image: "not_like_bron.png" },
        { title: "Oh Mr LeBron", artist: "LeBron Fan", image: "oh_mr_lebron.png" },
        { title: "Romantic Bronicide", artist: "ilyaugust", image: "romantic_bronicide.png" },
        { title: "Shut Up and Dance With Bron", artist: "ilyaugust", image: "shut_up_and_dance_with_bron.png" },
        { title: "Still Glazing You", artist: "musicbykidb", image: "still_glazing_you.png" },
        { title: "Sweet LeScape", artist: "ilyaugust", image: "sweet_lescape.png" },
        { title: "TACO TUESDAYYYYY", artist: "LeBron James", image: "taco_tuesday.jpg" },
        { title: "That's Bron", artist: "JJ Darrow", image: "that's_bron.png" },
        { title: "That's What Makes Bron Beautiful", artist: "ilyaugust", image: "that's_what_makes_bron_beautiful.png" },
        { title: "Thinkin Bout LeBron", artist: "ilyaugust", image: "thinkin_bout_lebron.png" },
        { title: "This is The Bron", artist: "fanoftatum0", image: "this_is_the_bron.png" },
        { title: "Towards The Bron", artist: "ilyaugust", image: "towards_the_bron.png" },
        { title: "You Are My Sunshine", artist: "LeBron Fan", image: "you_are_my_sunshine.png" },
    ];

    // -------------------------------------------
    // Populate Song Grid - ALL songs
    // -------------------------------------------
    const songGrid = document.getElementById('song-grid');
    if (songGrid) {
        songs.forEach((song) => {
            const item = document.createElement('div');
            item.className = 'song-item';
            item.innerHTML = `
                <div class="song-item-art">
                    <img src="images/albums/${song.image}" alt="${song.title}" loading="lazy">
                </div>
                <div class="song-item-title">${song.title}</div>
                <div class="song-item-artist">${song.artist}</div>
            `;
            songGrid.appendChild(item);
        });
    }

    // -------------------------------------------
    // Navbar scroll effect
    // -------------------------------------------
    const navbar = document.getElementById('navbar');
    let lastScroll = 0;

    window.addEventListener('scroll', () => {
        const scrollY = window.scrollY;
        if (scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
        lastScroll = scrollY;
    }, { passive: true });

    // -------------------------------------------
    // Mobile menu toggle
    // -------------------------------------------
    const mobileBtn = document.getElementById('mobile-menu-btn');
    const navLinks = document.getElementById('nav-links');

    if (mobileBtn && navLinks) {
        mobileBtn.addEventListener('click', () => {
            mobileBtn.classList.toggle('active');
            navLinks.classList.toggle('active');
        });

        navLinks.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', () => {
                mobileBtn.classList.remove('active');
                navLinks.classList.remove('active');
            });
        });
    }

    // -------------------------------------------
    // Animated stat counters
    // -------------------------------------------
    const statNumbers = document.querySelectorAll('.stat-number');

    function animateCounter(el) {
        const target = parseInt(el.dataset.target);
        const duration = 1500;
        const start = performance.now();

        function update(now) {
            const elapsed = now - start;
            const progress = Math.min(elapsed / duration, 1);
            const eased = 1 - (1 - progress) * (1 - progress);
            el.textContent = Math.round(target * eased);
            if (progress < 1) requestAnimationFrame(update);
        }

        requestAnimationFrame(update);
    }

    const statsObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCounter(entry.target);
                statsObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });

    statNumbers.forEach(el => statsObserver.observe(el));

    // -------------------------------------------
    // Scroll-triggered animations
    // -------------------------------------------
    const animatedElements = document.querySelectorAll('[data-animate]');

    const animObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                const siblings = entry.target.parentElement.querySelectorAll('[data-animate]');
                let delay = 0;
                siblings.forEach((sib, i) => {
                    if (sib === entry.target) delay = i * 80;
                });
                setTimeout(() => {
                    entry.target.classList.add('visible');
                }, delay);
                animObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1 });

    animatedElements.forEach(el => animObserver.observe(el));

    // -------------------------------------------
    // App Breakdown Tabs
    // -------------------------------------------
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabPanels = document.querySelectorAll('.breakdown-panel');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const tabId = btn.dataset.tab;

            tabBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            tabPanels.forEach(panel => {
                panel.classList.remove('active');
                if (panel.id === `tab-${tabId}`) {
                    panel.classList.add('active');
                }
            });
        });
    });

    // -------------------------------------------
    // Splash Screen loading phrases
    // -------------------------------------------
    const splashPhrases = [
        "Checking LeBron's playlist...",
        "Polishing the crown...",
        "Loading 4 rings worth of bangers...",
        "Warming up from the bench...",
        "Reviewing game film...",
        "The King has arrived.",
        "LeLoading...",
        "Preparing the chalk toss...",
        "Downloading greatness...",
        "Counting triple-doubles...",
        "Activating playoff mode...",
    ];

    const splashPhrase = document.getElementById('splash-phrase');
    if (splashPhrase) {
        let phraseIndex = 0;
        setInterval(() => {
            phraseIndex = (phraseIndex + 1) % splashPhrases.length;
            splashPhrase.style.opacity = '0';
            setTimeout(() => {
                splashPhrase.textContent = splashPhrases[phraseIndex];
                splashPhrase.style.opacity = '0.7';
            }, 300);
        }, 2500);
    }

    // -------------------------------------------
    // Mini Player - Full functionality
    // -------------------------------------------
    const miniProgressFill = document.getElementById('mini-progress-fill');
    const miniPlayBtn = document.getElementById('mini-play-btn');
    const miniPrevBtn = document.getElementById('mini-prev-btn');
    const miniNextBtn = document.getElementById('mini-next-btn');
    const miniArtImg = document.getElementById('mini-art-img');
    const miniSongTitle = document.getElementById('mini-song-title');
    const miniSongArtist = document.getElementById('mini-song-artist');

    let miniPlaying = false;
    let miniProgress = 0;
    let miniInterval = null;
    let currentSongIndex = 10; // Start with "He Is LeBron James"

    function updateMiniPlayer() {
        const song = songs[currentSongIndex];
        if (miniArtImg) miniArtImg.src = `images/albums/${song.image}`;
        if (miniArtImg) miniArtImg.alt = song.title;
        if (miniSongTitle) miniSongTitle.textContent = song.title;
        if (miniSongArtist) miniSongArtist.textContent = song.artist;
        miniProgress = 0;
        if (miniProgressFill) miniProgressFill.style.width = '0%';
    }

    function startPlaying() {
        miniPlaying = true;
        if (miniPlayBtn) miniPlayBtn.innerHTML = '&#x23F8;';
        if (miniInterval) clearInterval(miniInterval);
        miniInterval = setInterval(() => {
            miniProgress += 0.3;
            if (miniProgress > 100) {
                // Auto-advance to next song
                currentSongIndex = (currentSongIndex + 1) % songs.length;
                updateMiniPlayer();
                miniProgress = 0;
            }
            if (miniProgressFill) miniProgressFill.style.width = miniProgress + '%';
        }, 50);
    }

    function stopPlaying() {
        miniPlaying = false;
        if (miniPlayBtn) miniPlayBtn.innerHTML = '&#x25B6;';
        if (miniInterval) clearInterval(miniInterval);
    }

    if (miniPlayBtn) {
        miniPlayBtn.addEventListener('click', () => {
            if (miniPlaying) {
                stopPlaying();
            } else {
                startPlaying();
            }
        });
    }

    if (miniPrevBtn) {
        miniPrevBtn.addEventListener('click', () => {
            currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
            updateMiniPlayer();
            if (miniPlaying) startPlaying();
        });
    }

    if (miniNextBtn) {
        miniNextBtn.addEventListener('click', () => {
            currentSongIndex = (currentSongIndex + 1) % songs.length;
            updateMiniPlayer();
            if (miniPlaying) startPlaying();
        });
    }

    // -------------------------------------------
    // Crown cursor trail
    // -------------------------------------------
    const canvas = document.getElementById('crown-trail');
    if (canvas) {
        const ctx = canvas.getContext('2d');
        let particles = [];
        let mouseX = 0;
        let mouseY = 0;
        let lastEmit = 0;

        function resizeCanvas() {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
        }

        resizeCanvas();
        window.addEventListener('resize', resizeCanvas);

        document.addEventListener('mousemove', (e) => {
            mouseX = e.clientX;
            mouseY = e.clientY;

            const now = Date.now();
            if (now - lastEmit > 60) {
                particles.push({
                    x: mouseX,
                    y: mouseY,
                    life: 1,
                    size: Math.random() * 8 + 6,
                    vx: (Math.random() - 0.5) * 1.5,
                    vy: (Math.random() - 0.5) * 1.5 - 0.5,
                });
                lastEmit = now;
            }
        });

        function drawCrown(x, y, size, alpha) {
            ctx.save();
            ctx.globalAlpha = alpha;
            ctx.font = `${size}px serif`;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText('\u{1F451}', x, y);
            ctx.restore();
        }

        function animate() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            particles.forEach((p, i) => {
                p.x += p.vx;
                p.y += p.vy;
                p.life -= 0.025;

                if (p.life <= 0) {
                    particles.splice(i, 1);
                    return;
                }

                drawCrown(p.x, p.y, p.size, p.life * 0.5);
            });

            requestAnimationFrame(animate);
        }

        animate();
    }

    // -------------------------------------------
    // Smooth scroll for all anchor links
    // -------------------------------------------
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const href = this.getAttribute('href');
            if (href === '#') return;

            const target = document.querySelector(href);
            if (target) {
                e.preventDefault();
                target.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });

});
