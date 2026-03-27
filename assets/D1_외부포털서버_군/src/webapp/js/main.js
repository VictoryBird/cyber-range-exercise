/**
 * D1 외부 포털 서버 — 발도리아 국방부 메인 스크립트
 * 배너 슬라이더, GNB 메뉴, 글자 크기 변경 등
 */

(function () {
    'use strict';

    /* ========================================
     * 배너 슬라이더
     * ======================================== */
    var slides = document.querySelectorAll('.banner-slide');
    var dots = document.querySelectorAll('.banner-dot');
    var prevBtn = document.querySelector('.banner-prev');
    var nextBtn = document.querySelector('.banner-next');
    var currentSlide = 0;
    var slideTimer = null;

    function showSlide(index) {
        if (slides.length === 0) return;
        slides.forEach(function (s) { s.classList.remove('active'); });
        dots.forEach(function (d) { d.classList.remove('active'); });
        currentSlide = (index + slides.length) % slides.length;
        slides[currentSlide].classList.add('active');
        if (dots[currentSlide]) dots[currentSlide].classList.add('active');
    }

    function nextSlide() {
        showSlide(currentSlide + 1);
    }

    function prevSlide() {
        showSlide(currentSlide - 1);
    }

    function startAutoSlide() {
        stopAutoSlide();
        slideTimer = setInterval(nextSlide, 5000);
    }

    function stopAutoSlide() {
        if (slideTimer) {
            clearInterval(slideTimer);
            slideTimer = null;
        }
    }

    if (nextBtn) {
        nextBtn.addEventListener('click', function () {
            nextSlide();
            startAutoSlide();
        });
    }

    if (prevBtn) {
        prevBtn.addEventListener('click', function () {
            prevSlide();
            startAutoSlide();
        });
    }

    dots.forEach(function (dot, i) {
        dot.addEventListener('click', function () {
            showSlide(i);
            startAutoSlide();
        });
    });

    if (slides.length > 0) {
        startAutoSlide();
    }

    /* ========================================
     * 글자 크기 변경
     * ======================================== */
    var baseFontSize = 16;
    var currentFontSize = baseFontSize;

    window.changeFontSize = function (delta) {
        currentFontSize = Math.max(12, Math.min(22, currentFontSize + delta));
        document.documentElement.style.fontSize = currentFontSize + 'px';
    };

    /* ========================================
     * GNB 키보드 접근성
     * ======================================== */
    var gnbItems = document.querySelectorAll('.gnb-item');
    gnbItems.forEach(function (item) {
        var link = item.querySelector('.gnb-link');
        var sub = item.querySelector('.gnb-sub');
        if (!link || !sub) return;

        link.addEventListener('focus', function () {
            item.classList.add('hover');
        });

        item.addEventListener('focusout', function (e) {
            if (!item.contains(e.relatedTarget)) {
                item.classList.remove('hover');
            }
        });
    });

    /* ========================================
     * 헤더 검색 폼 — 빈 검색어 방지
     * ======================================== */
    var headerForms = document.querySelectorAll('.search-form-header');
    headerForms.forEach(function (form) {
        form.addEventListener('submit', function (e) {
            var input = form.querySelector('.search-input-header');
            if (input && input.value.trim() === '') {
                e.preventDefault();
                input.focus();
            }
        });
    });

    /* ========================================
     * 검색 페이지 폼 — 빈 검색어 방지
     * ======================================== */
    var searchForm = document.getElementById('search-form');
    if (searchForm) {
        searchForm.addEventListener('submit', function (e) {
            var input = document.getElementById('search-keyword');
            if (input && input.value.trim() === '') {
                e.preventDefault();
                input.focus();
            }
        });
    }

})();
