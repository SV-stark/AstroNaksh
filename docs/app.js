/**
 * AstroNaksh - Interactive GitHub Page Engine
 * Minimalist, Modern, Pure Vanilla JavaScript
 */

(function () {
  'use strict';

  // ── Theme Switcher ──────────────────────────────────────────────────────────
  const themeToggleBtn = document.getElementById('theme-toggle');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');

  function initTheme() {
    const savedTheme = localStorage.getItem('astronaksh-theme');
    if (savedTheme) {
      document.documentElement.setAttribute('data-theme', savedTheme);
    } else if (prefersDark.matches) {
      document.documentElement.setAttribute('data-theme', 'dark');
    } else {
      document.documentElement.setAttribute('data-theme', 'dark'); // Default to dark obsidian
    }
  }

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme') || 'dark';
      const next = current === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('astronaksh-theme', next);
    });
  }

  initTheme();

  // ── Mobile Menu Toggle ──────────────────────────────────────────────────────
  const mobileToggle = document.getElementById('mobile-toggle');
  const navMenu = document.getElementById('nav-menu');

  if (mobileToggle && navMenu) {
    mobileToggle.addEventListener('click', () => {
      navMenu.classList.toggle('open');
    });

    // Close menu when clicking outside or on a link
    navMenu.querySelectorAll('.nav-link').forEach((link) => {
      link.addEventListener('click', () => {
        navMenu.classList.remove('open');
      });
    });
  }

  // ── Interactive Demo Tabs ───────────────────────────────────────────────────
  const demoTabs = document.querySelectorAll('.demo-tab-btn');
  const demoPanes = document.querySelectorAll('.demo-pane');

  demoTabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const target = tab.getAttribute('data-tab');
      demoTabs.forEach((t) => t.classList.remove('active'));
      demoPanes.forEach((p) => p.classList.remove('active'));

      tab.classList.add('active');
      const targetPane = document.getElementById(`pane-${target}`);
      if (targetPane) targetPane.classList.add('active');
    });
  });

  // ── Sample Chart Data & Interactive Inspector ───────────────────────────────
  const samplePlanets = [
    { name: 'Ascendant (Lagna)', sign: 'Aries', deg: "14° 22'", nakshatra: 'Bharani', lord: 'Mars', subLord: 'Venus', house: 1, color: 'k-planet-gold' },
    { name: 'Sun (Surya)', sign: 'Leo', deg: "28° 10'", nakshatra: 'Uttara Phalguni', lord: 'Sun', subLord: 'Moon', house: 5, color: 'k-planet-gold' },
    { name: 'Moon (Chandra)', sign: 'Cancer', deg: "08° 45'", nakshatra: 'Pushya', lord: 'Moon', subLord: 'Saturn', house: 4, color: 'k-planet-cyan' },
    { name: 'Mars (Mangal)', sign: 'Capricorn', deg: "18° 30'", nakshatra: 'Shravana', lord: 'Mars', subLord: 'Mercury', house: 10, color: 'k-planet-gold' },
    { name: 'Mercury (Budha)', sign: 'Virgo', deg: "04° 12'", nakshatra: 'Uttara Phalguni', lord: 'Mercury', subLord: 'Rahu', house: 6, color: 'k-planet-cyan' },
    { name: 'Jupiter (Guru)', sign: 'Sagittarius', deg: "12° 50'", nakshatra: 'Mula', lord: 'Jupiter', subLord: 'Ketu', house: 9, color: 'k-planet-gold' },
    { name: 'Venus (Shukra)', sign: 'Pisces', deg: "27° 15'", nakshatra: 'Revati', lord: 'Venus', subLord: 'Jupiter', house: 12, color: 'k-planet-gold' },
    { name: 'Saturn (Shani)', sign: 'Aquarius', deg: "21° 04'", nakshatra: 'Purva Bhadrapada', lord: 'Saturn', subLord: 'Jupiter', house: 11, color: 'k-planet-cyan' },
    { name: 'Rahu (North Node)', sign: 'Pisces', deg: "16° 33'", nakshatra: 'Uttara Bhadrapada', lord: 'Saturn', subLord: 'Venus', house: 12, color: 'k-planet-cyan' },
    { name: 'Ketu (South Node)', sign: 'Virgo', deg: "16° 33'", nakshatra: 'Hasta', lord: 'Moon', subLord: 'Venus', house: 6, color: 'k-planet-cyan' }
  ];

  const houseSignifications = {
    1: 'Self, Vitality, Physical Constitution, General Fortune, Personality',
    2: 'Wealth, Family, Speech, Assets, Food Habits, Second Marriage',
    3: 'Courage, Younger Siblings, Short Journeys, Communication, Hands/Arms',
    4: 'Mother, Home, Vehicles, Fixed Property, Inner Happiness, Formal Education',
    5: 'Intelligence, Romance, Children, Purva Punya, Speculation, Creativity',
    6: 'Health, Debts, Competitions, Litigation, Routine Service, Enemies',
    7: 'Spouse, Business Partnerships, Public Relations, Contracts, Legal Tie-ups',
    8: 'Longevity, Sudden Gains/Losses, Occult, Transformation, Obstacles',
    9: 'Father, Dharma, Higher Wisdom, Guru, Long Travel, Fortune',
    10: 'Career, Profession, Karma, Status, Public Image, Governance',
    11: 'Gains, Aspirations, Elder Siblings, Friendships, Large Networks',
    12: 'Expenses, Foreign Settlements, Moksha, Solitude, Sleep & Dreams'
  };

  const inspectorHouseNum = document.getElementById('inspector-house-num');
  const inspectorHouseSign = document.getElementById('inspector-house-sign');
  const inspectorHouseDesc = document.getElementById('inspector-house-desc');
  const inspectorTableBody = document.getElementById('inspector-table-body');
  const chartStyleSelect = document.getElementById('chart-style-select');

  function renderInspector(selectedHouse = 1) {
    if (!inspectorTableBody) return;

    if (inspectorHouseNum) inspectorHouseNum.textContent = `House ${selectedHouse}`;
    if (inspectorHouseDesc) inspectorHouseDesc.textContent = houseSignifications[selectedHouse] || 'General house energies';

    // Populate planetary table
    let rowsHtml = '';
    samplePlanets.forEach((p) => {
      const isCurrentHouse = p.house === selectedHouse;
      rowsHtml += `
        <tr class="${isCurrentHouse ? 'highlight-row' : ''}">
          <td class="planet-cell"><span class="${p.color}">●</span> ${p.name}</td>
          <td><span class="badge-sign">${p.sign} ${p.deg}</span></td>
          <td>${p.nakshatra}</td>
          <td>${p.subLord}</td>
          <td><strong>H${p.house}</strong></td>
        </tr>
      `;
    });
    inspectorTableBody.innerHTML = rowsHtml;
  }

  // Handle House Click on SVG
  window.selectHouse = function (houseNum) {
    document.querySelectorAll('.k-house-polygon').forEach((el) => {
      el.classList.remove('selected');
    });
    const clickedHouse = document.getElementById(`house-poly-${houseNum}`);
    if (clickedHouse) clickedHouse.classList.add('selected');
    renderInspector(houseNum);
  };

  renderInspector(1);

  // ── KP Horary (1–249) Interactive Solver Demo ───────────────────────────────
  const kpNumberInput = document.getElementById('kp-number-input');
  const kpCategorySelect = document.getElementById('kp-category-select');
  const kpCalculateBtn = document.getElementById('kp-calculate-btn');
  const kpVerdictTitle = document.getElementById('kp-verdict-title');
  const kpVerdictDesc = document.getElementById('kp-verdict-desc');
  const kpVerdictHouses = document.getElementById('kp-verdict-houses');
  const kpMatrixTableBody = document.getElementById('kp-matrix-body');

  const kpCategories = {
    job: { primary: [2, 6, 10, 11], negative: [5, 12], name: 'Career & Employment' },
    marriage: { primary: [2, 7, 11], negative: [1, 6, 10], name: 'Marriage & Relationship' },
    property: { primary: [4, 11, 12], negative: [3, 8], name: 'Property & Vehicle Purchase' },
    health: { primary: [1, 5, 11], negative: [6, 8, 12], name: 'Health & Recovery' },
    wealth: { primary: [2, 6, 11], negative: [5, 8, 12], name: 'Financial Prosperity' },
    travel: { primary: [3, 9, 12], negative: [4, 11], name: 'Foreign Travel & Relocation' }
  };

  const kpSubLords = ['Ketu', 'Venus', 'Sun', 'Moon', 'Mars', 'Rahu', 'Jupiter', 'Saturn', 'Mercury'];

  function calculateKpVerdict() {
    if (!kpNumberInput || !kpCategorySelect) return;

    const horaryNum = parseInt(kpNumberInput.value, 10) || 108;
    const categoryKey = kpCategorySelect.value || 'job';
    const cat = kpCategories[categoryKey];

    // Seeded pseudo-calculation based on horary number
    const subLordIndex = (horaryNum - 1) % 9;
    const starLordIndex = (Math.floor((horaryNum - 1) / 9)) % 9;
    const subLord = kpSubLords[subLordIndex];
    const starLord = kpSubLords[starLordIndex];

    // Determine favorable or unfavorable
    const isFavorable = (horaryNum % 4 !== 0);

    if (kpVerdictTitle) {
      kpVerdictTitle.textContent = isFavorable ? 'Verdict: Strong Positive (Fulfillment Indicated)' : 'Verdict: Challenging / Delay Indicated';
      const banner = document.getElementById('kp-verdict-banner');
      if (banner) {
        banner.className = isFavorable ? 'verdict-banner verdict-favorable' : 'verdict-banner verdict-delay';
      }
    }

    if (kpVerdictDesc) {
      kpVerdictDesc.textContent = isFavorable
        ? `Cuspal Sub-Lord (${subLord}) and Star-Lord (${starLord}) connect directly to primary significators for ${cat.name}. Success expected during matching Dasha/Antardasha.`
        : `Cuspal Sub-Lord (${subLord}) activates detrimental houses (${cat.negative.join(', ')}). Patience and remedial alignment recommended.`;
    }

    if (kpVerdictHouses) {
      kpVerdictHouses.textContent = `Signifying Houses: ${cat.primary.join(', ')}`;
    }

    if (kpMatrixTableBody) {
      const rows = [
        { level: 'A (House Occupant Star)', planet: starLord, houses: cat.primary.slice(0, 2).join(', ') },
        { level: 'B (House Occupant)', planet: subLord, houses: `${cat.primary[0] || 2}, 11` },
        { level: 'C (House Lord Star)', planet: 'Jupiter', houses: `${cat.primary[1] || 6}, 10` },
        { level: 'D (House Lord)', planet: 'Mercury', houses: cat.primary.join(', ') }
      ];

      kpMatrixTableBody.innerHTML = rows.map(r => `
        <tr>
          <td><strong>Level ${r.level}</strong></td>
          <td><span class="badge-sign">${r.planet}</span></td>
          <td>${r.houses}</td>
        </tr>
      `).join('');
    }
  }

  if (kpCalculateBtn) {
    kpCalculateBtn.addEventListener('click', calculateKpVerdict);
  }
  calculateKpVerdict();

  // ── Live Panchang & Muhurta Calculator Simulation ───────────────────────────
  function initLivePanchang() {
    const tithiEl = document.getElementById('panchang-tithi');
    const nakshatraEl = document.getElementById('panchang-nakshatra');
    const yogaEl = document.getElementById('panchang-yoga');
    const muhurtaEl = document.getElementById('panchang-muhurta');

    if (!tithiEl) return;

    const today = new Date();
    const nakshatras = [
      'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra', 'Punarvasu',
      'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni', 'Hasta',
      'Chitra', 'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha', 'Mula', 'Purva Ashadha',
      'Uttara Ashadha', 'Shravana', 'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada',
      'Uttara Bhadrapada', 'Revati'
    ];

    const dayOfYear = Math.floor((today - new Date(today.getFullYear(), 0, 0)) / 1000 / 60 / 60 / 24);
    const nakIndex = (dayOfYear * 13) % 27;
    const tithiNum = (dayOfYear % 30) + 1;
    const paksha = tithiNum <= 15 ? 'Shukla' : 'Krishna';
    const tithiName = `Tithi ${((tithiNum - 1) % 15) + 1} (${paksha} Paksha)`;

    tithiEl.textContent = tithiName;
    if (nakshatraEl) nakshatraEl.textContent = nakshatras[nakIndex];
    if (yogaEl) yogaEl.textContent = 'Siddhi Yoga (Auspicious)';
    if (muhurtaEl) muhurtaEl.textContent = '11:42 AM - 12:34 PM (Local)';
  }

  initLivePanchang();

  // ── Tabbed Installation Code Snippets & Copy ────────────────────────────────
  const installTabs = document.querySelectorAll('.install-tab-btn');
  const installPanes = document.querySelectorAll('.install-pane');

  installTabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const target = tab.getAttribute('data-install');
      installTabs.forEach((t) => t.classList.remove('active'));
      installPanes.forEach((p) => p.classList.remove('active'));

      tab.classList.add('active');
      const targetPane = document.getElementById(`install-${target}`);
      if (targetPane) targetPane.classList.add('active');
    });
  });

  window.copySnippet = function (btn, elementId) {
    const el = document.getElementById(elementId);
    if (!el) return;
    navigator.clipboard.writeText(el.innerText).then(() => {
      const origText = btn.innerText;
      btn.innerText = 'Copied!';
      btn.style.borderColor = 'var(--emerald-500)';
      btn.style.color = 'var(--emerald-500)';
      setTimeout(() => {
        btn.innerText = origText;
        btn.style.borderColor = '';
        btn.style.color = '';
      }, 2000);
    });
  };

  // ── Smooth Active Navigation Highlighting ───────────────────────────────────
  const sections = document.querySelectorAll('section[id]');
  window.addEventListener('scroll', () => {
    const scrollY = window.pageYOffset;
    sections.forEach((current) => {
      const sectionHeight = current.offsetHeight;
      const sectionTop = current.offsetTop - 100;
      const sectionId = current.getAttribute('id');
      const navItem = document.querySelector(`.nav-menu a[href*=${sectionId}]`);
      if (navItem) {
        if (scrollY > sectionTop && scrollY <= sectionTop + sectionHeight) {
          navItem.classList.add('active');
        } else {
          navItem.classList.remove('active');
        }
      }
    });
  });

})();
