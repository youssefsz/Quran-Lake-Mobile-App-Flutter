(function () {
    const themeToggle = document.getElementById('themeToggle');
    const themeIcon = document.getElementById('themeIcon');
    const homeImg = document.getElementById('homeImg');
    const savedImg = document.getElementById('savedImg');
    const settingsImg = document.getElementById('settingsImg');
    const html = document.documentElement;
    const images = [homeImg, savedImg, settingsImg];
    const imageNames = ['home', 'saved', 'settigns'];
    let currentImageIndex = 0;
    let imageInterval = null;

    function getTheme() {
        return localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    }

    function setTheme(theme) {
        html.setAttribute('data-theme', theme);
        html.classList.remove('light', 'dark');
        html.classList.add(theme);
        localStorage.setItem('theme', theme);
        updateImages(theme);
        updateIcon(theme);
    }

    function updateImages(theme) {
        const mode = theme === 'dark' ? 'dark' : 'light';
        // Note: light folder has 'settigns' typo, dark folder has 'settings'
        const settingsName = mode === 'dark' ? 'settings' : 'settigns';
        homeImg.src = `imgs/screenshots/${mode}/home.jpeg`;
        savedImg.src = `imgs/screenshots/${mode}/saved.jpeg`;
        settingsImg.src = `imgs/screenshots/${mode}/${settingsName}.jpeg`;
    }

    function updateIcon(theme) {
        if (theme === 'dark') {
            themeIcon.innerHTML = `
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="currentColor"/>
          `;
        } else {
            themeIcon.innerHTML = `
            <path d="M12 18C15.3137 18 18 15.3137 18 12C18 8.68629 15.3137 6 12 6C8.68629 6 6 8.68629 6 12C6 15.3137 8.68629 18 12 18Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M12 2V4M12 20V22M4.93 4.93L6.34 6.34M17.66 17.66L19.07 19.07M2 12H4M20 12H22M6.34 17.66L4.93 19.07M19.07 4.93L17.66 6.34" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          `;
        }
    }

    function showNextImage() {
        // Remove active class from current image
        images[currentImageIndex].classList.remove('active');

        // Move to next image
        currentImageIndex = (currentImageIndex + 1) % images.length;

        // Add active class to new image
        images[currentImageIndex].classList.add('active');
    }

    function startImageCycle() {
        // Clear existing interval if any
        if (imageInterval) {
            clearInterval(imageInterval);
        }

        // Cycle through images every 3 seconds
        imageInterval = setInterval(showNextImage, 3000);
    }

    // Initialize theme on load
    const currentTheme = getTheme();
    setTheme(currentTheme);

    // Start image cycling
    startImageCycle();

    // Toggle theme on button click
    themeToggle.addEventListener('click', () => {
        const newTheme = html.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
        setTheme(newTheme);
    });

    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        if (!localStorage.getItem('theme')) {
            setTheme(e.matches ? 'dark' : 'light');
        }
    });
    // Modal Logic
    const modal = document.getElementById('apkModal');
    const googlePlayBtn = document.getElementById('googlePlayBtn');
    const closeModal = document.getElementById('closeModal');

    function openModal(e) {
        e.preventDefault();
        modal.style.display = 'flex';
        // Force reflow
        modal.offsetHeight;
        modal.classList.add('show');
        document.body.style.overflow = 'hidden'; // Prevent scrolling
    }

    function closeModalFunc() {
        modal.classList.remove('show');
        setTimeout(() => {
            modal.style.display = 'none';
            document.body.style.overflow = '';
        }, 300);
    }

    googlePlayBtn.addEventListener('click', openModal);
    closeModal.addEventListener('click', closeModalFunc);

    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            closeModalFunc();
        }
    });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && modal.classList.contains('show')) {
            closeModalFunc();
        }
    });

    // APK Download Logic
    const apkDownloadBtn = document.getElementById('apkDownloadBtn');
    const toast = document.getElementById('toast');

    apkDownloadBtn.addEventListener('click', (e) => {
        e.preventDefault();

        if (apkDownloadBtn.classList.contains('loading')) return;

        // Add loading state
        apkDownloadBtn.classList.add('loading');
        const btnText = apkDownloadBtn.querySelector('span');
        const originalText = btnText.textContent;
        const originalContent = apkDownloadBtn.innerHTML;

        // Insert spinner
        apkDownloadBtn.innerHTML = '<div class="spinner"></div><span>Starting...</span>';

        // Simulate processing delay
        setTimeout(() => {
            // Trigger download
            const link = document.createElement('a');
            link.href = 'apk/QuickQuoteTN.apk';
            link.download = 'QuickQuoteTN.apk';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

            // Reset button
            apkDownloadBtn.classList.remove('loading');
            apkDownloadBtn.innerHTML = originalContent;

            // Close modal
            closeModalFunc();

            // Show toast
            showToast();
        }, 1500);
    });

    function showToast() {
        toast.classList.add('show');
        setTimeout(() => {
            toast.classList.remove('show');
        }, 4000);
    }
})();