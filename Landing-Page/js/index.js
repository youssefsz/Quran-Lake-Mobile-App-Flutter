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

    function updateImages() {
        homeImg.src = `imgs/screenshots/light/home.jpeg`;
        savedImg.src = `imgs/screenshots/light/saved.jpeg`;
        settingsImg.src = `imgs/screenshots/light/settigns.jpeg`;
    }
    updateImages();

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

    // Start image cycling
    startImageCycle();
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
            link.href = 'apk/QuranLake.apk';
            link.download = 'QuranLake.apk';
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