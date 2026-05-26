/**
 * F1 AI Commentary Survey Results - Interactive Features
 * Powered by OpenAI API for intelligent race commentary
 * Smooth scrolling, animations, and dynamic effects
 */

// Smooth scroll for navigation links
document.addEventListener('DOMContentLoaded', function() {
    // Intersection Observer for scroll animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -100px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe all sections
    document.querySelectorAll('.section').forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(30px)';
        section.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
        observer.observe(section);
    });

    // Active nav link highlight
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');

    function highlightNavLink() {
        const scrollPosition = window.scrollY + 100;

        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.offsetHeight;
            const sectionId = section.getAttribute('id');

            if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
                navLinks.forEach(link => {
                    link.style.backgroundColor = '';
                    link.style.color = '';
                    if (link.getAttribute('href') === `#${sectionId}`) {
                        link.style.backgroundColor = 'var(--f1-red)';
                        link.style.color = 'var(--f1-white)';
                    }
                });
            }
        });
    }

    window.addEventListener('scroll', highlightNavLink);
    highlightNavLink(); // Initial call

    // Add hover effects to cards
    const cards = document.querySelectorAll('.content-card, .stat-card, .insight-card, .requirement-card');
    cards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
        });
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });

    // Parallax effect for hero background
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        const hero = document.querySelector('.hero-bg');
        if (hero) {
            hero.style.transform = `translateY(${scrolled * 0.5}px)`;
        }
    });

    // Add click animation to chart images
    document.querySelectorAll('.chart-image').forEach(img => {
        img.addEventListener('click', function() {
            // Create modal-like zoom effect
            const overlay = document.createElement('div');
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(21, 21, 30, 0.95);
                z-index: 10000;
                display: flex;
                align-items: center;
                justify-content: center;
                cursor: pointer;
                padding: 2rem;
            `;

            const imgClone = this.cloneNode();
            imgClone.style.cssText = `
                max-width: 90%;
                max-height: 90%;
                border-radius: 12px;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8);
            `;

            overlay.appendChild(imgClone);
            document.body.appendChild(overlay);

            // Close on click
            overlay.addEventListener('click', () => {
                overlay.style.opacity = '0';
                setTimeout(() => overlay.remove(), 300);
            });

            // Animate in
            overlay.style.opacity = '0';
            setTimeout(() => overlay.style.opacity = '1', 10);
            overlay.style.transition = 'opacity 0.3s ease-out';
        });

        // Add cursor pointer hint
        img.style.cursor = 'pointer';
        img.title = 'Click to enlarge';
    });

    // Add racing stripe animation on scroll
    let lastScroll = 0;
    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;
        const nav = document.querySelector('.nav');
        
        if (currentScroll > lastScroll && currentScroll > 100) {
            // Scrolling down
            nav.style.transform = 'translateY(-100%)';
        } else {
            // Scrolling up
            nav.style.transform = 'translateY(0)';
        }
        
        lastScroll = currentScroll;
    });

    // Add keyboard navigation
    document.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowDown' && e.ctrlKey) {
            e.preventDefault();
            scrollToNextSection();
        }
        if (e.key === 'ArrowUp' && e.ctrlKey) {
            e.preventDefault();
            scrollToPreviousSection();
        }
    });

    function scrollToNextSection() {
        const currentSection = getCurrentSection();
        const allSections = Array.from(sections);
        const currentIndex = allSections.indexOf(currentSection);
        
        if (currentIndex < allSections.length - 1) {
            allSections[currentIndex + 1].scrollIntoView({ behavior: 'smooth' });
        }
    }

    function scrollToPreviousSection() {
        const currentSection = getCurrentSection();
        const allSections = Array.from(sections);
        const currentIndex = allSections.indexOf(currentSection);
        
        if (currentIndex > 0) {
            allSections[currentIndex - 1].scrollIntoView({ behavior: 'smooth' });
        }
    }

    function getCurrentSection() {
        const scrollPosition = window.scrollY + 200;
        let current = sections[0];
        
        sections.forEach(section => {
            if (section.offsetTop <= scrollPosition) {
                current = section;
            }
        });
        
        return current;
    }

    // Add print button functionality (optional)
    console.log('📊 F1 AI Commentary Survey Results loaded');
    console.log('🤖 Powered by OpenAI API');
    console.log('💡 Tip: Use Ctrl+↓ and Ctrl+↑ to navigate between sections');
    console.log('🖱️ Click on any chart to view it in full size');
});

// Performance optimization: Debounce scroll events
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Add loading animation
window.addEventListener('load', () => {
    document.body.style.opacity = '0';
    setTimeout(() => {
        document.body.style.transition = 'opacity 0.5s ease-in';
        document.body.style.opacity = '1';
    }, 100);
});

