// Back-to-top button and closing the mobile menu after a click.
// Listeners are on window/document so they keep working after Blazor swaps page content.
window.addEventListener('scroll', function () {
    var b = document.getElementById('backToTop');
    if (b) b.style.display = window.scrollY > 400 ? 'block' : 'none';
});

document.addEventListener('click', function (e) {
    if (e.target.closest('#backToTop')) {
        window.scrollTo({ top: 0, behavior: 'smooth' });
        return;
    }
    var link = e.target.closest('.main-navbar .nav-link, .main-navbar .mobile-actions a');
    var nav = document.getElementById('mainNavbar');
    if (link && nav && nav.classList.contains('show') && window.bootstrap) {
        bootstrap.Collapse.getOrCreateInstance(nav).hide();
    }
});

// Square-crops a chosen image (biased toward the top so faces in portraits stay in frame) and returns a JPEG blob.
window.psabeCropSquare = async (input, size) => {
    const file = input.files && input.files[0];
    if (!file) return null;
    const bmp = await createImageBitmap(file, { imageOrientation: 'from-image' });
    const s = Math.min(bmp.width, bmp.height);
    const sx = (bmp.width - s) / 2;
    const sy = (bmp.height - s) * 0.2;
    const c = document.createElement('canvas');
    c.width = c.height = size;
    c.getContext('2d').drawImage(bmp, sx, sy, s, s, 0, 0, size, size);
    return await new Promise(r => c.toBlob(r, 'image/jpeg', 0.9));
};
