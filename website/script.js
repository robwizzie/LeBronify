/* ============================================
   LEBRONIFY WEBSITE - SCRIPTS
   ============================================ */

document.addEventListener('DOMContentLoaded', () => {

    // -------------------------------------------
    // Song data (matching the app's actual roster)
    // -------------------------------------------
    const songs = [
        { title: "Ain't It Bron", artist: "ilyaugust" },
        { title: "All LeBron Things", artist: "ilyaugust" },
        { title: "Bring Me Back to Bron", artist: "ilyaugust" },
        { title: "Bron Royalty", artist: "ilyaugust" },
        { title: "Bronpeii", artist: "ilyaugust" },
        { title: "Brons Not Brongedies", artist: "ilyaugust" },
        { title: "Brontastic", artist: "ilyaugust" },
        { title: "Catch a LeNade for You", artist: "ilyaugust" },
        { title: "Dear LeBron", artist: "ilyaugust" },
        { title: "Dunk With a Smile", artist: "ilyaugust" },
        { title: "He Is LeBron James", artist: "LeBron Fan" },
        { title: "He Is The King", artist: "LeBron Fan" },
        { title: "I'm Like That's Bron", artist: "ilyaugust" },
        { title: "I Believe in LeBron", artist: "ilyaugust" },
        { title: "I Glazed LeBron (And I Liked It)", artist: "ilyaugust" },
        { title: "In The Bron", artist: "ilyaugust" },
        { title: "La Bron Bron Land", artist: "LeBron Fan" },
        { title: "Le Bronba", artist: "ilyaugust" },
        { title: "LeAfrica", artist: "ilyaugust" },
        { title: "LeAll of Me", artist: "ilyaugust" },
        { title: "LeBron, LeBron, LeBron", artist: "ilyaugust" },
        { title: "LeBron Has Taken a Toll", artist: "ilyaugust" },
        { title: "Marry Me LeBron", artist: "LeBron Fan" },
        { title: "Still Into Bron", artist: "ilyaugust" },
        { title: "Sweet Child O' Bron", artist: "LeBron Fan" },
        { title: "The King of My Heart", artist: "ilyaugust" },
        { title: "LeBronda", artist: "ilyaugust" },
        { title: "On Bron", artist: "ilyaugust" },
        { title: "LeRude Boy", artist: "ilyaugust" },
        { title: "LeSenorita", artist: "ilyaugust" },
        { title: "Where Is The Bron", artist: "ilyaugust" },
        { title: "TACO TUESDAYYYYY", artist: "LeBron James" },
    ];

    // Emoji icons for song cards
    const songEmojis = [
        '&#x1F3C0;', '&#x1F451;', '&#x1F3B5;', '&#x1F525;',
        '&#x1F3B6;', '&#x2B50;', '&#x1F4AA;', '&#x1F3C6;'
    ];

    // -------------------------------------------
    // Populate Song Grid
    // -------------------------------------------
    const songGrid = document.getElementById('song-grid');
    if (songGrid) {
        // Show a subset of songs (random selection to keep it fresh)
        const shuffled = [...songs].sort(() => Math.random() - 0.5);
        const displaySongs = shuffled.slice(0, 16);

        displaySongs.forEach((song) => {
            const item = document.createElement('div');
            item.className = 'song-item';
            const emoji = songEmojis[Math.floor(Math.random() * songEmojis.length)];
            item.innerHTML = `
                <div class="song-item-art">${emoji}</div>
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

        // Close menu when a link is clicked
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
            // Ease out quad
            const eased = 1 - (1 - progress) * (1 - progress);
            el.textContent = Math.round(target * eased);
            if (progress < 1) requestAnimationFrame(update);
        }

        requestAnimationFrame(update);
    }

    // Use IntersectionObserver for stats
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
                // Staggered delay based on sibling index
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

            // Update active states
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
    // Mini Player progress animation
    // -------------------------------------------
    const miniProgressFill = document.getElementById('mini-progress-fill');
    const miniPlayBtn = document.getElementById('mini-play-btn');
    let miniPlaying = false;
    let miniProgress = 0;
    let miniInterval = null;

    if (miniPlayBtn && miniProgressFill) {
        miniPlayBtn.addEventListener('click', () => {
            miniPlaying = !miniPlaying;
            miniPlayBtn.innerHTML = miniPlaying ? '&#x23F8;' : '&#x25B6;';

            if (miniPlaying) {
                miniInterval = setInterval(() => {
                    miniProgress += 0.3;
                    if (miniProgress > 100) miniProgress = 0;
                    miniProgressFill.style.width = miniProgress + '%';
                }, 50);
            } else {
                clearInterval(miniInterval);
            }
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
